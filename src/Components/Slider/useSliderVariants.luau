local InputSize = require("../../Enums/InputSize")
type InputSize = InputSize.InputSize

local SliderVariant = require("../../Enums/SliderVariant")
type SliderVariant = SliderVariant.SliderVariant

local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local VariantsContext = require("../../Providers/Style/VariantsContext")

local Types = require("../Types")
type ColorStyleValue = Types.ColorStyleValue

type SliderVariantProps = {
	bar: {
		tag: string,
		height: number,
	},
	fill: {
		tag: string,
	},
	knob: {
		style: ColorStyleValue,
		dragStyle: ColorStyleValue,
		stroke: Types.Stroke?,
		hasShadow: boolean?,
	},
}

local function variantsFactory(tokens: Tokens)
	local common: VariantProps = {
		bar = {
			tag = "position-center-center anchor-center-center radius-circle",
		},
		fill = {
			tag = "radius-circle",
		},
	}

	local variants: { [SliderVariant]: VariantProps } = {
		[SliderVariant.Emphasis] = {
			bar = {
				tag = "bg-shift-200",
			},
			fill = {
				tag = "bg-emphasis",
			},
			knob = {
				style = tokens.Color.Extended.White.White_100,
				dragStyle = tokens.Color.System.Emphasis,
				hasShadow = true,
			},
		},
		[SliderVariant.Standard] = {
			bar = {
				tag = "bg-shift-200",
			},
			fill = {
				tag = "bg-system-contrast",
			},
			knob = {
				style = tokens.Color.System.Contrast,
				dragStyle = tokens.Color.System.Contrast,
				stroke = {
					Color = tokens.Color.Stroke.Default.Color3,
					Transparency = tokens.Color.Stroke.Default.Transparency,
					Thickness = tokens.Stroke.Standard,
				},
				hasShadow = true,
			},
		},
		[SliderVariant.Utility] = {
			knob = {
				style = tokens.Color.None,
				dragStyle = tokens.Color.None,
				stroke = {
					Color = tokens.Color.System.Contrast.Color3,
					Transparency = tokens.Color.System.Contrast.Transparency,
					Thickness = tokens.Stroke.Thicker,
				},
				hasShadow = true,
			},
		},
	}

	local sizes: { [InputSize]: VariantProps } = {
		[InputSize.XSmall] = {
			bar = { height = tokens.Size.Size_100 },
		},
		[InputSize.Small] = {
			bar = { height = tokens.Size.Size_150 },
		},
		[InputSize.Medium] = {
			bar = { height = tokens.Size.Size_200 },
		},
		[InputSize.Large] = {
			bar = { height = tokens.Size.Size_250 },
		},
	}

	return { common = common, variants = variants, sizes = sizes }
end

return function(tokens: Tokens, size: InputSize, variant: SliderVariant): SliderVariantProps
	local props = VariantsContext.useVariants("Slider", variantsFactory, tokens)
	return composeStyleVariant(props.common, props.variants[variant], props.sizes[size])
end
