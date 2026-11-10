local Vide = require("../../Packages/Vide")

local Constants = require("../../Constants")
local HintText = require("../HintText")
local InputLabel = require("../InputLabel")
local InputLabelSize = require("../../Enums/InputLabelSize")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local named = require("../../Utility/named")
local useScaledValue = require("../../Utility/useScaledValue")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InputLabelSize = InputLabelSize.InputLabelSize
type InternalTextInputRef = Types.InternalTextInputRef
type TextInputRef = Types.TextInputRef
type Value<T> = Types.Value<T>

export type InputFieldProps = {
	size: Value<InputLabelSize>?,
	hasError: Value<boolean?>?,
	-- Whether the input is disabled
	isDisabled: Value<boolean?>?,
	-- Whether the input is required, true for "*", false for " (optional)", nil for nothing
	isRequired: Value<boolean?>?,
	-- Input label text. To omit, set to an empty string
	label: Value<string>,
	-- Builds the input. It hands its TextBox handle to `textBoxRef` so the label can focus it.
	input: (textBoxRef: (InternalTextInputRef?) -> ()) -> any,
	-- Receives a handle to the inner TextBox once the input provides one.
	textBoxRef: ((TextInputRef) -> ())?,
	-- Hint text below the input, is red on error
	hint: Value<string?>?,
	width: Value<UDim?>?,
} & Types.CommonProps

local defaultProps = {
	size = InputLabelSize.Small,
	testId = "--foundation-input-field",
}

--- A form input with its label above and hint text below.
local function InputField(inputFieldProps: InputFieldProps): GuiObject
	local props = withDefaults(inputFieldProps, defaultProps)
	local testId = props.testId
	local defaultWidth = useScaledValue(Constants.DEFAULT_INPUT_FIELD_WIDTH_PIXELS)
	local textBox: InternalTextInputRef? = nil

	local function focusTextBox()
		if textBox and not textBox.getIsFocused() then
			textBox.focus()
		end
	end

	local function setTextBox(handle: InternalTextInputRef?)
		textBox = handle
		local onRef = props.textBoxRef
		if handle and onRef then
			onRef({
				focus = handle.focus,
				releaseFocus = handle.releaseFocus,
				getIsFocused = handle.getIsFocused,
				getCursorPosition = handle.getCursorPosition,
				getSelectionStart = handle.getSelectionStart,
				setCursorPosition = handle.setCursorPosition,
				setSelectionStart = handle.setSelectionStart,
			})
		end
	end

	return View(withCommonProps(props, {
		Size = function()
			local width: UDim? = Value.read(props.width)
			return if width then UDim2.new(width, UDim.new(0, 0)) else UDim2.fromOffset(defaultWidth(), 0)
		end,
		tag = "col gap-small auto-y",
		children = {
			Vide.show(function()
				return #Value.read(props.label) > 0
			end, function()
				return named(
					"Label",
					InputLabel({
						Text = props.label,
						size = props.size,
						isRequired = props.isRequired,
						isDisabled = props.isDisabled,
						onActivated = focusTextBox,
						LayoutOrder = 1,
						testId = `{testId}--label`,
					})
				)
			end),
			named(
				"InputWrapper",
				View({
					tag = "size-full-0 auto-y",
					LayoutOrder = 2,
					testId = `{testId}--input-wrapper`,
					children = named("Input", props.input(setTextBox)),
				})
			),
			Vide.show(function()
				return Value.read(props.hint) ~= nil
			end, function()
				return named(
					"Hint",
					HintText({
						text = function()
							return Value.read(props.hint) or ""
						end,
						hasError = props.hasError,
						isDisabled = props.isDisabled,
						LayoutOrder = 3,
						testId = `{testId}--hint`,
					})
				)
			end),
		},
	}) :: any)
end

return InputField
