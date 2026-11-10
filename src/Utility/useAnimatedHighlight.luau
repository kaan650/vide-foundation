local Vide = require("../Packages/Vide")

local Motion = require("./Motion")
local Types = require("../Components/Types")
local useTokens = require("../Providers/Style/useTokens")

type ItemId = Types.ItemId

export type AnimatedHighlight = {
	-- Height of the active item.
	activeItemHeight: () -> number,
	-- X offset of the active item from the container.
	highlightPosition: () -> number,
	-- Width of the active item.
	highlightWidth: () -> number,
}

local UNSET = newproxy()

--- A highlight that follows the active item of a row (tabs, segments, steps): it eases to a newly activated item and
--- snaps when the same item moves or resizes. `dependencies` reads the sources whose change re-measures the item.
--- Call it while the component is being created.
local function useAnimatedHighlight(
	activeItemId: () -> ItemId?,
	container: () -> GuiObject?,
	items: () -> { [ItemId]: GuiObject },
	dependencies: (() -> ())?
): AnimatedHighlight
	local tokens = useTokens()
	local function easeConfig(): Motion.EaseOptions
		local current = Vide.untrack(tokens)
		return {
			easingStyle = current.Ease.StandardOut,
			duration = current.Time.Time_200,
		}
	end

	local previousItemId: ItemId? = Vide.untrack(activeItemId)
	local highlightPosition, setHighlightPosition = Motion.useAnimatedBinding(0)
	local highlightWidth, setHighlightWidth = Motion.useAnimatedBinding(0)
	local activeItemHeight = Vide.source(0)

	local function updateHighlight(item: GuiObject, containerInstance: GuiObject, sameItem: boolean)
		local positionOffset = item.AbsolutePosition.X - containerInstance.AbsolutePosition.X
		local itemSize = item.AbsoluteSize.X
		if sameItem then
			setHighlightWidth(Motion.instant(itemSize))
			setHighlightPosition(Motion.instant(positionOffset))
		else
			local config = easeConfig()
			setHighlightPosition(Motion.ease(positionOffset, config))
			setHighlightWidth(Motion.ease(itemSize, config))
		end
		activeItemHeight(item.AbsoluteSize.Y)
	end

	--* Foundation decides once per activation whether layout changes snap: only the item active since mount does.
	local connectedId: any = UNSET
	local connectedSameItem = true
	Vide.effect(function()
		local id = activeItemId()
		local item = if id ~= nil then items()[id] else nil
		local containerInstance = container()
		Vide.untrack(function()
			if id ~= connectedId then
				connectedId = id
				connectedSameItem = id == previousItemId
			end
			if not item or not containerInstance then
				return
			end
			local activeItem = item :: GuiObject
			local activeContainer = containerInstance :: GuiObject
			local function animateHighlight()
				updateHighlight(activeItem, activeContainer, connectedSameItem)
			end
			Vide.cleanup(activeItem:GetPropertyChangedSignal("AbsoluteSize"):Connect(animateHighlight))
			Vide.cleanup(activeItem:GetPropertyChangedSignal("AbsolutePosition"):Connect(animateHighlight))
			Vide.cleanup(activeContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(animateHighlight))
		end)
	end)

	Vide.effect(function()
		local id = activeItemId()
		if dependencies then
			dependencies()
		end
		Vide.untrack(function()
			if id == nil then
				return
			end
			local item = items()[id]
			local containerInstance = container()
			if item and containerInstance then
				updateHighlight(item, containerInstance, id == previousItemId)
			end
			--! Deferred so strict mode's second run of this effect still sees the previous item and eases too.
			task.defer(function()
				previousItemId = id
			end)
		end)
	end)

	return {
		activeItemHeight = activeItemHeight,
		highlightPosition = highlightPosition,
		highlightWidth = highlightWidth,
	}
end

return useAnimatedHighlight
