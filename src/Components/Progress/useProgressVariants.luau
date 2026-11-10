local ProgressSize = require("../../Enums/ProgressSize")
type ProgressSize = ProgressSize.ProgressSize

local Types = require("../Types")
type FontStyle = Types.FontStyle

local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local VariantsContext = require("../../Providers/Style/VariantsContext")

export type ProgressVariantProps = {
	bar: { height: number },
	circle: { size: number, labelFont: FontStyle? },
}

local function variantsFactory(tokens: Tokens)
	local sizes: { [ProgressSize]: VariantProps } = {
		[ProgressSize.Small] = {
			bar = { height = tokens.Size.Size_50 },
			circle = { size = tokens.Size.Size_400 },
		},
		[ProgressSize.Medium] = {
			bar = { height = tokens.Size.Size_100 },
			circle = { size = tokens.Size.Size_800 },
		},
		[ProgressSize.Large] = {
			bar = { height = tokens.Size.Size_150 },
			circle = {
				size = tokens.Size.Size_1300,
				labelFont = tokens.Typography.LabelMedium,
			},
		},
	}

	return { sizes = sizes }
end

return function(tokens: Tokens, size: ProgressSize): ProgressVariantProps
	local props = VariantsContext.useVariants("Progress", variantsFactory, tokens)
	return composeStyleVariant(props.sizes[size]) :: any
end
