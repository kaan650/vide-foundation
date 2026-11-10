local Vide = require("../../Packages/Vide")

local BaseMenu = require("../BaseMenu")
local BuilderIcons = require("../../Packages/BuilderIcons")
local Constants = require("../../Constants")
local Icon = require("../Icon")
local InputField = require("../InputField")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local blendTransparencies = require("../../Utility/blendTransparencies")
local getInputTextSize = require("../../Utility/getInputTextSize")
local useDropdownVariants = require("./useDropdownVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local ControlState = require("../../Enums/ControlState")
local InputSize = require("../../Enums/InputSize")
local InputVariant = require("../../Enums/InputVariant")

type BaseMenuItem = BaseMenu.BaseMenuItem
type ColorStyleValue = Types.ColorStyleValue
type ControlState = ControlState.ControlState
type InputSize = InputSize.InputSize
type InputVariant = InputVariant.InputVariant
type Stroke = Types.Stroke
type Value<T> = Types.Value<T>

local MENU_OPEN_IMAGE = BuilderIcons.Icon.ChevronLargeUp
local MENU_CLOSE_IMAGE = BuilderIcons.Icon.ChevronLargeDown

export type DropdownControlProps = {
	variant: Value<InputVariant>?,
	hasError: Value<boolean?>?,
	isDisabled: Value<boolean?>?,
	item: Value<BaseMenuItem?>?,
	placeholder: Value<string?>?,
	onActivated: () -> (),
	isMenuOpen: Value<boolean>?,
	width: Value<UDim>,
	size: Value<InputSize>,
	label: Value<string>,
	hint: Value<string?>?,
	-- Receives the clickable control inside the field.
	inputRef: ((GuiObject) -> ())?,
} & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	variant = InputVariant.Standard,
	isMenuOpen = false,
	placeholder = "",
	--* Selectable by default, so consumers don't have to opt in.
	Selectable = true,
}

--- The closed dropdown: a field showing the selected item's text or the placeholder, and an arrow.
local function DropdownControl(dropdownControlProps: DropdownControlProps): GuiObject
	local props = withDefaults(dropdownControlProps, defaultProps)
	local tokens = useTokens()
	local controlState = Vide.source(ControlState.Initialize :: ControlState)

	local function isDisabled(): boolean
		return Value.read(props.isDisabled) == true
	end

	local function item(): BaseMenuItem?
		return Value.read(props.item)
	end

	local function isMenuOpen(): boolean
		return Value.read(props.isMenuOpen) == true
	end

	local variantProps = Vide.derive(function()
		local state = controlState()
		return useDropdownVariants(
			tokens(),
			Value.read(props.size),
			Value.read(props.variant),
			state,
			item() == nil,
			Value.read(props.hasError) == true,
			isMenuOpen(),
			state == ControlState.Hover
		)
	end)

	local function input(): GuiObject
		local text = Text({
			LayoutOrder = 1,
			Text = function(): string
				local selected = item()
				return if selected then selected.text else Value.read(props.placeholder) or ""
			end,
			tag = function()
				return variantProps().text.tag
			end,
		})
		text.Name = "Text"

		local arrow = Icon({
			LayoutOrder = 2,
			name = function(): string
				return if isMenuOpen() then MENU_OPEN_IMAGE else MENU_CLOSE_IMAGE
			end,
			size = function()
				return variantProps().arrow.size
			end,
			style = function(): ColorStyleValue
				local color = tokens().Color.Content
				return (if isDisabled() then color.Muted else color.Default) :: ColorStyleValue
			end,
			testId = `{props.testId}--arrow`,
		})
		arrow.Name = "Arrow"

		local control = View({
			onStateChanged = function(state: ControlState)
				controlState(state)
			end,
			isDisabled = isDisabled,
			onActivated = function()
				props.onActivated()
			end,
			selection = {
				Selectable = function(): boolean
					return if isDisabled() then false else Value.read(props.Selectable) == true
				end,
				NextSelectionUp = props.NextSelectionUp,
				NextSelectionDown = props.NextSelectionDown,
				NextSelectionLeft = props.NextSelectionLeft,
				NextSelectionRight = props.NextSelectionRight,
			},
			cursor = function()
				local current = tokens()
				return {
					radius = UDim.new(0, current.Radius.Small),
					offset = current.Size.Size_200,
					borderWidth = current.Stroke.Thicker,
				}
			end,
			stateLayer = { affordance = StateLayerAffordance.None },
			backgroundStyle = (function(): ColorStyleValue?
				local bgStyle = variantProps().container.bgStyle
				if not bgStyle then
					return nil
				end
				return {
					Color3 = bgStyle.Color3,
					Transparency = if isDisabled()
						then blendTransparencies(bgStyle.Transparency, Constants.DISABLED_TRANSPARENCY)
						else bgStyle.Transparency,
				}
			end) :: any,
			stroke = function(): Stroke?
				local container = variantProps().container
				local strokeStyle = container.strokeStyle
				if not strokeStyle then
					return nil
				end
				return {
					Color = strokeStyle.Color3,
					Transparency = if isDisabled()
						then blendTransparencies(strokeStyle.Transparency, Constants.DISABLED_TRANSPARENCY)
						else strokeStyle.Transparency,
					Thickness = container.strokeThickness,
					BorderStrokePosition = Enum.BorderStrokePosition.Inner,
				}
			end,
			tag = function()
				return variantProps().container.tag
			end,
			testId = `{props.testId}--control`,
			children = { text, arrow },
		})
		if props.inputRef then
			props.inputRef(control)
		end
		return control
	end

	return InputField(withCommonProps(
		props,
		{
			size = function()
				return getInputTextSize(Value.read(props.size))
			end,
			hasError = props.hasError,
			isDisabled = props.isDisabled,
			label = props.label,
			hint = props.hint,
			width = props.width,
			input = input,
		} :: InputField.InputFieldProps
	))
end

return DropdownControl
