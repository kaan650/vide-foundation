local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local withCommonProps = require("../../Utility/withCommonProps")

type Value<T> = Types.Value<T>

export type HintTextProps = {
	-- Determines the string rendered by the UI element
	text: Value<string>,
	-- Whether the input is in an error state
	hasError: Value<boolean?>?,
	-- Whether the input is disabled
	isDisabled: Value<boolean?>?,
} & Types.CommonProps

--- The caption under a form input, red on error.
local function HintText(props: HintTextProps): GuiObject
	return Text(withCommonProps(props, {
		Text = props.text,
		tag = function()
			local hasError = Value.read(props.hasError)
			local isDisabled = Value.read(props.isDisabled)
			return {
				["size-full-0 auto-y text-caption-small text-align-x-left text-align-y-top text-wrap"] = true,
				["content-action-alert"] = hasError == true,
				["content-muted"] = isDisabled == true and not hasError,
				["content-default"] = not isDisabled and not hasError,
			}
		end,
	}) :: any)
end

return HintText
