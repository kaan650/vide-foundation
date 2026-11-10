local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
local Constants = require("../../Constants")
local Icon = require("../Icon")
local InputSize = require("../../Enums/InputSize")
local InputVariant = require("../../Enums/InputVariant")
local InternalTextInput = require("../InternalTextInput")
local Radius = require("../../Enums/Radius")
local SearchInputShape = require("../../Enums/SearchInputShape")
local Translator = require("../../Utility/Localization/Translator")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local named = require("../../Utility/named")
local useScaledValue = require("../../Utility/useScaledValue")
local useTextInputVariants = require("../TextInput/useTextInputVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InputSize = InputSize.InputSize
type InputVariant = InputVariant.InputVariant
type Radius = Radius.Radius
type SearchInputShape = SearchInputShape.SearchInputShape
type TextInputRef = Types.TextInputRef
type Value<T> = Types.Value<T>

local SHAPE_TO_RADIUS: { [SearchInputShape]: Radius } = {
	[SearchInputShape.Pill] = Radius.Circle,
	[SearchInputShape.Box] = Radius.None,
}

export type SearchInputProps = {
	-- Typed text to display in the SearchInput
	text: Value<string>,
	-- Placeholder text for input (defaults to "Search")
	placeholder: Value<string?>?,
	-- Called when the text is changed in the SearchInput
	onChanged: (text: string) -> (),
	-- Size of the SearchInput
	size: Value<InputSize>?,
	-- Whether the SearchInput is disabled
	isDisabled: Value<boolean?>?,
	-- Whether to show the clear button (defaults to true)
	hasClearButton: Value<boolean?>?,
	-- Whether the SearchInput is in an error state
	hasError: Value<boolean?>?,
	-- Width of the SearchInput
	width: Value<UDim?>?,
	-- Style variant of the SearchInput
	variant: Value<InputVariant>?,
	-- Shape of the SearchInput
	shape: Value<SearchInputShape>?,
	-- Called when the SearchInput gains focus
	onFocusGained: (() -> ())?,
	-- Called when the SearchInput loses focus
	onFocusLost: ((inputObject: InputObject?) -> ())?,
	-- Receives a handle to the inner TextBox (React's `ref`).
	textBoxRef: ((TextInputRef) -> ())?,
} & Types.CommonProps

local defaultProps = {
	size = InputSize.Medium,
	variant = InputVariant.Standard,
	shape = SearchInputShape.Pill,
	hasClearButton = true,
	testId = "--foundation-search-input",
}

--- A search field with a magnifying glass and a clear button, pill-shaped by default.
local function SearchInput(searchInputProps: SearchInputProps): GuiObject
	local props = withDefaults(searchInputProps, defaultProps)
	local tokens = useTokens()
	local defaultWidth = useScaledValue(Constants.DEFAULT_INPUT_FIELD_WIDTH_PIXELS)
	local testId: string = props.testId

	local function size(): InputSize
		return Value.read(props.size)
	end
	local variantProps = Vide.derive(function()
		return useTextInputVariants(tokens(), size(), Value.read(props.variant))
	end)
	local function horizontalPadding(): UDim
		return variantProps().container.horizontalPadding
	end

	--TODO: Foundation may move this into InternalTextInput's default padding (UIBLOX-4313).
	local searchIcon = View({
		Position = function()
			return UDim2.fromOffset(0, (variantProps().container.minHeight - tokens().Stroke.Standard) / 2)
		end,
		tag = "anchor-center-left auto-xy",
		children = named(
			"Icon",
			Icon({
				name = BuilderIcons.Icon.MagnifyingGlass,
				size = size :: any,
				testId = `{testId}--search-icon`,
			})
		),
	})

	return View(withCommonProps(props, {
		Size = function()
			local width: UDim? = Value.read(props.width)
			return if width
				then UDim2.new(width, UDim.new(0, 0))
				else UDim2.new(UDim.new(0, defaultWidth()), UDim.new(0, 0))
		end,
		tag = "auto-y",
		children = named(
			"Input",
			InternalTextInput({
				textBoxRef = props.textBoxRef,
				hasError = props.hasError,
				isDisabled = props.isDisabled,
				hasClearButton = props.hasClearButton,
				text = props.text,
				size = props.size,
				radius = function(): Radius?
					return SHAPE_TO_RADIUS[Value.read(props.shape)]
				end,
				variant = props.variant,
				horizontalPadding = {
					left = horizontalPadding,
					right = horizontalPadding,
				},
				onChanged = props.onChanged,
				onFocus = props.onFocusGained,
				onFocusLost = props.onFocusLost,
				placeholder = function(): string
					return Value.read(props.placeholder) or Translator:FormatByKey("CommonUI.Controls.Action.Search")
				end,
				leadingElement = searchIcon,
				testId = `{testId}--input`,
			})
		),
	}) :: any)
end

return SearchInput
