local ControlState = require("../../Enums/ControlState")
local InputLabelSize = require("../../Enums/InputLabelSize")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Text = require("../Text")
local Translator = require("../../Utility/Localization/Translator")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local rebuildOn = require("../../Utility/rebuildOn")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ControlState = ControlState.ControlState
type InputLabelSize = InputLabelSize.InputLabelSize
type Value<T> = Types.Value<T>

local REQUIRED_INDICATOR = "*"

export type InputLabelProps = {
	-- Optional text style override
	textStyle: Types.ColorStyle?,
	-- Whether the input is required or not. Leave nil for the majority case
	isRequired: Value<boolean?>?,
	-- Whether the input is disabled
	isDisabled: Value<boolean?>?,
	-- Size of the input label
	size: Value<InputLabelSize>?,
	-- Callback for when the input label is activated.
	-- This should trigger the activation of the associated input button.
	onActivated: (() -> ())?,
	-- Callback for when the input label is hovered over.
	-- This should trigger the hover state of the associated input button.
	onHover: ((boolean) -> ())?,
	-- Whether the input label should be rich text or not
	RichText: Value<boolean>?,
	-- Determines the string rendered by the UI element
	Text: Value<string>,
} & Types.CommonProps

local function labelText(text: string, isRequired: boolean?): string
	if isRequired == nil then
		return text
	end
	return if isRequired
		then `{text} {REQUIRED_INDICATOR}`
		else Translator:FormatByKey("CommonUI.Controls.Input.Optional", { inputLabel = text })
end

local defaultProps = {
	size = InputLabelSize.Medium :: InputLabelSize,
	testId = "--foundation-input-label",
}

--- The label of a form input. Activating or hovering it is forwarded to the input. With input callbacks, a source
--- `isDisabled` returns a source of the instance: a disabled label is a TextLabel, an enabled one a TextButton.
local function InputLabel(inputLabelProps: InputLabelProps): GuiObject | () -> GuiObject
	local props = withDefaults(inputLabelProps, defaultProps)

	local onHover = props.onHover
	local onStateChanged = if onHover
		then function(newState: ControlState)
			onHover(newState == ControlState.Hover)
		end
		else nil

	local function isDisabled(): boolean
		return Value.read(props.isDisabled) == true
	end

	local function build(disabled: boolean?): GuiObject
		return Text(withCommonProps(props, {
			Text = function()
				return labelText(Value.read(props.Text), Value.read(props.isRequired))
			end,
			RichText = props.RichText,
			--* Directional input focuses the input itself, not its label.
			selection = {
				Selectable = false,
			},
			onActivated = if not disabled and props.onActivated
				then function()
					(props.onActivated :: () -> ())()
				end
				else nil,
			onStateChanged = if not disabled then onStateChanged else nil,
			stateLayer = { affordance = StateLayerAffordance.None },
			textStyle = props.textStyle,
			tag = function()
				local size = Value.read(props.size)
				local muted = isDisabled()
				return {
					["size-0 auto-xy text-wrap text-align-x-left text-align-y-top"] = true,
					["padding-top-xxsmall"] = size ~= InputLabelSize.XSmall,
					["content-muted"] = muted,
					["content-emphasis"] = not muted,
					["text-body-small"] = size == InputLabelSize.Small or size == InputLabelSize.XSmall,
					["text-body-medium"] = size == InputLabelSize.Medium,
					["text-body-large"] = size == InputLabelSize.Large,
				}
			end,
		}) :: any)
	end

	if props.onActivated == nil and onHover == nil then
		return build(nil)
	end
	return rebuildOn<<boolean?>>(props.isDisabled, build)
end

return InputLabel
