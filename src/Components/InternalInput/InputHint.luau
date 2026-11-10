local InputLabelSize = require("../../Enums/InputLabelSize")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")

type InputLabelSize = InputLabelSize.InputLabelSize
type Value<T> = Types.Value<T>

export type InputHintProps = {
	text: Value<string>,
	size: Value<InputLabelSize?>?,
	isDisabled: Value<boolean?>?,
	testId: string?,
	LayoutOrder: Value<number>?,
	padding: Types.Padding?,
}

--- The secondary description under an input's label.
local function InputHint(props: InputHintProps): GuiObject
	return Text({
		Text = props.text,
		tag = function()
			local size: InputLabelSize = Value.read(props.size) or InputLabelSize.Medium
			local isDisabled = Value.read(props.isDisabled) == true
			return {
				["size-0 auto-xy text-wrap text-align-x-left text-align-y-top"] = true,
				["content-muted"] = isDisabled,
				["content-default"] = not isDisabled,
				["text-caption-small"] = size == InputLabelSize.Small or size == InputLabelSize.XSmall,
				["text-caption-medium"] = size == InputLabelSize.Medium or size == InputLabelSize.Large,
			}
		end,
		testId = props.testId,
		LayoutOrder = props.LayoutOrder,
		padding = props.padding,
	})
end

return InputHint
