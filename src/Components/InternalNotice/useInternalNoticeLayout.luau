local Vide = require("../../Packages/Vide")

local Breakpoint = require("../../Enums/Breakpoint")
local BreakpointConfig = require("../../Utility/Responsive/BreakpointConfig")
local Types = require("../Types")
local useAbsoluteSize = require("../../Utility/useAbsoluteSize")

type SizeConstraint = Types.SizeConstraint

-- Stack at XSmall based on notice width, not screen width.
local STACK_BREAKPOINT_WIDTH = BreakpointConfig.widths[Breakpoint.XSmall]
-- Reserve at least this much of the notice for the message. Stack the CTA if it would take more.
local MESSAGE_MIN_WIDTH_RATIO = 0.7

export type InternalNoticeLayout = {
	isStacked: () -> boolean,
	onNoticeAbsoluteSizeChanged: (GuiObject) -> (),
	onStackedColumnAbsoluteSizeChanged: (GuiObject) -> (),
	-- Give it to the inline link only: measuring the stacked link would shrink the saved width.
	measureInlineLink: (GuiObject) -> (),
	stackedLinkConstraint: () -> SizeConstraint?,
}

--- Whether the notice stacks its link under the message: when the notice is XSmall wide, or when the inline link
--- would take more than 30% of it. Call it while the component is being created.
local function useInternalNoticeLayout(onNoticeAbsoluteSizeChanged: ((GuiObject) -> ())?): InternalNoticeLayout
	local noticeSize, handleNoticeAbsoluteSizeChanged = useAbsoluteSize(onNoticeAbsoluteSizeChanged)
	local inlineLinkWidth = Vide.source(0)
	local stackedColumnWidth = Vide.source(0)

	local isStacked = Vide.derive(function(): boolean
		local width = noticeSize().X
		local isAtStackBreakpoint = width > 0 and width <= STACK_BREAKPOINT_WIDTH
		local maxInlineLinkWidth = width * (1 - MESSAGE_MIN_WIDTH_RATIO)
		local isInlineLinkTooWide = maxInlineLinkWidth > 0 and inlineLinkWidth() > maxInlineLinkWidth
		return isAtStackBreakpoint or isInlineLinkTooWide
	end)

	-- Limit the stacked link to the column width so wrapped text does not overflow.
	local stackedLinkConstraint = Vide.derive(function(): SizeConstraint?
		local width = stackedColumnWidth()
		return if isStacked() and width > 0 then { MaxSize = Vector2.new(width, math.huge) } else nil
	end)

	return {
		isStacked = isStacked,
		onNoticeAbsoluteSizeChanged = handleNoticeAbsoluteSizeChanged,
		onStackedColumnAbsoluteSizeChanged = function(instance: GuiObject)
			stackedColumnWidth(instance.AbsoluteSize.X)
		end,
		measureInlineLink = function(instance: GuiObject)
			if not Vide.untrack(isStacked) then
				inlineLinkWidth(instance.AbsoluteSize.X)
			end
		end,
		stackedLinkConstraint = stackedLinkConstraint,
	}
end

return useInternalNoticeLayout
