local BuilderIcons = require("../../../Packages/BuilderIcons")
local ButtonVariant = require("../../../Enums/ButtonVariant")
local DateTimeCalendarViewUtilities = require("../Utilities/DateTimeCalendarViewUtilities")
local DateTimeUtilities = require("../DateTimeUtilities")
local IconButton = require("../../IconButton")
local InputSize = require("../../../Enums/InputSize")
local Text = require("../../Text")
local View = require("../../View")
local named = require("../../../Utility/named")

type ViewDate = DateTimeCalendarViewUtilities.ViewDate

local IconName = BuilderIcons.Icon

export type TwoMonthCalendarHeaderProps = {
	currViewDate: () -> ViewDate,
	onNextMonth: () -> (),
	onPreviousMonth: () -> (),
	secondMonth: () -> number,
	secondYear: () -> number,
	testId: string?,
}

--- Previous and next buttons around the names of the two months shown.
local function TwoMonthCalendarHeader(props: TwoMonthCalendarHeaderProps): GuiObject
	local firstMonthLabel = Text({
		LayoutOrder = 2,
		tag = "grow auto-y text-title-small text-align-x-center",
		testId = `{props.testId}--first-month-label`,
		Text = function()
			local viewDate = props.currViewDate()
			return `{DateTimeUtilities.monthMap[viewDate.month]} {viewDate.year}`
		end,
	})
	firstMonthLabel.Name = "FirstMonthLabel"

	local secondMonthLabel = Text({
		LayoutOrder = 3,
		tag = "grow auto-y text-title-small text-align-x-center",
		testId = `{props.testId}--second-month-label`,
		Text = function()
			return `{DateTimeUtilities.monthMap[props.secondMonth()]} {props.secondYear()}`
		end,
	})
	secondMonthLabel.Name = "SecondMonthLabel"

	return View({
		LayoutOrder = 1,
		tag = "row align-y-center gap-small size-full-0 auto-y padding-x-large padding-y-medium",
		children = {
			named(
				"PreviousMonthButton",
				IconButton({
					icon = IconName.ChevronSmallLeft,
					isCircular = false,
					LayoutOrder = 1,
					onActivated = props.onPreviousMonth,
					size = InputSize.Small,
					testId = `{props.testId}--previous-month-button`,
					variant = ButtonVariant.Utility,
				})
			),
			firstMonthLabel,
			secondMonthLabel,
			named(
				"NextMonthButton",
				IconButton({
					icon = IconName.ChevronSmallRight,
					isCircular = false,
					LayoutOrder = 4,
					onActivated = props.onNextMonth,
					size = InputSize.Small,
					testId = `{props.testId}--next-month-button`,
					variant = ButtonVariant.Utility,
				})
			),
		},
	})
end

return TwoMonthCalendarHeader
