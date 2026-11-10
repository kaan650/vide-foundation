local ThumbnailType = require("../Enums/ThumbnailType")
type ThumbnailType = ThumbnailType.ThumbnailType

local ThumbnailSize = require("../Enums/ThumbnailSize")
type ThumbnailSize = ThumbnailSize.ThumbnailSize

local getAssetIdAsNumeric = require("./getAssetIdAsNumeric")

type AssetId = string | number

export type AvatarHeadShotOptions = {
	-- Composites the user's equipped profile frame into the headshot, server-side.
	includeProfileFrame: boolean?,
}

-- The sizes the rbxthumb protocol accepts for each type, in pixels.
local SIZE_TO_DIMENSIONS: { [ThumbnailType]: { [ThumbnailSize]: Vector2 } } = {
	[ThumbnailType.Asset] = {
		[ThumbnailSize.Medium] = Vector2.new(150, 150),
		[ThumbnailSize.Large] = Vector2.new(420, 420),
	},
	[ThumbnailType.Avatar] = {
		[ThumbnailSize.Small] = Vector2.new(48, 48),
		[ThumbnailSize.Medium] = Vector2.new(150, 150),
		[ThumbnailSize.Large] = Vector2.new(420, 420),
		[ThumbnailSize.XLarge] = Vector2.new(720, 720),
	},
	[ThumbnailType.AvatarBust] = {
		[ThumbnailSize.Small] = Vector2.new(50, 50),
		[ThumbnailSize.Medium] = Vector2.new(150, 150),
		[ThumbnailSize.Large] = Vector2.new(420, 420),
	},
	[ThumbnailType.AvatarHeadShot] = {
		[ThumbnailSize.Small] = Vector2.new(48, 48),
		[ThumbnailSize.Medium] = Vector2.new(150, 150),
		[ThumbnailSize.Large] = Vector2.new(420, 420),
	},
	[ThumbnailType.BadgeIcon] = {
		[ThumbnailSize.Medium] = Vector2.new(150, 150),
	},
	[ThumbnailType.BundleThumbnail] = {
		[ThumbnailSize.Medium] = Vector2.new(150, 150),
		[ThumbnailSize.Large] = Vector2.new(420, 420),
	},
	[ThumbnailType.FontFamily] = {
		[ThumbnailSize.Medium] = Vector2.new(1200, 80),
	},
	[ThumbnailType.GameIcon] = {
		[ThumbnailSize.Small] = Vector2.new(50, 50),
		[ThumbnailSize.Medium] = Vector2.new(150, 150),
	},
	[ThumbnailType.GamePass] = {
		[ThumbnailSize.Medium] = Vector2.new(150, 150),
	},
	[ThumbnailType.GameThumbnail] = {
		[ThumbnailSize.Small] = Vector2.new(256, 144),
		[ThumbnailSize.Medium] = Vector2.new(384, 216),
		[ThumbnailSize.Large] = Vector2.new(480, 270),
		[ThumbnailSize.XLarge] = Vector2.new(768, 432),
	},
	[ThumbnailType.GroupIcon] = {
		[ThumbnailSize.Medium] = Vector2.new(150, 150),
		[ThumbnailSize.Large] = Vector2.new(420, 420),
	},
	[ThumbnailType.Outfit] = {
		[ThumbnailSize.Medium] = Vector2.new(150, 150),
		[ThumbnailSize.Large] = Vector2.new(420, 420),
	},
}

--- An `rbxthumb://` URI for a thumbnail of `id`. A size the type does not support falls back to Medium.
local function getRbxThumb(
	type: ThumbnailType,
	id: AssetId,
	size: ThumbnailSize?,
	options: AvatarHeadShotOptions?
): string
	local dimensions = SIZE_TO_DIMENSIONS[type][size or ThumbnailSize.Medium]
	local assetId = getAssetIdAsNumeric(id)

	if not dimensions then
		warn(`Unsupported size {size} for media type: {type}, defaulting to {ThumbnailSize.Medium}`)
		dimensions = SIZE_TO_DIMENSIONS[type][ThumbnailSize.Medium]
	end

	local url = `rbxthumb://type={type}&id={assetId}&w={dimensions.X}&h={dimensions.Y}`
	if type == ThumbnailType.AvatarHeadShot and options and options.includeProfileFrame then
		url ..= "&includeprofileframe=true"
	end
	return url
end

return getRbxThumb
