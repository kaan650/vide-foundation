local Vide = require("../../Packages/Vide")

local InputField = require("../InputField")
local InputSize = require("../../Enums/InputSize")
local InternalTextInput = require("../InternalTextInput")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local getInputTextSize = require("../../Utility/getInputTextSize")
local useTextInputVariants = require("../TextInput/useTextInputVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InternalTextInputRef = Types.InternalTextInputRef
type Value<T> = Types.Value<T>

export type TextAreaProps = {
	-- Number of lines shown at once
	numLines: Value<number>?,
} & Types.TextInputCommonProps & Types.CommonProps

local defaultProps = {
	size = InputSize.Medium,
	numLines = 3,
	testId = "--foundation-text-area",
}

--- A multi-line text field with a label and hint. The text scrolls once it outgrows `numLines`.
local function TextArea(textAreaProps: TextAreaProps): GuiObject
	local props = withDefaults(textAreaProps, defaultProps)
	local tokens = useTokens()

	local variantProps = Vide.derive(function()
		return useTextInputVariants(tokens(), Value.read(props.size), Value.read(props.variant))
	end)

	return InputField(withCommonProps(props, {
		width = props.width,
		label = props.label,
		size = function()
			return getInputTextSize(Value.read(props.size))
		end,
		hint = props.hint,
		hasError = props.hasError,
		isDisabled = props.isDisabled,
		isRequired = props.isRequired,
		input = function(textBoxRef: (InternalTextInputRef?) -> ())
			return InternalTextInput({
				inputRef = props.inputRef,
				size = props.size,
				variant = props.variant,
				numLines = props.numLines,
				focusBehavior = props.focusBehavior,
				onFocus = props.onFocusGained,
				onFocusLost = props.onFocusLost,
				onChanged = props.onChanged,
				text = props.text,
				hasError = props.hasError,
				isDisabled = props.isDisabled,
				hasClearButton = props.hasClearButton,
				placeholder = props.placeholder,
				horizontalPadding = {
					left = function()
						return variantProps().container.horizontalPadding
					end,
					--TODO: share the scroll bar thickness token with ScrollView (UIBLOX-2919).
					right = function()
						return variantProps().container.horizontalPadding - UDim.new(0, tokens().Size.Size_150)
					end,
				},
				LayoutOrder = 2,
				textBoxRef = textBoxRef,
				testId = `{props.testId}--input`,
			})
		end,
		textBoxRef = props.textBoxRef,
	}) :: any) :: GuiObject
end

return TextArea
