local Vide = require("../../../Packages/Vide")

local Image = require("../../Image")
local MediaShape = require("../../../Enums/MediaShape")
local MediaType = require("../../../Enums/MediaType")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local getRbxThumb = require("../../../Utility/getRbxThumb")
local useTile = require("../useTile")
local withDefaults = require("../../../Utility/withDefaults")

type MediaShape = MediaShape.MediaShape
type MediaType = MediaType.MediaType
type ColorStyle = Types.ColorStyle
type Value<T> = Types.Value<T>

local SHAPE_TO_ASPECT_RATIO: { [MediaShape]: number } = {
	[MediaShape.Circle] = 1,
	[MediaShape.Square] = 1,
	[MediaShape.Landscape] = 16 / 9,
	[MediaShape.Portrait] = 9 / 16,
}

export type TileMediaBackground = {
	image: string?,
	style: ColorStyle?,
}

export type TileMediaProps = {
	-- With `type`, shows this id's rbxthumb thumbnail.
	id: Value<number?>?,
	type: Value<MediaType?>?,
	shape: Value<MediaShape>?,
	style: ColorStyle?,
	-- Whether the background is an image is decided from its first value.
	background: Value<TileMediaBackground?>?,
	onStateChanged: Types.StateChangedCallback?,
	children: Types.Children?,
	LayoutOrder: Value<number>?,
}

local defaultProps = {
	shape = MediaShape.Square,
	LayoutOrder = 1,
}

--- The tile's thumbnail, sized to its shape's aspect ratio along the tile's direction.
local function TileMedia(tileMediaProps: TileMediaProps): GuiObject
	local props = withDefaults(tileMediaProps, defaultProps)
	local tileContext = useTile()

	local function background(): TileMediaBackground?
		return Value.read(props.background)
	end
	local function shape(): MediaShape
		return Value.read(props.shape)
	end
	local function isVertical(): boolean
		return Value.read(tileContext.fillDirection) == Enum.FillDirection.Vertical
	end
	local function isContained(): boolean
		return Value.read(tileContext.isContained) == true
	end
	local function backgroundStyle(): Types.ColorStyleValue?
		local current = background()
		return if current then Value.read(current.style) else nil
	end

	local function thumbnail(): string?
		local id: number? = Value.read(props.id)
		local mediaType: MediaType? = Value.read(props.type)
		if id == nil or mediaType == nil then
			return nil
		end
		return getRbxThumb(mediaType, id)
	end

	local imageProps: { [string]: any } = {
		imageStyle = props.style,
		tag = function()
			local vertical, contained, currentShape = isVertical(), isContained(), shape()
			return {
				["size-full"] = true,
				["padding-medium"] = props.children ~= nil,
				["radius-top-medium"] = vertical and contained,
				["radius-left-medium"] = not vertical and contained,
				["radius-medium"] = currentShape ~= MediaShape.Circle and not contained,
				["radius-circle"] = currentShape == MediaShape.Circle,
			}
		end,
		testId = `{tileContext.testId}--media-image`,
		children = props.children,
	}
	if type(props.id) == "function" or type(props.type) == "function" then
		--* Image binds `Image` as a plain property, which cannot be nil, so a reactive thumbnail goes in as content.
		imageProps.ImageContent = function(): Content
			local uri = thumbnail()
			return if uri then Content.fromUri(uri) else Content.none
		end
	else
		imageProps.Image = thumbnail()
	end
	local image = Image(imageProps :: any)
	image.Name = "Image"

	local rootProps: { [string]: any } = {
		Size = function()
			return if isVertical() then UDim2.fromScale(1, 0) else UDim2.fromScale(0, 1)
		end,
		ZIndex = 0,
		LayoutOrder = props.LayoutOrder,
		aspectRatio = {
			AspectRatio = function()
				return SHAPE_TO_ASPECT_RATIO[shape()]
			end,
			AspectType = Enum.AspectType.ScaleWithParentSize,
			DominantAxis = function()
				return if isVertical() then Enum.DominantAxis.Width else Enum.DominantAxis.Height
			end,
		},
		tag = function()
			local vertical, contained, currentShape = isVertical(), isContained(), shape()
			return {
				["radius-top-medium"] = vertical and contained,
				["radius-left-medium"] = not vertical and contained,
				["radius-medium"] = currentShape ~= MediaShape.Circle and not contained,
				["radius-circle"] = currentShape == MediaShape.Circle and not contained,
			}
		end,
		onStateChanged = props.onStateChanged,
		testId = `{tileContext.testId}--media`,
		children = image,
	}

	local isBackgroundReactive = type(props.background) == "function"
	local initialBackground = Vide.untrack(background)
	local style: Types.ColorStyle? = if isBackgroundReactive
		then backgroundStyle :: any
		elseif initialBackground then initialBackground.style
		else nil

	if initialBackground and initialBackground.image then
		rootProps.Image = if isBackgroundReactive
			then function()
				local current = background()
				return if current then current.image or "" else ""
			end
			else initialBackground.image
		rootProps.imageStyle = style
		return Image(rootProps :: any)
	end
	rootProps.backgroundStyle = style
	return View(rootProps :: any)
end

return TileMedia
