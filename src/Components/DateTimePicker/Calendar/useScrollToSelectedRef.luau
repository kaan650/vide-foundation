local Vide = require("../../../Packages/Vide")

local Dropdown = require("../../Dropdown")

--- A `scrollingFrameRef` that centers the selected item when a Dropdown menu opens. The menu is measured and clamped
--- to its max height only after it mounts; before that its window equals the whole canvas and the centering math
--- lands on the top, so it waits for the sizes to settle.
local function useScrollToSelectedRef(
	items: () -> { Dropdown.DropdownItem },
	selectedId: () -> number
): (frame: ScrollingFrame) -> ()
	local connections: { RBXScriptConnection }? = nil
	local function disconnect()
		if connections then
			for _, connection in connections do
				connection:Disconnect()
			end
			connections = nil
		end
	end
	Vide.cleanup(disconnect)

	return function(scrollingFrame: ScrollingFrame)
		disconnect()
		local currentItems = Vide.untrack(items)
		local currentId = Vide.untrack(selectedId)

		local function scrollToSelected(): boolean
			local count = #currentItems
			local canvasHeight = scrollingFrame.AbsoluteCanvasSize.Y
			local windowHeight = scrollingFrame.AbsoluteWindowSize.Y
			if count == 0 or windowHeight <= 0 or canvasHeight <= windowHeight then
				return false
			end
			local rowHeight = canvasHeight / count
			local targetIndex = 0
			for index, item in currentItems do
				if item.id == currentId then
					targetIndex = index - 1
					break
				end
			end
			local centeredY = targetIndex * rowHeight - windowHeight / 2 + rowHeight / 2
			scrollingFrame.CanvasPosition = Vector2.new(0, math.clamp(centeredY, 0, canvasHeight - windowHeight))
			return true
		end

		if not scrollToSelected() then
			local function onSizeChanged()
				if scrollToSelected() then
					disconnect()
				end
			end
			connections = {
				scrollingFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(onSizeChanged),
				scrollingFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(onSizeChanged),
			}
		end
	end
end

return useScrollToSelectedRef
