local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local DateTimePickerVariantEnum = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/DateTimePickerVariant")
local DateTimePresetRangesUtilities = require(
	"@game/ReplicatedStorage/Packages/VideFoundation/Components/DateTimePicker/Utilities/DateTimePresetRangesUtilities"
)
local DateTimeUtilities =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Components/DateTimePicker/DateTimeUtilities")

type DateTimePickerProps = VideFoundation.DateTimePickerProps
type DateTimePickerVariant = DateTimePickerVariantEnum.DateTimePickerVariant
type DateRange = DateTimeUtilities.DateRange

local WIDTH_DEFAULT = "default (400px)"
local WIDTH_500 = "500px"
local WIDTH_FILL = "fill (UDim.new(1, 0))"

local VARIANT_ORDER: { DateTimePickerVariant } = {
	DateTimePickerVariantEnum.Single,
	DateTimePickerVariantEnum.SingleWithTime,
	DateTimePickerVariantEnum.Dual,
	DateTimePickerVariantEnum.DualWithPresets,
}

local DEFAULT_START_DATE = DateTime.fromLocalTime(2000, 1, 1)
local DEFAULT_END_DATE = DateTime.fromLocalTime(2000, 1, 3)
local DEFAULT_START_DATE_WITH_TIME = DateTime.fromLocalTime(2000, 1, 1, 14, 30, 0)
local SECONDS_PER_DAY = 24 * 60 * 60

local DEFAULT_HELPER_TEXT = "This is a helper text or hint"

local function noopOnChanged(_startDateTime: DateTime?, _endDateTime: DateTime?) end

local DEFAULT_WIDTH = UDim.new(0, 400)
local WIDTH_UDIM_500 = UDim.new(0, 500)
local WIDTH_UDIM_FILL = UDim.new(1, 0)

local STACKED_EXAMPLES_TAG = "col gap-xxlarge size-full-0 auto-y"
local STORY_PAGE_TAG = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0"
local STACKED_STORY_PAGE_TAG = STORY_PAGE_TAG .. " " .. STACKED_EXAMPLES_TAG

local WIDTH_EXAMPLES: { { label: string, width: UDim? } } = {
	{ label = "Default width", width = nil },
	{ label = "Custom 500px", width = WIDTH_UDIM_500 },
	{ label = "Full width in 800px container", width = WIDTH_UDIM_FILL },
}

local STATE_EXAMPLES: { { label: string, props: { [string]: any } } } = {
	{ label = "Default", props = {} },
	{ label = "With hint", props = { hint = DEFAULT_HELPER_TEXT } },
	{ label = "Required", props = { isRequired = true } },
	{ label = "hasError", props = { hasError = true } },
	{ label = "isDisabled", props = { isDisabled = true } },
}

local CONTROLLED_EXAMPLES: { { label: string, variant: DateTimePickerVariant, note: string } } = {
	{
		label = "Single",
		variant = DateTimePickerVariantEnum.Single,
		note = "Select a date. onChanged(dateTime?)",
	},
	{
		label = "SingleWithTime",
		variant = DateTimePickerVariantEnum.SingleWithTime,
		note = "Select a date and time. onChanged(dateTime?)",
	},
	{
		label = "Dual",
		variant = DateTimePickerVariantEnum.Dual,
		note = "Select a range. onChanged(startDateTime?, endDateTime?)",
	},
	{
		label = "DualWithPresets",
		variant = DateTimePickerVariantEnum.DualWithPresets,
		note = "Two-pane range with presets. Draft commits on Apply. Requires the beta flag.",
	},
}

local RESTRICTED_RANGE_NOTE = "selectableDateRange limits selection to 2 days before through 3 days after today."

local function join(base: any, overrides: any?): any
	local joined = table.clone(base)
	for key, value in overrides or {} do
		joined[key] = value
	end
	return joined
end

local function Section(props: {
	LayoutOrder: number,
	label: string,
	contentTag: string?,
	note: string?,
	heading: boolean?,
	children: any,
})
	local contentTag = props.contentTag or if props.heading then "row gap-large auto-xy wrap" else "auto-xy"
	local outerTag = if props.heading then "col gap-medium size-full-0 auto-y" else "col gap-medium " .. contentTag
	local labelTag = if props.heading
		then "text-label-medium content-default auto-xy"
		else "auto-xy text-caption-small text-align-x-left content-default"

	return VF.View({
		tag = outerTag,
		LayoutOrder = props.LayoutOrder,
		children = {
			if props.note
				then VF.View({
					tag = "row wrap align-y-center gap-xsmall auto-xy",
					LayoutOrder = 1,
					children = {
						VF.Text({
							Text = props.label,
							tag = labelTag,
							LayoutOrder = 1,
						}),
						VF.Text({
							Text = props.note,
							tag = "auto-xy text-caption-small text-wrap text-align-x-left content-muted",
							LayoutOrder = 2,
						}),
					},
				})
				else VF.Text({
					Text = props.label,
					tag = labelTag,
					LayoutOrder = 1,
				}),
			VF.View({
				tag = contentTag,
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local TODAY_DEFAULT_DATES_RANGE = DateTimePresetRangesUtilities.resolvePresetRange("Today")
local THIS_WEEK_DEFAULT_DATES_RANGE = DateTimePresetRangesUtilities.resolvePresetRange("ThisWeek")

local DEFAULT_DATES_TODAY = DateTimeUtilities.formatLocalTime(TODAY_DEFAULT_DATES_RANGE.startDate)
local DEFAULT_DATES_THIS_WEEK =
	`{DateTimeUtilities.formatLocalTime(THIS_WEEK_DEFAULT_DATES_RANGE.startDate)} - {DateTimeUtilities.formatLocalTime(
		THIS_WEEK_DEFAULT_DATES_RANGE.endDate
	)}`

local function resolveDefaultDates(defaultDates: string): (DateTime | { DateTime })?
	if defaultDates == "" then
		return nil
	end

	if defaultDates == DEFAULT_DATES_TODAY then
		return { TODAY_DEFAULT_DATES_RANGE.startDate, TODAY_DEFAULT_DATES_RANGE.endDate }
	end

	if defaultDates == DEFAULT_DATES_THIS_WEEK then
		return { THIS_WEEK_DEFAULT_DATES_RANGE.startDate, THIS_WEEK_DEFAULT_DATES_RANGE.endDate }
	end

	return nil
end

local function offsetDate(dateTime: DateTime, dayOffset: number): DateTime
	return DateTime.fromUnixTimestamp(dateTime.UnixTimestamp + dayOffset * SECONDS_PER_DAY)
end

local function offsetDateFromToday(dayOffset: number): DateTime
	local today = DateTime.now()
	return DateTime.fromUnixTimestamp(today.UnixTimestamp + dayOffset * SECONDS_PER_DAY)
end

local SELECTABLE_DATE_RANGE_PLUS_MINUS_7_DAYS = "+/- 7 days"
local SELECTABLE_DATE_RANGE_DAY_OFFSET = 7

local function getSelectableDateRangeFromToday(dayOffsetStart: number, dayOffsetEnd: number): DateRange
	return {
		startDate = offsetDateFromToday(dayOffsetStart),
		endDate = offsetDateFromToday(dayOffsetEnd),
	}
end

local function resolveSelectableDateRange(selectableDateRange: string, defaultDates: string): DateRange?
	if selectableDateRange == "" then
		return nil
	end

	local dayOffset = SELECTABLE_DATE_RANGE_DAY_OFFSET
	local resolvedDefaultDates = resolveDefaultDates(defaultDates)
	local referenceStart: DateTime
	local referenceEnd: DateTime

	if resolvedDefaultDates == nil then
		local today = DateTime.now()
		referenceStart = today
		referenceEnd = today
	elseif typeof(resolvedDefaultDates) == "DateTime" then
		referenceStart = resolvedDefaultDates
		referenceEnd = resolvedDefaultDates
	else
		referenceStart = resolvedDefaultDates[1]
		referenceEnd = resolvedDefaultDates[2]
	end

	return {
		startDate = offsetDate(referenceStart, -dayOffset),
		endDate = offsetDate(referenceEnd, dayOffset),
	}
end

local REFERENCE_DATE = DateTime.fromLocalTime(2010, 3, 15)

local function resolveReferenceDate(referenceDate: string): DateTime?
	if referenceDate == "" then
		return nil
	end

	return REFERENCE_DATE
end

local function resolveWidth(width: string): UDim?
	if width == WIDTH_DEFAULT then
		return nil
	end

	if width == WIDTH_FILL then
		return WIDTH_UDIM_FILL
	end

	return WIDTH_UDIM_500
end

local function formatDateTimeLabel(dateTime: DateTime?, includeTime: boolean?): string
	if dateTime == nil then
		return "nil"
	end

	return DateTimeUtilities.formatLocalTime(dateTime, includeTime)
end

local VARIANT_STATIC_PROPS: { [DateTimePickerVariant]: { label: string, defaultDates: DateTime | { DateTime } } } = {
	[DateTimePickerVariantEnum.Single] = {
		label = "Date",
		defaultDates = DEFAULT_START_DATE,
	},
	[DateTimePickerVariantEnum.SingleWithTime] = {
		label = "Date and time",
		defaultDates = DEFAULT_START_DATE_WITH_TIME,
	},
	[DateTimePickerVariantEnum.Dual] = {
		label = "Date range",
		defaultDates = { DEFAULT_START_DATE, DEFAULT_END_DATE },
	},
	[DateTimePickerVariantEnum.DualWithPresets] = {
		label = "Date range with filters",
		defaultDates = { DEFAULT_START_DATE, DEFAULT_END_DATE },
	},
}

local function variantProps(variant: DateTimePickerVariant): DateTimePickerProps
	return join({
		label = "Date",
		onChanged = noopOnChanged,
		variant = variant,
		width = DEFAULT_WIDTH,
	}, VARIANT_STATIC_PROPS[variant])
end

local function emptySingleProps(overrides: {
	placeholder: string?,
	width: UDim?,
}?): DateTimePickerProps
	return join({
		label = "Date",
		onChanged = noopOnChanged,
		variant = DateTimePickerVariantEnum.Single,
		width = DEFAULT_WIDTH,
	}, overrides)
end

local WIDTH_EXAMPLE_CONTAINER_WIDTH = 800

local function WidthExampleContainer(children: any)
	return VF.View({
		tag = "col size-full-0 auto-y padding-medium radius-medium bg-surface-100",
		Size = UDim2.fromOffset(WIDTH_EXAMPLE_CONTAINER_WIDTH, 0),
		children = children,
	})
end

--- A DateTimePicker built again after every change, so it always shows its defaults.
local function StaticDateTimePicker(props: DateTimePickerProps)
	local remountKey = Vide.source(0)

	return foundation.rebuildOn(remountKey, function()
		return VF.DateTimePicker(join(props, {
			onChanged = function(_startDateTime: DateTime?, _endDateTime: DateTime?)
				--* React re-renders after the callback returns; rebuilding inside it would destroy the picker that is
				--* still running it.
				task.defer(function()
					remountKey(Vide.untrack(remountKey) + 1)
				end)
			end,
		})) :: any
	end)
end

local function PlaygroundStory(controls: { [string]: any })
	--* React remounts the picker with a key built from these controls.
	local function key(): string
		return `{controls.variant()}-{controls.defaultDates()}-{controls.selectableDateRange()}-{controls.width()}-{controls.hint()}-{controls.referenceDate()}-{controls.hasError()}-{controls.isRequired()}`
	end

	return VF.View({
		tag = function()
			return if controls.width() == WIDTH_FILL then "col size-full-0 auto-y" else "row auto-xy"
		end,
		Size = UDim2.new(1, 0, 0, 100),
		children = foundation.rebuildOn(key, function()
			local variant: DateTimePickerVariant = controls.variant()
			local hint: string = controls.hint()
			return VF.DateTimePicker({
				defaultDates = resolveDefaultDates(controls.defaultDates()),
				referenceDate = resolveReferenceDate(controls.referenceDate()),
				hasError = controls.hasError(),
				hint = if hint == "" then nil else hint,
				isDisabled = controls.isDisabled,
				isRequired = if controls.isRequired() then true else nil,
				label = controls.label,
				placeholder = function(): string?
					local placeholder = controls.placeholder()
					return if placeholder == "" then nil else placeholder
				end,
				onChanged = function(startDateTime: DateTime?, endDateTime: DateTime?)
					if
						variant == DateTimePickerVariantEnum.Dual
						or variant == DateTimePickerVariantEnum.DualWithPresets
					then
						print(`Dual onChanged: {startDateTime} - {endDateTime}`)
					else
						print(`onChanged: {startDateTime}`)
					end
				end,
				selectableDateRange = resolveSelectableDateRange(
					controls.selectableDateRange(),
					controls.defaultDates()
				),
				variant = variant,
				width = resolveWidth(controls.width()),
			}) :: any
		end),
	})
end

local function isPickerInputEmpty(host: Instance?): boolean
	local textBox = (host and host:FindFirstChildWhichIsA("TextBox", true)) :: TextBox?
	return textBox == nil or textBox.Text:match("^%s*$") ~= nil
end

local function isDateOutsideSelectableRange(date: DateTime, selectableDateRange: DateRange?): boolean
	return selectableDateRange ~= nil and not DateTimeUtilities.isDateWithinRange(date, selectableDateRange)
end

type ControlledExampleProps = {
	variant: DateTimePickerVariant,
	selectableDateRange: DateRange?,
}

local function DualRangeControlledExample(props: ControlledExampleProps)
	local host: GuiObject? = nil
	local startDate = Vide.source(nil :: DateTime?)
	local getStartDate: () -> DateTime? = startDate :: any
	local endDate = Vide.source(nil :: DateTime?)
	local getEndDate: () -> DateTime? = endDate :: any
	local hasError = Vide.source(false)

	host = VF.View({
		tag = "col gap-small auto-xy",
		children = {
			VF.Text({
				Text = function()
					return `Selected: {formatDateTimeLabel(getStartDate())} - {formatDateTimeLabel(getEndDate())}`
				end,
				tag = "auto-xy text-caption-small text-align-x-left content-muted",
				LayoutOrder = 1,
			}),
			VF.DateTimePicker({
				LayoutOrder = 2,
				hasError = hasError,
				hint = function(): string?
					return if hasError() then "Invalid date range" else nil
				end,
				label = "Date",
				onChanged = function(startDateTime: DateTime?, endDateTime: DateTime?)
					startDate(startDateTime)
					endDate(endDateTime)
					local inputEmpty = isPickerInputEmpty(host)
					local incomplete = startDateTime == nil or endDateTime == nil
					local outOfRange = if startDateTime and endDateTime
						then isDateOutsideSelectableRange(startDateTime, props.selectableDateRange)
							or isDateOutsideSelectableRange(endDateTime, props.selectableDateRange)
						else false
					hasError(not inputEmpty and (incomplete or outOfRange))
				end,
				selectableDateRange = props.selectableDateRange,
				variant = props.variant,
				width = DEFAULT_WIDTH,
			}),
		},
	})
	return host
end

local function SingleControlledExample(props: ControlledExampleProps)
	local host: GuiObject? = nil
	local selectedDate = Vide.source(nil :: DateTime?)
	local getSelectedDate: () -> DateTime? = selectedDate :: any
	local hasError = Vide.source(false)
	local includeTime = props.variant == DateTimePickerVariantEnum.SingleWithTime

	host = VF.View({
		tag = "col gap-small auto-xy",
		children = {
			VF.Text({
				Text = function()
					return `Selected: {formatDateTimeLabel(getSelectedDate(), if includeTime then true else nil)}`
				end,
				tag = "auto-xy text-caption-small text-align-x-left content-muted",
				LayoutOrder = 1,
			}),
			VF.DateTimePicker({
				LayoutOrder = 2,
				hasError = hasError,
				hint = function(): string?
					return if hasError() then "Invalid date" else nil
				end,
				label = "Date",
				onChanged = function(dateTime: DateTime?, _endDateTime: DateTime?)
					selectedDate(dateTime)
					local inputEmpty = isPickerInputEmpty(host)
					local unparseable = dateTime == nil
					local outOfRange = if dateTime
						then isDateOutsideSelectableRange(dateTime, props.selectableDateRange)
						else false
					hasError(not inputEmpty and (unparseable or outOfRange))
				end,
				selectableDateRange = props.selectableDateRange,
				variant = props.variant,
				width = DEFAULT_WIDTH,
			}),
		},
	})
	return host
end

local function ControlledExample(props: ControlledExampleProps)
	local isDualRange = props.variant == DateTimePickerVariantEnum.Dual
		or props.variant == DateTimePickerVariantEnum.DualWithPresets

	return if isDualRange then DualRangeControlledExample(props) else SingleControlledExample(props)
end

local function getRestrictedRangeForPresets(): DateRange
	local today = DateTime.now()
	local weekday = tonumber(today:FormatLocalTime("d", "en-us")) or 0

	return {
		startDate = offsetDateFromToday(-weekday - 7),
		endDate = offsetDateFromToday(-weekday + 6),
	}
end

local function ControlledStory()
	local restrictedSelectableDateRange = getSelectableDateRangeFromToday(-2, 3)
	local restrictedRangeLayoutOrder = #CONTROLLED_EXAMPLES + 1

	local sections = {}
	for index, example in CONTROLLED_EXAMPLES do
		sections[index] = Section({
			LayoutOrder = index,
			label = example.label,
			contentTag = "auto-xy",
			note = example.note,
			heading = true,
			children = ControlledExample({
				variant = example.variant,
				selectableDateRange = nil,
			}),
		})
	end

	table.insert(
		sections,
		Section({
			LayoutOrder = restrictedRangeLayoutOrder,
			label = "Restricted range",
			contentTag = "auto-xy",
			note = RESTRICTED_RANGE_NOTE,
			heading = true,
			children = ControlledExample({
				variant = DateTimePickerVariantEnum.Single,
				selectableDateRange = restrictedSelectableDateRange,
			}),
		})
	)
	table.insert(
		sections,
		Section({
			LayoutOrder = restrictedRangeLayoutOrder + 1,
			label = "Restricted range — Dual",
			contentTag = "auto-xy",
			note = RESTRICTED_RANGE_NOTE,
			heading = true,
			children = ControlledExample({
				variant = DateTimePickerVariantEnum.Dual,
				selectableDateRange = restrictedSelectableDateRange,
			}),
		})
	)
	table.insert(
		sections,
		Section({
			LayoutOrder = restrictedRangeLayoutOrder + 2,
			label = "Restricted range — DualWithPresets",
			contentTag = "auto-xy",
			note = "selectableDateRange spans last week through this week so Today, This week, and Last week presets remain available.",
			heading = true,
			children = ControlledExample({
				variant = DateTimePickerVariantEnum.DualWithPresets,
				selectableDateRange = getRestrictedRangeForPresets(),
			}),
		})
	)

	return VF.View({
		tag = STORY_PAGE_TAG,
		children = sections,
	})
end

local function VariantsStory()
	local sections = {}
	for index, variant in VARIANT_ORDER do
		sections[index] = Section({
			label = variant,
			LayoutOrder = index,
			children = StaticDateTimePicker(variantProps(variant)),
		})
	end
	return VF.View({
		tag = STACKED_STORY_PAGE_TAG,
		children = sections,
	})
end

local function WidthStory()
	local sections = {}
	for index, example in WIDTH_EXAMPLES do
		sections[index] = Section({
			label = example.label,
			LayoutOrder = index,
			children = WidthExampleContainer(StaticDateTimePicker(emptySingleProps({
				width = example.width,
			}))),
		})
	end
	return VF.View({
		tag = STACKED_STORY_PAGE_TAG,
		children = sections,
	})
end

local function StatesStory()
	local baseProps = emptySingleProps()

	local sections = {}
	for index, example in STATE_EXAMPLES do
		sections[index] = Section({
			label = example.label,
			LayoutOrder = index,
			children = StaticDateTimePicker(join(baseProps, example.props)),
		})
	end
	return VF.View({
		tag = STACKED_STORY_PAGE_TAG,
		children = sections,
	})
end

local function offsetMonthsFromToday(monthOffset: number): DateTime
	local localTime = DateTimeUtilities.toLocalTime(DateTime.now())
	local month = localTime.Month
	local year = localTime.Year
	for _ = 1, monthOffset do
		month, year = DateTimeUtilities.getNextMonthInfo(month, year)
	end
	local day = math.min(localTime.Day, DateTimeUtilities.getDaysInMonth(month, year))
	return DateTime.fromLocalTime(year, month, day)
end

local function getMonthSelectableDateRange(dateTime: DateTime): DateRange
	local localTime = DateTimeUtilities.toLocalTime(dateTime)
	return {
		startDate = DateTime.fromLocalTime(localTime.Year, localTime.Month, 1),
		endDate = DateTime.fromLocalTime(
			localTime.Year,
			localTime.Month,
			DateTimeUtilities.getDaysInMonth(localTime.Month, localTime.Year)
		),
	}
end

local function ContentStory()
	local referenceDate = offsetMonthsFromToday(5)

	local contentExamples: { { label: string, note: string?, props: DateTimePickerProps } } = {
		{
			label = "Preset date",
			props = variantProps(DateTimePickerVariantEnum.Single),
		},
		{
			label = "Custom placeholder",
			note = "Override the empty-state hint with `placeholder`.",
			props = emptySingleProps({
				placeholder = "MM/DD/YYYY",
			}),
		},
		{
			label = "Reference date",
			note = "selectableDateRange is the month ~5 months from today. Opening there depends on referenceDate — without it the calendar would open on today.",
			props = {
				label = "Select available dates",
				onChanged = noopOnChanged,
				referenceDate = referenceDate,
				selectableDateRange = getMonthSelectableDateRange(referenceDate),
				variant = DateTimePickerVariantEnum.DualWithPresets,
				width = DEFAULT_WIDTH,
			},
		},
	}

	local sections = {}
	for index, example in contentExamples do
		sections[index] = Section({
			LayoutOrder = index,
			label = example.label,
			contentTag = STACKED_EXAMPLES_TAG,
			note = example.note,
			heading = true,
			children = StaticDateTimePicker(example.props),
		})
	end
	return VF.View({
		tag = STORY_PAGE_TAG,
		children = sections,
	})
end

local function scrolled(build: () -> any): (controls: { [string]: any }) -> any
	return function()
		return foundation.scroll(build())
	end
end

return foundation.sections({
	summary = "DateTimePicker is a text input with a calendar popover for selecting a date, date-time, or date range. Single selects one date. SingleWithTime adds a time dropdown. Dual selects a start and end date. DualWithPresets adds a two-pane calendar with range presets and a draft that commits on Apply.",
	controls = {
		defaultDates = UILabs.Choose({ "", DEFAULT_DATES_TODAY, DEFAULT_DATES_THIS_WEEK }),
		hasError = false,
		hint = DEFAULT_HELPER_TEXT,
		isDisabled = false,
		isRequired = false,
		label = "Date",
		selectableDateRange = UILabs.Choose({ "", SELECTABLE_DATE_RANGE_PLUS_MINUS_7_DAYS }),
		variant = UILabs.Choose(VARIANT_ORDER),
		width = UILabs.Choose({ WIDTH_DEFAULT, WIDTH_500, WIDTH_FILL }),
		placeholder = "",
		referenceDate = UILabs.Choose({ "", "2010-03-15" }),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Variants", story = scrolled(VariantsStory) },
		{ name = "Width", story = scrolled(WidthStory) },
		{ name = "States", story = scrolled(StatesStory) },
		{
			name = "Controlled component",
			summary = "Parent state via onChanged. Non-empty invalid or out-of-range input sets hasError; clearing restores a valid empty state.",
			story = scrolled(ControlledStory),
		},
		{ name = "Content", story = scrolled(ContentStory) },
	},
})
