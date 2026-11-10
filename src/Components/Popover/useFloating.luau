local Vide = require("../../Packages/Vide")

local PopoverAlign = require("../../Enums/PopoverAlign")
local PopoverSide = require("../../Enums/PopoverSide")
local Types = require("../Types")
local positioning = require("./positioning")

type PopoverSide = PopoverSide.PopoverSide
type PopoverAlign = PopoverAlign.PopoverAlign
type PopoverAnchor = Types.PopoverAnchor

export type SideConfig = {
	position: PopoverSide,
	offset: number,
} | PopoverSide

export type AlignConfig = {
	position: PopoverAlign,
	offset: number,
} | PopoverAlign

export type Floating = {
	position: () -> Vector2,
	isVisible: () -> boolean,
	contentSize: () -> UDim2,
	arrowPosition: () -> Vector2,
	screenSize: () -> Vector2,
	anchorPoint: () -> Vector2,
}

local function connectSignals(instance: PopoverAnchor | GuiBase2d, signalNames: { string }, callback: () -> ())
	for _, signalName in signalNames do
		local connection = (instance :: any):GetPropertyChangedSignal(signalName):Connect(callback)
		Vide.cleanup(function()
			connection:Disconnect()
		end)
	end
end

local function getRect(object: PopoverAnchor | GuiBase2d): Rect
	local position: Vector2 = (object :: any).AbsolutePosition
	return Rect.new(position, position + (object :: any).AbsoluteSize)
end

--- Places popover content next to its anchor. The results are sources, recomputed (once per frame at most) while the
--- anchor, the content, the overlay or a clipping ancestor of the anchor moves or resizes. Call it while the component
--- is being created.
local function useFloating(
	isOpen: () -> boolean,
	anchor: () -> PopoverAnchor?,
	content: () -> GuiObject?,
	overlay: () -> GuiBase2d?,
	sideConfig: () -> SideConfig,
	alignConfig: () -> AlignConfig,
	arrowSize: () -> number
): Floating
	local position = Vide.source(Vector2.new())
	local isVisible = Vide.source(true)
	local contentSize = Vide.source(UDim2.new())
	local screenSize = Vide.source(Vector2.new())
	local arrowPosition = Vide.source(Vector2.new())
	local anchorPoint = Vide.source(Vector2.new(0, 0))
	local clippingAncestors: { GuiObject } = {}

	local function recalculatePosition()
		local currentAnchor = anchor()
		local currentContent = content()
		local currentOverlay = overlay()
		if not isOpen() or not currentAnchor or not currentContent or not currentOverlay then
			isVisible(false)
			return
		end

		local measuredContentSize = currentContent.AbsoluteSize
		local measuredScreenSize = currentOverlay.AbsoluteSize
		local anchorRect = getRect(currentAnchor)
		local screenRect = getRect(currentOverlay)

		if not positioning.isOnScreen(anchorRect, screenRect) then
			isVisible(false)
			return
		end
		local clipRect: Rect? = nil
		for _, clippingAncestor in clippingAncestors do
			local rect = getRect(clippingAncestor)
			if clipRect == nil then
				clipRect = rect
			else
				clipRect = Rect.new(
					Vector2.new(math.max(clipRect.Min.X, rect.Min.X), math.max(clipRect.Min.Y, rect.Min.Y)),
					Vector2.new(math.min(clipRect.Max.X, rect.Max.X), math.min(clipRect.Max.Y, rect.Max.Y))
				)
			end
		end
		if clipRect and not positioning.isOnScreen(anchorRect, clipRect) then
			isVisible(false)
			return
		end

		local currentSide = sideConfig()
		local currentAlign = alignConfig()
		local side: PopoverSide = if type(currentSide) == "table" then currentSide.position else currentSide
		local sideOffset = if type(currentSide) == "table" then currentSide.offset else 0
		local align: PopoverAlign = if type(currentAlign) == "table" then currentAlign.position else currentAlign
		local alignOffset = if type(currentAlign) == "table" then currentAlign.offset else 0
		local arrowOffset = arrowSize()

		local popoverSize =
			positioning.calculatePopoverBounds(side, sideOffset, alignOffset, arrowOffset, measuredContentSize)
		side = positioning.calculateSide(side, anchorRect, screenRect, popoverSize)

		local calculatedPosition, calculatedArrowPosition, calculatedAnchorPoint = positioning.calculatePositions(
			side,
			sideOffset,
			align,
			alignOffset,
			anchorRect,
			screenRect,
			arrowOffset,
			measuredContentSize
		)

		Vide.batch(function()
			contentSize(UDim2.fromOffset(measuredContentSize.X, measuredContentSize.Y))
			screenSize(measuredScreenSize)
			arrowPosition(calculatedArrowPosition + calculatedPosition)
			position(calculatedPosition)
			anchorPoint(calculatedAnchorPoint)
			isVisible(true)
		end)

		--! Reading AbsolutePosition forces a layout pass, so the AutomaticSize content does not wobble (quantum GUI).
		local _ = currentContent.AbsolutePosition
	end

	local isPending = false
	local isAlive = true
	Vide.cleanup(function()
		isAlive = false
	end)
	local function scheduleRecalculate()
		if isPending then
			return
		end
		isPending = true
		task.defer(function()
			isPending = false
			if isAlive then
				recalculatePosition()
			end
		end)
	end

	Vide.effect(function()
		local current = anchor()
		if current ~= nil then
			connectSignals(current, { "AbsolutePosition", "AbsoluteSize" }, scheduleRecalculate)
		end
	end)
	Vide.effect(function()
		local current = content()
		if current ~= nil then
			connectSignals(current, { "AbsoluteSize" }, scheduleRecalculate)
		end
	end)
	Vide.effect(function()
		local current = overlay()
		if current ~= nil then
			connectSignals(current, { "AbsoluteSize" }, scheduleRecalculate)
		end
	end)

	Vide.effect(function()
		local current = anchor()
		if not isOpen() or typeof(current) ~= "Instance" or not (current :: Instance):IsA("GuiObject") then
			return
		end
		local guiAnchor = current :: GuiObject
		local connections: { RBXScriptConnection } = {}

		local function rebuild()
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)

			--! An ancestor toggling ClipsDescendants later is not noticed, as in Foundation.
			local ancestors: { GuiObject } = {}
			local node = guiAnchor.Parent
			while node and node:IsA("GuiObject") do
				if node.ClipsDescendants then
					table.insert(ancestors, node)
					table.insert(
						connections,
						node:GetPropertyChangedSignal("AbsolutePosition"):Connect(scheduleRecalculate)
					)
					table.insert(
						connections,
						node:GetPropertyChangedSignal("AbsoluteSize"):Connect(scheduleRecalculate)
					)
				end
				node = node.Parent
			end

			clippingAncestors = ancestors
			if #ancestors > 0 then
				scheduleRecalculate()
			end
		end

		rebuild()
		local ancestryConnection = guiAnchor.AncestryChanged:Connect(rebuild)
		Vide.cleanup(function()
			ancestryConnection:Disconnect()
			for _, connection in connections do
				connection:Disconnect()
			end
			clippingAncestors = {}
		end)
	end)

	Vide.effect(function()
		isOpen()
		anchor()
		content()
		overlay()
		sideConfig()
		alignConfig()
		arrowSize()
		Vide.untrack(recalculatePosition)
	end)

	return {
		position = position,
		isVisible = isVisible,
		contentSize = contentSize,
		arrowPosition = arrowPosition,
		screenSize = screenSize,
		anchorPoint = anchorPoint,
	}
end

return useFloating
