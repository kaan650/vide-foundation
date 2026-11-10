local IconSize = require("../../Enums/IconSize")
local InputSize = require("../../Enums/InputSize")
local VariantsContext = require("../../Providers/Style/VariantsContext")
local composeStyleVariant = require("../../Utility/composeStyleVariant")

type IconSize = IconSize.IconSize
type InputSize = InputSize.InputSize
type VariantProps = composeStyleVariant.VariantProps

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

export type NumberInputVariantProps = {
	controls: {
		tag: string,
		width: number,
		buttonSize: number,
		iconSize: IconSize,
		radius: number,
	},
}

local function variantsFactory(tokens: Tokens)
	local common: VariantProps = { controls = { tag = "row align-y-center bg-action-standard" } }

	local sizes: { [InputSize]: VariantProps } = {
		[InputSize.XSmall] = {
			controls = {
				width = tokens.Size.Size_1200,
				buttonSize = tokens.Size.Size_600,
				iconSize = IconSize.XSmall,
				tag = "radius-small",
				radius = tokens.Radius.Small,
			},
		},
		[InputSize.Small] = {
			controls = {
				width = tokens.Size.Size_1600,
				buttonSize = tokens.Size.Size_800,
				iconSize = IconSize.Small,
				tag = "radius-medium",
				radius = tokens.Radius.Medium,
			},
		},
		[InputSize.Medium] = {
			controls = {
				width = tokens.Size.Size_2000,
				buttonSize = tokens.Size.Size_1000,
				iconSize = IconSize.Medium,
				tag = "radius-medium",
				radius = tokens.Radius.Medium,
			},
		},
		[InputSize.Large] = {
			controls = {
				width = tokens.Size.Size_2400,
				buttonSize = tokens.Size.Size_1200,
				iconSize = IconSize.Large,
				tag = "radius-medium",
				radius = tokens.Radius.Medium,
			},
		},
	}

	return {
		common = common,
		sizes = sizes,
	}
end

--- The variant props of NumberInput's increment and decrement controls.
local function useNumberInputVariants(tokens: Tokens, size: InputSize): NumberInputVariantProps
	local props = VariantsContext.useVariants("NumberInput", variantsFactory, tokens)
	return (composeStyleVariant :: any)(props.common, props.sizes[size])
end

return useNumberInputVariants
