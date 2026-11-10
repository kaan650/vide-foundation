local Constants = require("../../../Constants")
local Text = require("../../Text")
local Types = require("../../Types")
local View = require("../../View")
local useDialog = require("../useDialog")
local useDialogVariants = require("../useDialogVariants").useDialogVariants
local useTokens = require("../../../Providers/Style/useTokens")

type Value<T> = Types.Value<T>

export type DialogTitleProps = {
	text: Value<string>,
}

local NO_PADDING = UDim.new(0, 0)

--- The dialog's heading. Leaves room for the close button unless the dialog has hero media.
local function DialogTitle(props: DialogTitleProps): GuiObject
	local tokens = useTokens()
	local dialogContext = useDialog()
	local variants = useDialogVariants()

	local title = Text({
		tag = function()
			return variants().titleText.tag
		end,
		Text = props.text,
	})
	title.Name = "Title"

	return View({
		tag = function()
			return variants().title.tag
		end,
		--* Second after HeroMedia.
		LayoutOrder = Constants.MIN_LAYOUT_ORDER + 1,
		padding = {
			right = function()
				return if dialogContext.hasHeroMedia()
					then NO_PADDING
					else UDim.new(0, variants().closeAffordance.offset + tokens().Size.Size_1000)
			end,
			top = function()
				return if dialogContext.hasHeroMedia() then NO_PADDING else UDim.new(0, tokens().Size.Size_500)
			end,
		},
		testId = `{dialogContext.testId}--title`,
		children = title,
	})
end

return DialogTitle
