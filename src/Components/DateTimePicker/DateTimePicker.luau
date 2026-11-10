local BuilderIcons = require("../../Packages/BuilderIcons")
local DateTimePickerCalendarContent = require("./DateTimePickerCalendarContent")
local DateTimePickerPanel = require("./DateTimePickerPanel")
local DateTimePickerPropsModule = require("./DateTimePickerProps")
local DateTimePickerVariantEnum = require("../../Enums/DateTimePickerVariant")
local InputSize = require("../../Enums/InputSize")
local Popover = require("../Popover")
local PopoverAlign = require("../../Enums/PopoverAlign")
local PopoverSide = require("../../Enums/PopoverSide")
local TextInput = require("../TextInput")
local Translator = require("../../Utility/Localization/Translator")
local Value = require("../../Utility/Value")
local named = require("../../Utility/named")
local useDateTimePickerState = require("./useDateTimePickerState")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type DateTimePickerVariant = DateTimePickerVariantEnum.DateTimePickerVariant
type SectionedLayout = DateTimePickerPanel.SectionedLayout
export type DateTimePickerProps = DateTimePickerPropsModule.DateTimePickerProps

local IconName = BuilderIcons.Icon

local defaultProps = {
	testId = "--foundation-date-time-picker",
	variant = DateTimePickerVariantEnum.Single,
}

--- A text input for a date, a date and time, or a range, with a calendar popover to pick it. Returns the input and
--- the popover content, as React renders them as a fragment.
--- Foundation's FoundationDateTimePickerBetaUpdate is on: this is its DateTimePickerBeta.
local function DateTimePicker(dateTimePickerProps: DateTimePickerProps): { any }
	local props = withDefaults(dateTimePickerProps, defaultProps)
	local tokens = useTokens()
	local testId: string = props.testId

	local function variant(): DateTimePickerVariant
		return Value.read(props.variant) or DateTimePickerVariantEnum.Single
	end
	local function isPresets(): boolean
		return variant() == DateTimePickerVariantEnum.DualWithPresets
	end
	local function isTime(): boolean
		return variant() == DateTimePickerVariantEnum.SingleWithTime
	end
	local function isSectioned(): boolean
		return isPresets() or isTime()
	end
	local function referenceDate(): DateTime?
		return Value.read(props.referenceDate)
	end
	local function selectableDateRange()
		return Value.read(props.selectableDateRange)
	end

	local state = useDateTimePickerState(props)

	local function panel(): GuiObject
		return named(
			"Children",
			DateTimePickerPanel({
				isApplyButtonDisabled = state.isApplyButtonDisabled,
				isResetButtonDisabled = state.isResetButtonDisabled,
				isSectioned = isSectioned,
				onApply = state.onApply,
				onCancel = state.onCancel,
				onReset = state.onReset,
				sectionedLayout = function(): SectionedLayout?
					return if isPresets() then "dual" elseif isTime() then "singleWithTime" else nil
				end,
				showReset = isSectioned,
				testId = testId,
				children = DateTimePickerCalendarContent({
					onDayActivated = state.onDayActivated,
					onPresetSelected = state.onPresetSelected,
					onSelectedDatesChanged = state.onSelectedDatesChanged,
					referenceDate = referenceDate,
					selectableDateRange = selectableDateRange,
					selectedDates = state.selectedDates,
					testId = testId,
					variant = variant,
					viewAnchorDate = state.viewAnchorDate,
				}),
			})
		)
	end

	return Popover.Root({
		isOpen = state.isOpen,
		testId = testId,
		children = function()
			local input = TextInput(withCommonProps(
				props,
				{
					hasError = props.hasError,
					hint = props.hint,
					iconTrailing = {
						name = IconName.Calendar,
						onActivated = state.showDateTimePicker,
					},
					isDisabled = props.isDisabled,
					isRequired = props.isRequired,
					label = props.label,
					onChanged = state.updateInputText,
					onFocusGained = state.onFocusGained,
					onFocusLost = state.onFocusLost,
					placeholder = function()
						return Value.read(props.placeholder)
							or Translator:FormatByKey("CommonUI.Controls.Label.SelectDate")
					end,
					size = InputSize.Medium,
					text = state.inputText,
					width = props.width,
				} :: TextInput.TextInputProps
			))

			return {
				named("DateInput", input),
				Popover.Anchor({ anchorRef = input }),
				Popover.Content({
					align = PopoverAlign.Start,
					hasArrow = false,
					onPressedOutside = state.closeDateTimePicker,
					selection = props.selection,
					selectionGroup = props.selectionGroup,
					side = function()
						return {
							offset = tokens().Stroke.Standard + tokens().Padding.Small,
							position = PopoverSide.Bottom,
						}
					end,
					name = "PopoverContent",
					children = panel,
				}),
			}
		end,
	})
end

return DateTimePicker
