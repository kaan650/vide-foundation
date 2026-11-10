local Vide = require("../../../Packages/Vide")

local Constants = require("../../../Constants")
local Image = require("../../Image")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local useDialog = require("../useDialog")
local useDialogVariants = require("../useDialogVariants").useDialogVariants
local withDefaults = require("../../../Utility/withDefaults")

type Value<T> = Types.Value<T>
type AspectRatio = Types.AspectRatio
type ColorStyle = Types.ColorStyle

export type DialogHeroMediaProps = {
	media: Value<string>,
	mediaStyle: ColorStyle?,
	backgroundStyle: ColorStyle?,
	height: Value<UDim>?,
	aspectRatio: AspectRatio?,
}

local defaultProps = {
	height = UDim.new(1, 0),
}

--- An image across the top of the dialog, edge to edge.
local function DialogHeroMedia(mediaProps: DialogHeroMediaProps): GuiObject
	local props = withDefaults(mediaProps, defaultProps)
	local dialogContext = useDialog()
	local variants = useDialogVariants()

	dialogContext.setHasHeroMedia(true)
	Vide.cleanup(function()
		dialogContext.setHasHeroMedia(false)
	end)

	local function offsetX(): number
		return variants().heroMedia.offsetX
	end

	local image = Image({
		Image = props.media,
		imageStyle = props.mediaStyle,
		backgroundStyle = props.backgroundStyle,
		tag = function()
			return variants().heroMedia.tag
		end,
		aspectRatio = props.aspectRatio,
		Position = function()
			return UDim2.fromOffset(-offsetX(), 0)
		end,
		Size = function()
			local height: UDim = Value.read(props.height)
			return UDim2.new(1, offsetX() * 2, height.Scale, height.Offset)
		end,
	})
	image.Name = "Image"

	return View({
		tag = function()
			return variants().heroMediaWrapper.tag
		end,
		LayoutOrder = Constants.MIN_LAYOUT_ORDER,
		testId = `{dialogContext.testId}--hero-media`,
		children = image,
	})
end

return DialogHeroMedia
