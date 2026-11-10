local Dash = require("../../Utility/Dash")

local ColorNamespace = require("../../Enums/ColorNamespace")
type ColorNamespace = ColorNamespace.ColorNamespace

local InputSize = require("../../Enums/InputSize")
type InputSize = InputSize.InputSize

local Types = require("../Types")
type ColorStyleValue = Types.ColorStyleValue
type StateLayer = Types.StateLayer

local IconSize = require("../../Enums/IconSize")
type IconSize = IconSize.IconSize

local VariantsContext = require("../../Providers/Style/VariantsContext")
local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local CloseAffordanceVariant = require("../../Enums/CloseAffordanceVariant")
type CloseAffordanceVariant = CloseAffordanceVariant.CloseAffordanceVariant

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local Constants = require("../../Constants")
local getSharedVariants = require("../Button/getSharedVariants")

type CloseAffordanceVariantProps = {
	container: {
		tag: string,
		size: UDim2?,
		radius: number,
		padding: UDim?,
		stateLayer: StateLayer?,
	},
	content: {
		style: ColorStyleValue,
		iconSize: IconSize,
	},
}

local variantsMap = function(tokens: Tokens)
	local common = {
		container = {
			tag = "row align-x-center align-y-center auto-xy clip",
		},
	}

	local sharedVariants = getSharedVariants(tokens)

	local sizes: { [boolean]: { [InputSize]: VariantProps } } = {
		[true] = {
			[InputSize.XSmall] = {
				container = {
					size = UDim2.fromOffset(
						sharedVariants.sizes[InputSize.XSmall].container.height,
						sharedVariants.sizes[InputSize.XSmall].container.height
					),
					padding = UDim.new(0, tokens.Size.Size_100),
				},
				content = {
					iconSize = IconSize.Small,
				},
			},
			[InputSize.Small] = {
				container = {
					size = UDim2.fromOffset(
						sharedVariants.sizes[InputSize.Small].container.height,
						sharedVariants.sizes[InputSize.Small].container.height
					),
					padding = UDim.new(0, tokens.Size.Size_150),
				},
				content = {
					iconSize = IconSize.Medium,
				},
			},
			[InputSize.Medium] = {
				container = {
					size = UDim2.fromOffset(
						sharedVariants.sizes[InputSize.Medium].container.height,
						sharedVariants.sizes[InputSize.Medium].container.height
					),
					padding = UDim.new(0, tokens.Size.Size_200),
				},
				content = {
					iconSize = IconSize.Large,
				},
			},
		},
		[false] = {
			[InputSize.XSmall] = { content = { iconSize = IconSize.XSmall } },
			[InputSize.Small] = { content = { iconSize = IconSize.Small } },
			[InputSize.Medium] = { content = { iconSize = IconSize.Large } },
		},
	}

	local types: { [CloseAffordanceVariant]: { [ColorNamespace]: VariantProps } } = {
		[CloseAffordanceVariant.OverMedia] = Dash.map(ColorNamespace :: any, function()
			return {
				container = { tag = "bg-over-media-100" },
				content = { style = tokens.Color.Content.Emphasis },
			}
		end),
		[CloseAffordanceVariant.Utility] = Dash.map(ColorNamespace :: any, function(colorNamespace: ColorNamespace)
			return {
				container = {
					stateLayer = {
						mode = Constants.COLOR_NAMESPACE_TO_STATE_LAYER_MODE[false][colorNamespace],
					},
				},
				content = { style = (tokens :: any)[colorNamespace].Content.Emphasis },
			}
		end),
	}

	local padding: { [boolean]: VariantProps } = {
		[true] = { container = { radius = tokens.Radius.Medium } },
		[false] = { container = { radius = 0 } },
	}

	local circular: { [boolean]: VariantProps } = {
		[true] = { container = { radius = tokens.Radius.Circle } },
		[false] = {},
	}

	return {
		common = common,
		types = types,
		sizes = sizes,
		padding = padding,
		circular = circular,
	}
end

return function(
	tokens: Tokens,
	size: InputSize,
	variant: CloseAffordanceVariant,
	colorNamespace: ColorNamespace?,
	hasPadding: boolean,
	isCircular: boolean
): CloseAffordanceVariantProps
	local variants = VariantsContext.useVariants("CloseAffordance", variantsMap, tokens)
	local isShapeCircular = variant == CloseAffordanceVariant.OverMedia or isCircular

	return (composeStyleVariant :: any)(
		variants.common,
		variants.types[variant][colorNamespace or ColorNamespace.Color],
		variants.sizes[hasPadding][size],
		variants.padding[hasPadding],
		variants.circular[isShapeCircular]
	)
end
