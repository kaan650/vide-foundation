local Vide = require("../../Packages/Vide")

local Image = require("../Image")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local getRbxThumb = require("../../Utility/getRbxThumb")
local useAvatarIconVariants = require("./useAvatarIconVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local AvatarIconSize = require("../../Enums/AvatarIconSize")
type AvatarIconSize = AvatarIconSize.AvatarIconSize
local ThumbnailSize = require("../../Enums/ThumbnailSize")
local ThumbnailType = require("../../Enums/ThumbnailType")

type Value<T> = Types.Value<T>

export type AvatarIconProps = {
	userId: Value<number>,
	-- Fills the headshot's background.
	backgroundStyle: Types.ColorStyle?,
	-- Fills the circle behind the headshot and strokes its edge.
	backplateStyle: Types.ColorStyle?,
	size: Value<AvatarIconSize>?,
} & Types.CommonProps

local defaultProps = {
	size = AvatarIconSize.Medium,
	testId = "--foundation-avatar-icon",
}

--- A user's round headshot at icon sizes.
local function AvatarIcon(avatarIconProps: AvatarIconProps): GuiObject
	local props = withDefaults(avatarIconProps, defaultProps)
	local tokens = useTokens()

	local variantProps = Vide.derive(function()
		return useAvatarIconVariants(tokens(), Value.read(props.size), props.backplateStyle)
	end)

	local image = Image({
		Image = function()
			return getRbxThumb(ThumbnailType.AvatarHeadShot, Value.read(props.userId), ThumbnailSize.Medium)
		end,
		tag = function()
			return variantProps().avatar.tag
		end,
		backgroundStyle = props.backgroundStyle,
	})
	image.Name = "Image"

	return View(withCommonProps(props, {
		tag = function()
			return variantProps().container.tag
		end,
		stroke = function()
			return variantProps().container.stroke
		end,
		backgroundStyle = props.backplateStyle,
		Size = function()
			local size = variantProps().container.size
			return UDim2.fromOffset(size, size)
		end,
		children = image,
	}) :: any)
end

return AvatarIcon
