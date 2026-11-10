local Vide = require("../../Packages/Vide")

local Image = require("../Image")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local StatusIndicator = require("../StatusIndicator")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local getAvatarSize = require("./getAvatarSize")
local getRbxThumb = require("../../Utility/getRbxThumb")
local useAvatarVariants = require("./useAvatarVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local AvatarSize = require("../../Enums/AvatarSize")
type AvatarSize = AvatarSize.AvatarSize
local ThumbnailSize = require("../../Enums/ThumbnailSize")
local ThumbnailType = require("../../Enums/ThumbnailType")
local UserPresence = require("../../Enums/UserPresence")
type UserPresence = UserPresence.UserPresence
local StatusIndicatorShape = require("../../Enums/StatusIndicatorShape")
type StatusIndicatorShape = StatusIndicatorShape.StatusIndicatorShape
local StatusIndicatorSize = require("../../Enums/StatusIndicatorSize")
type StatusIndicatorSize = StatusIndicatorSize.StatusIndicatorSize
local StatusIndicatorVariant = require("../../Enums/StatusIndicatorVariant")
type StatusIndicatorVariant = StatusIndicatorVariant.StatusIndicatorVariant

type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

export type AvatarProps = {
	-- Roblox user id.
	userId: Value<number>,
	-- Fills the headshot's background.
	backgroundStyle: Types.ColorStyle?,
	-- Fills the circle behind the headshot and strokes its edge.
	backplateStyle: Types.ColorStyle?,
	size: Value<AvatarSize>?,
	userPresence: Value<UserPresence>?,
	-- Asks the thumbnail service to composite the user's equipped profile frame into the headshot.
	includeProfileFrame: Value<boolean?>?,
} & Types.CommonProps

local defaultProps = {
	size = AvatarSize.Medium,
	userPresence = UserPresence.None :: UserPresence,
	testId = "--foundation-avatar",
}

--- A user's round headshot, with a presence ring or status dot.
local function Avatar(avatarProps: AvatarProps): GuiObject
	local props = withDefaults(avatarProps, defaultProps)
	local tokens = useTokens()
	local isIconSize = PresentationContext.usePresentationContext().isIconSize

	local function size(): AvatarSize
		return Value.read(props.size)
	end

	local variantProps = Vide.derive(function()
		return useAvatarVariants(tokens(), size(), Value.read(props.userPresence), props.backplateStyle, isIconSize)
	end)

	local image = Image({
		Image = function()
			return getRbxThumb(ThumbnailType.AvatarHeadShot, Value.read(props.userId), ThumbnailSize.Medium, {
				includeProfileFrame = Value.read(props.includeProfileFrame),
			})
		end,
		tag = function()
			return variantProps().avatar.tag
		end,
		backgroundStyle = props.backgroundStyle,
		testId = `{props.testId}--image`,
	})
	image.Name = "Image"

	local indicator = Vide.show(function()
		return variantProps().statusIndicator.isVisible
	end, function()
		local statusIndicator = StatusIndicator({
			testId = `{props.testId}--status-indicator`,
			variant = function()
				return variantProps().statusIndicator.variant :: StatusIndicatorVariant
			end,
			shape = function()
				return variantProps().statusIndicator.shape :: StatusIndicatorShape
			end,
			size = function()
				return variantProps().statusIndicator.size :: StatusIndicatorSize
			end,
			mask = function(): ColorStyleValue
				return variantProps().statusIndicatorMask.mask
			end,
			ZIndex = function()
				return variantProps().statusIndicatorMask.ZIndex
			end,
			AnchorPoint = function()
				return variantProps().statusIndicatorMask.AnchorPoint
			end,
			Position = function()
				return variantProps().statusIndicatorMask.Position
			end,
		})
		statusIndicator.Name = "Indicator"
		return statusIndicator
	end)

	return View(withCommonProps(props, {
		tag = function()
			return variantProps().container.tag
		end,
		backgroundStyle = props.backplateStyle,
		stroke = function()
			return variantProps().container.stroke
		end,
		Size = function()
			local diameter = getAvatarSize(tokens(), size(), isIconSize)
			return UDim2.fromOffset(diameter, diameter)
		end,
		children = { image, indicator },
	}) :: any)
end

return Avatar
