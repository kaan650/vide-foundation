local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local VariantsContext = require("../../Providers/Style/VariantsContext")

local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local AvatarIconSize = require("../../Enums/AvatarIconSize")
type AvatarIconSize = AvatarIconSize.AvatarIconSize

local Types = require("../Types")
local Value = require("../../Utility/Value")

export type AvatarIconVariantProps = {
	container: { tag: string, size: number, stroke: Types.Stroke? },
	avatar: { tag: string },
}

local function composeStroke(style: Types.ColorStyle?, thickness: number?): VariantProps
	if not style or not thickness then
		return {}
	end

	return {
		container = {
			stroke = {
				Color = Value.index(style, "Color3"),
				Transparency = Value.index(style, "Transparency"),
				Thickness = thickness,
			},
		},
	}
end

local function variantsFactory(tokens: Tokens)
	local common: VariantProps = {
		container = { tag = "radius-circle" },
		avatar = { tag = "size-full radius-circle" },
	}

	local backplateStrokes: { [boolean]: { [AvatarIconSize]: number } } = {
		[true] = {
			[AvatarIconSize.XSmall] = tokens.Stroke.Standard,
			[AvatarIconSize.Small] = tokens.Stroke.Standard,
			[AvatarIconSize.Medium] = tokens.Stroke.Thick,
			[AvatarIconSize.Large] = tokens.Stroke.Thicker,
			[AvatarIconSize.XLarge] = tokens.Stroke.Thicker,
		},
		[false] = {},
	}

	local sizes: { [AvatarIconSize]: VariantProps } = {
		[AvatarIconSize.XSmall] = { container = { size = tokens.Size.Size_300 } },
		[AvatarIconSize.Small] = { container = { size = tokens.Size.Size_400 } },
		[AvatarIconSize.Medium] = { container = { size = tokens.Size.Size_500 } },
		[AvatarIconSize.Large] = { container = { size = tokens.Size.Size_600 } },
		[AvatarIconSize.XLarge] = { container = { size = tokens.Size.Size_700 } },
	}

	return {
		strokes = backplateStrokes,
		common = common,
		sizes = sizes,
	}
end

return function(tokens: Tokens, size: AvatarIconSize, backplateStyle: Types.ColorStyle?): AvatarIconVariantProps
	local props = VariantsContext.useVariants("AvatarIcon", variantsFactory, tokens)

	return composeStyleVariant(
		props.common,
		props.sizes[size],
		composeStroke(backplateStyle, props.strokes[backplateStyle ~= nil][size])
	) :: any
end
