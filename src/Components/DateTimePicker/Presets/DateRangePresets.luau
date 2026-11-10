local Vide = require("../../../Packages/Vide")

local ChipGroup = require("../../ChipGroup")
local ChipSize = require("../../../Enums/ChipSize")
local DateTimeEqualityUtilities = require("../Utilities/DateTimeEqualityUtilities")
local DateTimePickerDateRangePresetEnum = require("../../../Enums/DateTimePickerDateRangePreset")
local DateTimePresetRangesUtilities = require("../Utilities/DateTimePresetRangesUtilities")
local DateTimeUtilities = require("../DateTimeUtilities")
local Translator = require("../../../Utility/Localization/Translator")

type DateRange = DateTimeUtilities.DateRange
type DateRangePreset = DateTimePickerDateRangePresetEnum.DateTimePickerDateRangePreset
type ChipGroupItem = ChipGroup.ChipGroupItem

export type DateRangePresetsProps = {
	-- The selected range; the preset covering the same days is checked.
	selectedDates: () -> { DateTime }?,
	-- Called with the preset's range when its chip is activated.
	onPresetSelected: (range: DateRange) -> (),
	-- Day the relative presets are counted from; defaults to now.
	referenceDate: () -> DateTime?,
	-- Presets reaching outside this range are left out.
	selectableDateRange: () -> DateRange?,
	LayoutOrder: number?,
	testId: string?,
}

local ORDERED_PRESETS: { DateRangePreset } = {
	DateTimePickerDateRangePresetEnum.Today,
	DateTimePickerDateRangePresetEnum.ThisWeek,
	DateTimePickerDateRangePresetEnum.LastWeek,
	DateTimePickerDateRangePresetEnum.ThisMonth,
	DateTimePickerDateRangePresetEnum.ThisYear,
	DateTimePickerDateRangePresetEnum.LastYear,
}

local function buildPresetChip(
	preset: DateRangePreset,
	selectedDates: { DateTime }?,
	referenceDate: DateTime?,
	selectableDateRange: DateRange?,
	onPresetSelected: (range: DateRange) -> ()
): ChipGroupItem?
	local range = DateTimePresetRangesUtilities.resolvePresetRange(preset, referenceDate)
	if
		selectableDateRange and not DateTimeEqualityUtilities.isRangeWithinSelectableRange(range, selectableDateRange)
	then
		return nil
	end

	return {
		text = Translator:FormatByKey(`CommonUI.Controls.Label.{preset}`),
		isChecked = DateTimeEqualityUtilities.areDatesSameDayAsRange(selectedDates, range),
		onActivated = function()
			onPresetSelected(range)
		end,
	}
end

--- Chips for the common ranges (today, this week...), the one matching the selection checked.
local function DateRangePresets(props: DateRangePresetsProps): GuiObject
	local chips = Vide.derive(function(): { ChipGroupItem }
		local items = {}
		for _, preset in ORDERED_PRESETS do
			local chip = buildPresetChip(
				preset,
				props.selectedDates(),
				props.referenceDate(),
				props.selectableDateRange(),
				props.onPresetSelected
			)
			if chip then
				table.insert(items, chip)
			end
		end
		return items
	end)

	return ChipGroup({
		chips = chips,
		LayoutOrder = props.LayoutOrder,
		size = ChipSize.Small,
		testId = props.testId,
	})
end

return DateRangePresets
