local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local VariantsContext = require("../../Providers/Style/VariantsContext")

local AvatarSize = require("../../Enums/AvatarSize")
type AvatarSize = AvatarSize.AvatarSize
local UserPresence = require("../../Enums/UserPresence")
type UserPresence = UserPresence.UserPresence
local StatusIndicatorVariant = require("../../Enums/StatusIndicatorVariant")
type StatusIndicatorVariant = StatusIndicatorVariant.StatusIndicatorVariant
local StatusIndicatorSize = require("../../Enums/StatusIndicatorSize")
type StatusIndicatorSize = StatusIndicatorSize.StatusIndicatorSize
local StatusIndicatorShape = require("../../Enums/StatusIndicatorShape")
type StatusIndicatorShape = StatusIndicatorShape.StatusIndicatorShape

local Types = require("../Types")
local Value = require("../../Utility/Value")

export type AvatarVariantProps = {
	container: {
		tag: string,
		stroke: Types.Stroke?,
		backgroundStyle: Types.ColorStyle?,
	},
	avatar: {
		tag: string,
	},
	statusIndicatorMask: {
		Position: UDim2,
		AnchorPoint: Vector2,
		ZIndex: number,
		mask: Types.ColorStyleValue,
	},
	statusIndicator: {
		size: StatusIndicatorSize?,
		shape: StatusIndicatorShape?,
		variant: StatusIndicatorVariant?,
		isVisible: boolean,
	},
}

local function variantsFactory(tokens: Tokens)
	local common: VariantProps = {
		container = { tag = "radius-circle" },
		avatar = { tag = "size-full radius-circle" },
		statusIndicatorMask = {
			ZIndex = 2,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -tokens.Size.Size_150 / 2, 1, -tokens.Size.Size_150 / 2),
			mask = tokens.Color.Surface.Surface_0,
		},
	}

	local sizes: { [AvatarSize]: VariantProps } = {
		[AvatarSize.XSmall] = { statusIndicator = { size = StatusIndicatorSize.XSmall } },
		[AvatarSize.Small] = { statusIndicator = { size = StatusIndicatorSize.XSmall } },
		[AvatarSize.Medium] = { statusIndicator = { size = StatusIndicatorSize.Small } },
		[AvatarSize.Large] = { statusIndicator = { size = StatusIndicatorSize.Small } },
		[AvatarSize.XLarge] = { statusIndicator = { size = StatusIndicatorSize.Medium } },
		[AvatarSize.Pictogram] = { statusIndicator = { size = StatusIndicatorSize.Large } },
	}

	local presence: { [UserPresence]: VariantProps } = {
		[UserPresence.InExperience] = {},
		[UserPresence.Away] = {
			statusIndicator = { shape = StatusIndicatorShape.Ring, variant = StatusIndicatorVariant.Neutral },
		},
		[UserPresence.Active] = {
			statusIndicator = { shape = StatusIndicatorShape.Circle, variant = StatusIndicatorVariant.Success },
		},
		[UserPresence.None] = {},
	}

	local sizeStrokes: { [AvatarSize]: number } = {
		[AvatarSize.Small] = tokens.Stroke.Thicker,
		[AvatarSize.Medium] = tokens.Stroke.Thicker,
		[AvatarSize.Large] = tokens.Stroke.Thicker,
		[AvatarSize.XLarge] = tokens.Stroke.Thicker,
		[AvatarSize.Pictogram] = tokens.Stroke.Thicker + tokens.Stroke.Standard,
	}

	local iconSizeStrokes: { [AvatarSize]: number } = {
		[AvatarSize.XSmall] = tokens.Stroke.Standard,
		--* 2px in the design, which has no token.
		[AvatarSize.Small] = tokens.Stroke.Thick,
		[AvatarSize.Medium] = tokens.Stroke.Thick,
		[AvatarSize.Large] = tokens.Stroke.Thicker,
		[AvatarSize.XLarge] = tokens.Stroke.Thicker,
		[AvatarSize.Pictogram] = tokens.Stroke.Thicker,
	}

	return {
		common = common,
		sizes = sizes,
		presence = presence,
		iconSizeStrokes = iconSizeStrokes,
		sizeStrokes = sizeStrokes,
	}
end

return function(
	tokens: Tokens,
	size: AvatarSize,
	presence: UserPresence,
	backplateStyle: Types.ColorStyle?,
	isIconSize: boolean
): AvatarVariantProps
	local props = VariantsContext.useVariants("Avatar", variantsFactory, tokens)

	local hasIndicator = not isIconSize and (presence == UserPresence.Active or presence == UserPresence.Away)
	local strokeColor: Types.ColorStyle? = if not isIconSize and presence == UserPresence.InExperience
		then tokens.Color.System.Emphasis :: Types.ColorStyleValue
		else backplateStyle
	local strokeThickness = if isIconSize then props.iconSizeStrokes[size] else props.sizeStrokes[size]

	return composeStyleVariant(props.common, props.sizes[size], props.presence[presence], {
		container = {
			stroke = if strokeColor
				then {
					Color = Value.index(strokeColor, "Color3"),
					Transparency = Value.index(strokeColor, "Transparency"),
					Thickness = strokeThickness,
				}
				else nil,
			backgroundStyle = backplateStyle,
		},
		statusIndicator = {
			isVisible = hasIndicator,
		},
	}) :: any
end
