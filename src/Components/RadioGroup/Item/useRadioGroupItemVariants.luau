local InternalInput = require("../../InternalInput")
type InputVariantProps = InternalInput.InputVariantProps

local InputSize = require("../../../Enums/InputSize")
type InputSize = InputSize.InputSize

local composeStyleVariant = require("../../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Tokens = require("../../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local Types = require("../../Types")
type ColorStyleValue = Types.ColorStyleValue

local VariantsContext = require("../../../Providers/Style/VariantsContext")

type RadioItemVariantProps = {
	input: InputVariantProps,
	checkmark: { tag: string, style: ColorStyleValue },
}

local function variantsFactory(tokens: Tokens)
	local common = {
		input = { tag = "radius-circle", cursorRadius = UDim.new(0, tokens.Radius.Circle) },
		checkmark = {
			tag = "position-center-center anchor-center-center radius-circle",
			style = tokens.Inverse.Content.Emphasis,
		},
	}

	local sizes: { [InputSize]: VariantProps } = {
		[InputSize.XSmall] = {
			input = { size = UDim2.fromOffset(tokens.Size.Size_400, tokens.Size.Size_400) },
			checkmark = { tag = "size-150" },
		},
		[InputSize.Small] = {
			input = { size = UDim2.fromOffset(tokens.Size.Size_500, tokens.Size.Size_500) },
			checkmark = { tag = "size-200" },
		},
		[InputSize.Medium] = {
			input = { size = UDim2.fromOffset(tokens.Size.Size_600, tokens.Size.Size_600) },
			checkmark = { tag = "size-250" },
		},
		[InputSize.Large] = {
			input = { size = UDim2.fromOffset(tokens.Size.Size_600, tokens.Size.Size_600) },
			checkmark = { tag = "size-250" },
		},
	}

	return { common = common, sizes = sizes }
end

return function(tokens: Tokens, size: InputSize): RadioItemVariantProps
	local props = VariantsContext.useVariants("RadioItem", variantsFactory, tokens)
	return (composeStyleVariant :: any)(props.common, props.sizes[size])
end
