local InputSize = require("../../Enums/InputSize")
type InputSize = InputSize.InputSize

local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Types = require("../Types")
type ColorStyleValue = Types.ColorStyleValue

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local VariantsContext = require("../../Providers/Style/VariantsContext")
local getKnobSize = require("./getKnobSize")

local IconSize = require("../../Enums/IconSize")
type IconSize = IconSize.IconSize

type KnobVariantProps = {
	knob: {
		tag: string,
		size: UDim2,
		style: ColorStyleValue,
		iconSize: IconSize,
	},
	iconContainer: {
		backgroundStyle: ColorStyleValue,
	},
}

local function computeProps(props: {
	size: UDim2,
	iconSize: IconSize,
}): VariantProps
	return {
		knob = {
			size = props.size,
			iconSize = props.iconSize,
		},
	}
end

local function variantsFactory(tokens: Tokens)
	local common: VariantProps = {
		knob = {
			tag = "align-x-center align-y-center position-center-center anchor-center-center auto-xy radius-circle",
		},
	}

	local sizes: { [InputSize]: VariantProps } = {
		[InputSize.XSmall] = computeProps({
			iconSize = IconSize.XSmall,
			size = getKnobSize(tokens, InputSize.XSmall),
		}),
		[InputSize.Small] = computeProps({
			iconSize = IconSize.Small,
			size = getKnobSize(tokens, InputSize.Small),
		}),
		[InputSize.Medium] = computeProps({
			iconSize = IconSize.Small,
			size = getKnobSize(tokens, InputSize.Medium),
		}),
		[InputSize.Large] = computeProps({
			iconSize = IconSize.Small,
			size = getKnobSize(tokens, InputSize.Large),
		}),
	}

	local isInverse: { [boolean]: VariantProps } = {
		[false] = {
			knob = {
				style = tokens.Color.Content.Emphasis,
			},
			iconContainer = {
				backgroundStyle = tokens.Inverse.Content.Emphasis,
			},
		},
		[true] = {
			knob = {
				style = tokens.Inverse.Content.Emphasis,
			},
			iconContainer = {
				backgroundStyle = tokens.Color.Content.Emphasis,
			},
		},
	}

	return { common = common, sizes = sizes, isInverse = isInverse }
end

return function(tokens: Tokens, size: InputSize, isInverse: boolean): KnobVariantProps
	local props = VariantsContext.useVariants("Knob", variantsFactory, tokens)
	return composeStyleVariant(props.common, props.sizes[size], props.isInverse[isInverse])
end
