local Image = require("../Image")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local MediaAspectRatio = require("../../Enums/MediaAspectRatio")
type MediaAspectRatio = MediaAspectRatio.MediaAspectRatio
local MediaOrientation = require("../../Enums/MediaOrientation")
type MediaOrientation = MediaOrientation.MediaOrientation

type Value<T> = Types.Value<T>

-- The ratio of the longer side to the shorter side for each aspect ratio.
local LONG_TO_SHORT: { [MediaAspectRatio]: number } = {
	[MediaAspectRatio.Ratio1x1] = 1,
	[MediaAspectRatio.Ratio5x4] = 5 / 4,
	[MediaAspectRatio.Ratio4x3] = 4 / 3,
	[MediaAspectRatio.Ratio3x2] = 3 / 2,
	[MediaAspectRatio.Ratio16x9] = 16 / 9,
	[MediaAspectRatio.Ratio2x1] = 2,
}

export type MediaImage = {
	-- Discriminator for image media.
	type: "Image",
	-- Image asset URI or Foundation image key.
	source: Value<string>,
}

--- The visual content to display, as a tagged union so new media types (e.g. video) can be added without changing
--- the API shape.
export type MediaContent = MediaImage

export type MediaProps = {
	-- The content to display, cropped to fill the aspect ratio.
	content: Value<MediaContent?>?,
	-- Aspect ratio of the media frame. Defaults to `MediaAspectRatio.Ratio1x1`.
	aspectRatio: Value<MediaAspectRatio>?,
	-- Whether the longer side is horizontal or vertical. Defaults to `MediaOrientation.Landscape`.
	orientation: Value<MediaOrientation>?,
} & Types.CommonProps

local defaultProps = {
	aspectRatio = MediaAspectRatio.Ratio1x1 :: MediaAspectRatio,
	orientation = MediaOrientation.Landscape :: MediaOrientation,
	testId = "--foundation-media",
}

local function getImageSource(content: MediaContent?): Value<string>?
	return if content and content.type == "Image" then content.source else nil
end

--- An image cropped to a fixed aspect ratio. It fills its container's width and takes its height from the ratio.
local function Media(mediaProps: MediaProps): GuiObject
	local props = withDefaults(mediaProps, defaultProps)

	local function widthOverHeight(): number
		local longToShort = LONG_TO_SHORT[Value.read(props.aspectRatio) :: MediaAspectRatio]
		return if Value.read(props.orientation) == MediaOrientation.Portrait then 1 / longToShort else longToShort
	end
	local isRatioReactive = type(props.aspectRatio) == "function" or type(props.orientation) == "function"

	local image: Value<string>?
	local content = props.content
	if type(content) == "function" then
		local getContent: () -> MediaContent? = content :: any
		image = function(): string
			--? Image turns a reactive image into ImageContent, which can't be set to nil.
			return Value.read(getImageSource(getContent())) or ""
		end
	else
		image = getImageSource(content :: MediaContent?)
	end

	return Image(withCommonProps(props, {
		Image = image,
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.fromScale(1, 0),
		aspectRatio = {
			AspectRatio = if isRatioReactive then widthOverHeight else widthOverHeight(),
			AspectType = Enum.AspectType.ScaleWithParentSize,
			DominantAxis = Enum.DominantAxis.Width,
		},
	}) :: any)
end

return Media
