local DateTimePickerVariantEnum = require("../../Enums/DateTimePickerVariant")
local DateTimeUtilities = require("./DateTimeUtilities")
local Types = require("../Types")

type Value<T> = Types.Value<T>

export type DateTimePickerProps = {
	-- Dates selected when the picker is created. Range variants use the first as the start and the second, if
	-- present, as the end.
	defaultDates: (DateTime | { DateTime })?,
	-- Whether the input has an error
	hasError: Value<boolean>?,
	-- Hint text for the text input
	hint: Value<string?>?,
	-- Whether the input is disabled
	isDisabled: Value<boolean>?,
	-- Whether the input is required
	isRequired: Value<boolean?>?,
	-- Label used for the text input
	label: Value<string>,
	-- Called when the input text changes. Dates are nil when not valid; endDateTime is the end of a range.
	onChanged: (startDateTime: DateTime?, endDateTime: DateTime?) -> (),
	-- Placeholder shown when the input is empty.
	placeholder: Value<string?>?,
	-- Month the calendar opens to when nothing is selected, and the day relative presets count from.
	referenceDate: Value<DateTime?>?,
	-- Selectable date range (inclusive), compared by whole days.
	selectableDateRange: Value<DateTimeUtilities.DateRange?>?,
	-- Gamepad focus configuration between the picker surface and neighboring UI elements.
	selection: Types.Selection?,
	-- Gamepad focus grouping and directional navigation between the picker and its neighbors.
	selectionGroup: (Value<boolean> | Types.SelectionGroup)?,
	-- Variant of the date time picker
	variant: Value<DateTimePickerVariantEnum.DateTimePickerVariant?>?,
	-- Width of the text input component
	width: Value<UDim>?,
} & Types.CommonProps

return {}
