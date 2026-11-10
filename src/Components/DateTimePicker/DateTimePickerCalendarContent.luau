local DateRangePresets = require("./Presets/DateRangePresets")
local DateTimePickerVariantEnum = require("../../Enums/DateTimePickerVariant")
local DateTimeUtilities = require("./DateTimeUtilities")
local Divider = require("../Divider")
local SingleMonthCalendar = require("./Calendar/SingleMonthCalendar")
local TwoMonthCalendar = require("./Calendar/TwoMonthCalendar")
local View = require("../View")
local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")

type DateRange = DateTimeUtilities.DateRange
type DateTimePickerVariant = DateTimePickerVariantEnum.DateTimePickerVariant

export type DateTimePickerCalendarContentProps = {
	-- Day click in DualWithPresets (TwoMonthCalendar).
	onDayActivated: (dateTime: DateTime) -> (),
	-- Preset range chip selected.
	onPresetSelected: (range: DateRange) -> (),
	-- Selection changed in SingleMonthCalendar.
	onSelectedDatesChanged: (dates: { DateTime }) -> (),
	-- Month shown when nothing is selected.
	referenceDate: () -> DateTime?,
	-- Inclusive bounds for selectable days.
	selectableDateRange: () -> DateRange?,
	-- Current draft selection.
	selectedDates: () -> { DateTime }?,
	testId: string?,
	-- DualWithPresets shows two months and presets; the others one month, with the time list for SingleWithTime.
	variant: () -> DateTimePickerVariant,
	-- Month the calendar panes should show.
	viewAnchorDate: () -> DateTime?,
}

--- The picker's calendar for its variant. Returns a source of the current root.
local function DateTimePickerCalendarContent(props: DateTimePickerCalendarContentProps): () -> GuiObject
	local calendarTestId = `{props.testId}--calendar`

	local function presetsContent(): GuiObject
		local calendar = TwoMonthCalendar({
			LayoutOrder = 1,
			onDayActivated = props.onDayActivated,
			referenceDate = props.referenceDate,
			selectableDateRange = props.selectableDateRange,
			selectedDates = props.selectedDates,
			testId = calendarTestId,
			viewAnchorDate = props.viewAnchorDate,
		})
		calendar.Name = "Calendar"

		local presetsDivider = Divider({
			LayoutOrder = 2,
		})
		presetsDivider.Name = "PresetsDivider"

		local presets = DateRangePresets({
			LayoutOrder = 1,
			onPresetSelected = props.onPresetSelected,
			referenceDate = props.referenceDate,
			selectableDateRange = props.selectableDateRange,
			selectedDates = props.selectedDates,
			testId = `{calendarTestId}--presets`,
		})
		presets.Name = "Presets"

		local presetsBar = View({
			LayoutOrder = 3,
			tag = "row size-full-0 auto-y padding-x-large padding-y-medium",
			children = presets,
		})
		presetsBar.Name = "PresetsBar"

		return View({
			tag = "col size-full-0 auto-y",
			children = { calendar, presetsDivider, presetsBar },
		})
	end

	local function isPresets(): boolean
		return props.variant() == DateTimePickerVariantEnum.DualWithPresets
	end

	return rebuildOn<<boolean>>(isPresets, function(presets: boolean): GuiObject
		if presets then
			return presetsContent()
		end
		--* A source yielding a source is a valid Vide child.
		return named(
			"Content",
			SingleMonthCalendar({
				isDateRange = function()
					return props.variant() == DateTimePickerVariantEnum.Dual
				end,
				LayoutOrder = 1,
				onSelectedDateChanged = props.onSelectedDatesChanged,
				referenceDate = props.referenceDate,
				selectableDateRange = props.selectableDateRange,
				selectedDates = props.selectedDates,
				showTimeList = function()
					return props.variant() == DateTimePickerVariantEnum.SingleWithTime
				end,
				testId = calendarTestId,
				viewAnchorDate = props.viewAnchorDate,
			})
		) :: any
	end) :: () -> GuiObject
end

return DateTimePickerCalendarContent
