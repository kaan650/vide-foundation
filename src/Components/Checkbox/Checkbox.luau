local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")

local Constants = require("../../Constants")
local InputPlacement = require("../../Enums/InputPlacement")
local InputSize = require("../../Enums/InputSize")
local InternalInput = require("../InternalInput")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local named = require("../../Utility/named")
local useCheckboxVariants = require("./useCheckboxVariants")
local useInputGroupDefaults = require("../InternalInputGroup/useInputGroupDefaults")
local useTokens = require("../../Providers/Style/useTokens")
local useUncontrolledState = require("../InternalInput/useUncontrolledState")
local withCommonProps = require("../../Utility/withCommonProps")

type InputPlacement = InputPlacement.InputPlacement
type InputSize = InputSize.InputSize
type Value<T> = Types.Value<T>

export type CheckboxProps = {
	-- Whether the checkbox is currently checked. If it is left `nil`,
	-- the checkbox will be considered uncontrolled.
	isChecked: Value<boolean?>?,
	-- Whether the checkbox is disabled. When `true`, the `onActivated` callback
	-- will not be invoked, even if the user interacts with the checkbox.
	isDisabled: Value<boolean?>?,
	-- A visual property that, if true, will show an indeterminate state
	-- over the checkbox
	isIndeterminate: Value<boolean?>?,
	-- A function that will be called whenever the checkbox is activated.
	-- Returns the new value of the checkbox when uncontrolled.
	onActivated: (boolean) -> (),
	-- A label for the checkbox. To omit, set it to an empty string.
	label: Value<string>,
	-- A secondary description displayed below the label.
	hint: Value<string?>?,
	size: Value<InputSize>?,
	placement: Value<InputPlacement>?,
} & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	size = InputSize.Medium,
	placement = InputPlacement.Start,
	Selectable = true,
	testId = "--foundation-checkbox",
}

--- A box that toggles between checked and unchecked, with an optional indeterminate look. Inside an input group it
--- takes the group's size and placement. A source `isDisabled` or `label` returns a source of the instance.
local function Checkbox(checkboxProps: CheckboxProps): GuiObject | () -> GuiObject
	local props = useInputGroupDefaults(checkboxProps, defaultProps)
	local tokens = useTokens()
	local variantProps = Vide.derive(function()
		return useCheckboxVariants(tokens(), Value.read(props.size))
	end)

	local isChecked, onActivated = useUncontrolledState(props.isChecked, props.onActivated)
	local function isIndeterminate(): boolean
		return Value.read(props.isIndeterminate) == true
	end

	local checkmark = Vide.show(function()
		return isChecked() or isIndeterminate()
	end, function()
		return named(
			"Checkmark",
			Text({
				Text = function()
					return if isIndeterminate() then BuilderIcons.Icon.Minus else BuilderIcons.Icon.Check
				end,
				fontStyle = {
					Font = (BuilderIcons.Font :: any)[BuilderIcons.IconVariant.Filled],
				},
				TextScaled = true,
				tag = function()
					return variantProps().checkmark.tag
				end,
				testId = `{props.testId}--checkmark`,
			})
		)
	end)

	return InternalInput(withCommonProps(props, {
		isChecked = isChecked,
		isIndeterminate = isIndeterminate,
		isDisabled = props.isDisabled,
		onActivated = onActivated,
		label = {
			text = props.label,
			position = function()
				return Constants.INPUT_PLACEMENT_TO_LABEL_ALIGNMENT[Value.read(props.placement)]
			end,
			hint = props.hint,
		},
		customVariantProps = function()
			return variantProps().input
		end,
		size = props.size,
		Selectable = props.Selectable,
		NextSelectionUp = props.NextSelectionUp,
		NextSelectionDown = props.NextSelectionDown,
		NextSelectionLeft = props.NextSelectionLeft,
		NextSelectionRight = props.NextSelectionRight,
		children = checkmark,
	}) :: any)
end

return Checkbox
