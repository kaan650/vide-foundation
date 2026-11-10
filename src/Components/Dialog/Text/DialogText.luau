local Text = require("../../Text")
local Types = require("../../Types")
local useDialog = require("../useDialog")
local useDialogVariants = require("../useDialogVariants").useDialogVariants

type Value<T> = Types.Value<T>

export type DialogTextProps = {
	Text: Value<string>?,
	LayoutOrder: Value<number>?,
}

--- Body text sized for the dialog.
local function DialogText(props: DialogTextProps): GuiObject
	local variants = useDialogVariants()
	local dialogContext = useDialog()

	return Text({
		Text = props.Text,
		--! RichText works around a TextLabel bug: its size does not update inside a ScrollView otherwise.
		RichText = true,
		tag = function()
			return variants().contentText.tag
		end,
		LayoutOrder = props.LayoutOrder,
		testId = `{dialogContext.testId}--text`,
	})
end

return DialogText
