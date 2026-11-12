local BadgeVariant = require("../../Enums/BadgeVariant")
type BadgeVariant = BadgeVariant.BadgeVariant
local BadgeShape = require("../../Enums/BadgeShape")
type BadgeShape = BadgeShape.BadgeShape

local Types = require("../Types")
type ColorStyleValue = Types.ColorStyleValue
type ColorToken = { Color3: Color3, Transparency: number }

local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local VariantsContext = require("../../Providers/Style/VariantsContext")

export type BadgeVariantProps = {
	container: { tag: string, backgroundStyle: ColorStyleValue, stroke: Types.Stroke? },
	text: { tag: string },
	content: { style: ColorStyleValue },
}

local function variantsFactory(tokens: Tokens)
	local common: VariantProps = {
		container = { tag = "row align-x-center align-y-center gap-xsmall" },
		text = { tag = "auto-xy text-label-small text-align-x-left text-truncate-split" },
	}

	local function variant(background: ColorToken, content: ColorToken): VariantProps
		return {
			container = { backgroundStyle = background },
			content = { style = content },
		}
	end

	local overMedia = variant(tokens.LightMode.Surface.Surface_100, tokens.LightMode.Content.Emphasis)
	overMedia.container.stroke = {
		Color = tokens.LightMode.Stroke.Default.Color3,
		Transparency = tokens.LightMode.Stroke.Default.Transparency,
	}

	local variants: { [BadgeVariant]: VariantProps } = {
		[BadgeVariant.Alert] = variant(tokens.Color.System.Alert, tokens.DarkMode.Content.Emphasis),
		[BadgeVariant.Success] = variant(tokens.Color.System.Success, tokens.LightMode.Content.Emphasis),
		[BadgeVariant.Warning] = variant(tokens.Color.System.Warning, tokens.LightMode.Content.Emphasis),
		[BadgeVariant.Contrast] = variant(tokens.Color.System.Contrast, tokens.Inverse.Content.Emphasis),
		[BadgeVariant.Standard] = variant(
			tokens.Color.ActionStandard.Background,
			tokens.Color.ActionStandard.Foreground
		),
		[BadgeVariant.Neutral] = variant(tokens.Color.Shift.Shift_300, tokens.Color.Content.Emphasis),
		[BadgeVariant.OverMedia] = overMedia,
		[BadgeVariant.OverMediaWhite] = overMedia,
		[BadgeVariant.Emphasis] = variant(tokens.Color.System.Emphasis, tokens.DarkMode.Content.Emphasis),
	}

	local iconOnly: { [boolean]: VariantProps } = {
		[true] = { container = { tag = "size-600" } },
		[false] = { container = { tag = "size-0-600 auto-x padding-x-small" } },
	}

	local shapes: { [BadgeShape]: VariantProps } = {
		[BadgeShape.Pill] = { container = { tag = "radius-circle" } },
		[BadgeShape.Box] = { container = { tag = "radius-small" } },
	}

	return {
		common = common,
		variants = variants,
		shapes = shapes,
		iconOnly = iconOnly,
	}
end

return function(tokens: Tokens, variant: BadgeVariant, shape: BadgeShape, isIconOnly: boolean): BadgeVariantProps
	local props = VariantsContext.useVariants("Badge", variantsFactory, tokens)
	return composeStyleVariant(
			props.common,
			props.variants[variant],
			props.shapes[shape],
			props.iconOnly[isIconOnly]
		) :: any
end
