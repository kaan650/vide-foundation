local Vide = require("../../../Packages/Vide")

local Constants = require("../../../Constants")
local InputPlacement = require("../../../Enums/InputPlacement")
local InputSize = require("../../../Enums/InputSize")
local InternalInput = require("../../InternalInput")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local named = require("../../../Utility/named")
local useInputGroupDefaults = require("../../InternalInputGroup/useInputGroupDefaults")
local useRadioGroup = require("../useRadioGroup")
local useRadioGroupItemVariants = require("./useRadioGroupItemVariants")
local useTokens = require("../../../Providers/Style/useTokens")
local withCommonProps = require("../../../Utility/withCommonProps")

type InputPlacement = InputPlacement.InputPlacement
type InputSize = InputSize.InputSize
type Value<T> = Types.Value<T>

export type RadioGroupItemProps = {
	-- A unique value for the radio item. It also names the item's test id, so it is a plain string.
	value: string,
	-- Whether the radio item is disabled. When `true`, the `setValue` method
	-- will not be invoked, even if the user interacts with the radio item.
	isDisabled: Value<boolean?>?,
	-- A label for the radio item, or an instance shown in its place. To omit, set it to an empty string.
	-- When nil, defaults to `value`.
	label: (Value<string?> | GuiObject)?,
	-- A secondary description displayed below the label.
	hint: Value<string?>?,
	-- Size of the radio item
	size: Value<InputSize>?,
	placement: Value<InputPlacement>?,
} & Types.CommonProps

local defaultProps = {
	size = InputSize.Medium,
	isDisabled = false,
	placement = InputPlacement.Start,
}

--- One option of a RadioGroup. Create it inside the group's `children`. A source `isDisabled` or `label` returns a
--- source of the instance.
local function RadioGroupItem(radioGroupItemProps: RadioGroupItemProps): GuiObject | () -> GuiObject
	local props = useInputGroupDefaults(radioGroupItemProps, defaultProps)
	local radioGroup = useRadioGroup()
	local tokens = useTokens()
	local value = props.value

	local function isChecked(): boolean
		return radioGroup.value() == value
	end

	local label = props.label
	local text: (Value<string?> | GuiObject)? = if label == nil
		then value
		elseif type(label) == "function" then function()
			return (label :: () -> string?)() or value
		end
		else label

	local variantProps = Vide.derive(function()
		return useRadioGroupItemVariants(tokens(), Value.read(props.size))
	end)

	props.testId = `{radioGroup.testId}--item-{value}`

	local center = Vide.show(isChecked, function()
		return named(
			"Center",
			View({
				tag = function()
					return variantProps().checkmark.tag
				end,
				backgroundStyle = function()
					return variantProps().checkmark.style
				end,
			})
		)
	end)

	return InternalInput(withCommonProps(props, {
		isChecked = isChecked,
		isDisabled = props.isDisabled,
		onActivated = function()
			radioGroup.onValueChanged(value)
		end,
		label = {
			text = text,
			position = function()
				return Constants.INPUT_PLACEMENT_TO_LABEL_ALIGNMENT[Value.read(props.placement)]
			end,
			hint = props.hint,
		},
		customVariantProps = function()
			return variantProps().input
		end,
		size = props.size,
		Selectable = radioGroup.Selectable,
		children = center,
	}) :: any)
end

return RadioGroupItem
