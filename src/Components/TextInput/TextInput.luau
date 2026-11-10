local Vide = require("../../Packages/Vide")

local Icon = require("../Icon")
local IconButton = require("../IconButton")
local InputField = require("../InputField")
local InputSize = require("../../Enums/InputSize")
local InternalTextInput = require("../InternalTextInput")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local getInputTextSize = require("../../Utility/getInputTextSize")
local named = require("../../Utility/named")
local useTextInputVariants = require("./useTextInputVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InternalTextInputRef = Types.InternalTextInputRef
type Value<T> = Types.Value<T>

export type TextInputTrailingIcon = string | {
	name: string,
	onActivated: () -> (),
}

export type TextInputProps = {
	-- Image before the input
	leadingIcon: Value<string?>?,
	-- Image after the input, can be pressed
	iconTrailing: Value<TextInputTrailingIcon?>?,
	-- Type of text input. Only available for use in descendants of CoreGui.
	textInputType: Enum.TextInputType?,
	-- Ran when return is pressed within the TextInput
	onReturnPressed: (() -> ())?,
} & Types.TextInputCommonProps & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	size = InputSize.Large,
	testId = "--foundation-text-input",
}

--- `build(key)` while `key` is not nil, built again when it changes.
local function keyed(key: () -> string?, build: (key: string) -> GuiObject | () -> GuiObject): () -> any
	local builders = setmetatable({}, {
		__index = function(_, current: string)
			return function()
				return build(current)
			end
		end,
	})
	return Vide.switch(key)(builders :: any)
end

--- A single-line text field with a label, hint and optional icons.
local function TextInput(textInputProps: TextInputProps): GuiObject
	local props = withDefaults(textInputProps, defaultProps)
	local tokens = useTokens()
	local testId: string = props.testId

	local variantProps = Vide.derive(function()
		return useTextInputVariants(tokens(), Value.read(props.size), Value.read(props.variant))
	end)
	local function horizontalPadding(): UDim
		return variantProps().container.horizontalPadding
	end
	local function iconStyle(): Types.ColorStyleValue
		return variantProps().icon.style :: any
	end
	local function iconSize()
		return variantProps().icon.size
	end

	local function iconRow(child: any): GuiObject
		return View({
			tag = "row align-y-center size-0-full auto-x",
			children = named("Children", child),
		})
	end

	local leadingElement = keyed(function()
		return Value.read(props.leadingIcon)
	end, function(name: string)
		return iconRow(Icon({
			name = name,
			style = iconStyle,
			size = iconSize,
		}))
	end)

	local function trailingIcon(): TextInputTrailingIcon?
		return Value.read(props.iconTrailing)
	end
	local trailingElement = keyed(function(): string?
		local icon = trailingIcon()
		if icon == nil then
			return nil
		elseif type(icon) == "table" then
			return if icon.onActivated then `button:{icon.name}` else `icon:{icon.name}`
		end
		return `icon:{icon}`
	end, function(key: string)
		local name = string.sub(key, string.find(key, ":", 1, true) :: number + 1)
		if string.sub(key, 1, 7) == "button:" then
			return iconRow(IconButton({
				onActivated = function()
					local icon = Vide.untrack(trailingIcon)
					if type(icon) == "table" and icon.onActivated then
						icon.onActivated()
					end
				end,
				isDisabled = props.isDisabled,
				size = iconSize,
				icon = name,
				testId = `{testId}--trailing-icon-button`,
			}))
		end
		return iconRow(Icon({
			name = name,
			style = iconStyle,
			size = iconSize,
		}))
	end)

	return InputField(withCommonProps(props, {
		width = props.width,
		label = props.label,
		size = function()
			return getInputTextSize(Value.read(props.size))
		end,
		isRequired = props.isRequired,
		isDisabled = props.isDisabled,
		hasError = props.hasError,
		hint = props.hint,
		textBoxRef = props.textBoxRef,
		input = function(textBoxRef: (InternalTextInputRef?) -> ())
			return InternalTextInput({
				textBoxRef = textBoxRef,
				inputRef = props.inputRef,
				hasError = props.hasError,
				isDisabled = props.isDisabled,
				hasClearButton = props.hasClearButton,
				text = props.text,
				textInputType = props.textInputType,
				focusBehavior = props.focusBehavior,
				size = props.size,
				variant = props.variant,
				Selectable = props.Selectable,
				NextSelectionUp = props.NextSelectionUp,
				NextSelectionDown = props.NextSelectionDown,
				NextSelectionLeft = props.NextSelectionLeft,
				NextSelectionRight = props.NextSelectionRight,
				horizontalPadding = {
					left = horizontalPadding,
					right = horizontalPadding,
				},
				onChanged = props.onChanged,
				onFocus = props.onFocusGained,
				onFocusLost = props.onFocusLost,
				onReturnPressed = props.onReturnPressed,
				placeholder = props.placeholder,
				leadingElement = leadingElement,
				trailingElement = trailingElement,
				testId = `{testId}--internal-text-input`,
			})
		end,
	}) :: any) :: GuiObject
end

return TextInput
