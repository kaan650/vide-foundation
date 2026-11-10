local Vide = require("@game/ReplicatedStorage/Packages/Vide")

local Types = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Types")

type ItemId = Types.ItemId

--- A `scrollingFrameRef` for BaseMenu and Dropdown that centers the selected item in the menu, and again whenever
--- the selection changes. Call it while the story is being created.
local function scrollToSelected(items: () -> { any }, selectedId: () -> ItemId): (scrollingFrame: ScrollingFrame) -> ()
	local frame: ScrollingFrame? = nil
	local connections: { RBXScriptConnection } = {}

	local function disconnect()
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
	end

	--* Before the menu is measured and clamped to maxHeight the window is as tall as the canvas, so centering would
	--* land on the top. Rows are found from canvasHeight / count rather than AbsolutePosition.
	local function scroll(scrollingFrame: ScrollingFrame): boolean
		local list = Vide.untrack(items)
		local selected = Vide.untrack(selectedId)
		local count = #list
		local canvasHeight = scrollingFrame.AbsoluteCanvasSize.Y
		local windowHeight = scrollingFrame.AbsoluteWindowSize.Y
		if count == 0 or windowHeight <= 0 or canvasHeight <= windowHeight then
			return false
		end
		local rowHeight = canvasHeight / count
		local targetIndex = 0
		for index, item in list do
			if item.id == selected then
				targetIndex = index - 1
				break
			end
		end
		local centeredY = targetIndex * rowHeight - windowHeight / 2 + rowHeight / 2
		scrollingFrame.CanvasPosition = Vector2.new(0, math.clamp(centeredY, 0, canvasHeight - windowHeight))
		return true
	end

	local function attach(scrollingFrame: ScrollingFrame)
		disconnect()
		frame = scrollingFrame
		if scroll(scrollingFrame) then
			return
		end
		local function onSizeChanged()
			if scroll(scrollingFrame) then
				disconnect()
			end
		end
		table.insert(connections, scrollingFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(onSizeChanged))
		table.insert(connections, scrollingFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(onSizeChanged))
	end

	Vide.effect(function()
		selectedId()
		items()
		Vide.untrack(function()
			if frame and frame.Parent then
				attach(frame)
			end
		end)
	end)
	Vide.cleanup(disconnect)

	return attach
end

return scrollToSelected
