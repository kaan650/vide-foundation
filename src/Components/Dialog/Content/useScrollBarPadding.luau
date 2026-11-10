local Vide = require("../../../Packages/Vide")

local isScrollingFrameOverflowingY = require("../../../Utility/isScrollingFrameOverflowingY")
local useTokens = require("../../../Providers/Style/useTokens")

--- Whether the content overflows, the right padding that keeps it clear of the scroll bar, and the update to call
--- when the canvas or window size changes.
local function useScrollBarPadding(): (() -> boolean, () -> number, (instance: ScrollingFrame) -> ())
	local hasOverflowY = Vide.source(false)
	local tokens = useTokens()
	local scrollBarPadding = Vide.source(0)

	local function updateScrollBarPadding(instance: ScrollingFrame)
		local isOverflowingY = isScrollingFrameOverflowingY(instance, 1)
		hasOverflowY(isOverflowingY)
		scrollBarPadding(if isOverflowingY then Vide.untrack(tokens).Size.Size_150 else 0)
	end

	return function()
		return hasOverflowY()
	end, function()
		return scrollBarPadding()
	end, updateScrollBarPadding
end

return useScrollBarPadding
