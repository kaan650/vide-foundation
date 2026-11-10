local Vide = require("../../Packages/Vide")

local FoundationCloudAssets = require("../../Packages/FoundationCloudAssets")
local FoundationImages = require("../../Packages/FoundationImages")

local AspectRatio = require("../AspectRatio")
local GuiObjectChildren = require("../../Utility/GuiObjectChildren")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local create = require("../../Utility/create")
local getScaledSlice = require("./ImageSet/getScaledSlice")
local getTestIdTag = require("../../Utility/getTestIdTag")
local isCloudAsset = require("./CloudAsset/isCloudAsset")
local isFoundationImage = require("./ImageSet/isFoundationImage")
local tags = require("../../Utility/tags")
local useOnLoaded = require("./useOnLoaded")
local withDefaults = require("../../Utility/withDefaults")
local withGuiObjectProps = require("../../Utility/withGuiObjectProps")
local withInteractable = require("../Interactable/withInteractable")

type ImageSetImage = FoundationImages.ImageSetImage
type ColorStyle = Types.ColorStyle
type Slice = Types.Slice
type Value<T> = Types.Value<T>

local Assets: { [string]: { assetId: string, size: Vector2 } } = FoundationCloudAssets.Assets :: any
local Images = FoundationImages.Images
local DeprecatedIconImages: { [string]: ImageSetImage } = FoundationImages.IconImages_DEPRECATED :: any

export type ImageRect = {
	offset: Value<Vector2>?,
	size: Value<Vector2>?,
}

export type ImageProps = {
	slice: Slice?,
	imageRect: ImageRect?,
	imageStyle: ColorStyle?,
	-- A FoundationImages key ("icons/common/robux"), a cloud asset key ("pictograms/alert") or an asset URI.
	Image: Value<string>?,
	ImageContent: Value<string | Content>?,
	AutoButtonColor: Value<boolean>?,
	ResampleMode: Value<Enum.ResamplerMode>?,
	ScaleType: Value<Enum.ScaleType>?,
	TileSize: Value<UDim2>?,
	-- Called when the image asset finishes fetching, with Success, Failure or TimedOut.
	onLoaded: ((assetStatus: Enum.AssetFetchStatus) -> ())?,
} & Types.GuiObjectProps & Types.CommonProps

local defaultProps = {
	AutoLocalize = false,
	AutoButtonColor = false,
	BorderSizePixel = 0,
	isDisabled = false,
}

local DEFAULT_TAGS = "gui-object-defaults"
local DEFAULT_TAGS_WITH_BG = `{DEFAULT_TAGS} x-default-transparency`

--* Unknown keys index FoundationImages' guard, which throws; malformed input must not break the UI.
local function getFoundationImageAsset(image: string): ImageSetImage?
	local deprecatedImage = DeprecatedIconImages[image]
	if deprecatedImage then
		return deprecatedImage
	end
	return rawget(Images :: any, image)
end

local function shouldUseFoundationSlice(image: string): boolean
	if not isFoundationImage(image) then
		return false
	end
	return isCloudAsset(image) or getFoundationImageAsset(image) ~= nil
end

type Resolved = {
	image: string?,
	rectOffset: Value<Vector2>?,
	rectSize: Value<Vector2>?,
	aspectRatio: number?,
}

local function resolve(image: string?, imageRect: ImageRect?): Resolved
	local resolved: Resolved = {
		image = image,
		rectOffset = if imageRect then imageRect.offset else nil,
		rectSize = if imageRect then imageRect.size else nil,
	}
	if image and isFoundationImage(image) then
		if isCloudAsset(image) then
			local asset = Assets[image]
			resolved.image = asset.assetId
			resolved.aspectRatio = asset.size.X / asset.size.Y
		else
			local asset = getFoundationImageAsset(image)
			if asset then
				resolved.image = asset.Image
				resolved.rectOffset = asset.ImageRectOffset
				resolved.rectSize = asset.ImageRectSize
			end
		end
	end
	return resolved
end

local function toContent(value: string | Content): Content
	return if typeof(value) == "string" then Content.fromUri(value) else value
end

--- Foundation's image: an ImageLabel, or an ImageButton when it handles input. Resolves FoundationImages and cloud
--- asset keys into their asset and image rect.
local function Image(imageProps: ImageProps): GuiObject
	local props = withDefaults(imageProps, defaultProps)
	local isInteractable = props.onStateChanged ~= nil or props.onActivated ~= nil or props.onSecondaryActivated ~= nil
	local class = if isInteractable then "ImageButton" else "ImageLabel"
	local isReactiveImage = type(props.Image) == "function"

	local resolved: () -> Resolved
	if isReactiveImage then
		resolved = Vide.derive(function()
			return resolve(Value.read(props.Image), props.imageRect)
		end)
	else
		local static = resolve(props.Image :: string?, props.imageRect)
		resolved = function()
			return static
		end
	end

	local properties: { [any]: any } = {
		AutoButtonColor = if class == "ImageButton" then props.AutoButtonColor else nil,
		ResampleMode = props.ResampleMode,
		TileSize = props.TileSize,
		tags(function()
			return if Value.read(props.backgroundStyle) ~= nil then DEFAULT_TAGS_WITH_BG else DEFAULT_TAGS
		end, props.tag, getTestIdTag(props.testId)),
	}

	if props.ImageContent ~= nil then
		local imageContent = props.ImageContent
		properties.ImageContent = if type(imageContent) == "function"
			then function()
				return toContent((imageContent :: () -> string | Content)())
			end
			else toContent(imageContent :: string | Content)
	elseif props.Image ~= nil then
		local function imageContent(): Content?
			local image = resolved().image
			return if image then Content.fromUri(image) else nil
		end
		properties.ImageContent = if isReactiveImage then imageContent else imageContent()
	end

	local function rect(key: "rectOffset" | "rectSize"): Value<Vector2>?
		if isReactiveImage then
			return function(): Vector2
				local value: Value<Vector2>? = (resolved() :: any)[key]
				return Value.read(value) or Vector2.zero
			end
		end
		return (resolved() :: any)[key]
	end
	properties.ImageRectOffset = rect("rectOffset")
	properties.ImageRectSize = rect("rectSize")

	local imageStyle = props.imageStyle
	if imageStyle ~= nil then
		if type(imageStyle) == "function" then
			table.insert(properties, Value.bindProperty("ImageColor3", Value.index(imageStyle, "Color3")))
			table.insert(properties, Value.bindProperty("ImageTransparency", Value.index(imageStyle, "Transparency")))
		else
			properties.ImageColor3 = imageStyle.Color3
			properties.ImageTransparency = imageStyle.Transparency
		end
	end

	local slice = props.slice
	if slice then
		local function scaledSlice(): Slice
			local image = Value.read(props.Image)
			return if image and shouldUseFoundationSlice(image)
				then getScaledSlice(slice.center, slice.scale)
				else slice
		end
		if isReactiveImage then
			properties.SliceCenter = function()
				return scaledSlice().center or Rect.new(0, 0, 0, 0)
			end
			properties.SliceScale = function()
				return scaledSlice().scale or 1
			end
		else
			local static = scaledSlice()
			properties.SliceCenter = static.center
			properties.SliceScale = static.scale
		end
		properties.ScaleType = Enum.ScaleType.Slice
	else
		properties.ScaleType = props.ScaleType
	end

	--* A cloud asset brings its own aspect ratio. A reactive image gets the constraint only while it is a cloud asset.
	local childProps = props
	if props.aspectRatio == nil then
		if isReactiveImage then
			table.insert(
				properties,
				Vide.show(function()
					return resolved().aspectRatio
				end, function(ratio: () -> number)
					return AspectRatio({ value = ratio })
				end)
			)
		elseif resolved().aspectRatio then
			childProps = table.clone(props)
			childProps.aspectRatio = resolved().aspectRatio
		end
	end
	table.insert(properties, GuiObjectChildren(childProps))

	useOnLoaded(function()
		return resolved().image
	end, props.onLoaded)

	withGuiObjectProps.withGuiObjectProps(props, properties)

	if isInteractable then
		local backgroundStyle = props.backgroundStyle
		withInteractable({
			BackgroundColor3 = if backgroundStyle then Value.index(backgroundStyle, "Color3") else nil,
			BackgroundTransparency = if backgroundStyle then Value.index(backgroundStyle, "Transparency") else nil,
			SelectionImageObject = if props.selection then props.selection.SelectionImageObject else nil,
			isDisabled = props.isDisabled,
			onActivated = props.onActivated,
			onSecondaryActivated = props.onSecondaryActivated,
			onStateChanged = props.onStateChanged,
			stateLayer = props.stateLayer,
			cursor = props.cursor,
		}, properties)
	else
		withGuiObjectProps.backgroundProperties(props, properties)
	end

	return (create :: any)(class)(properties)
end

return Image
