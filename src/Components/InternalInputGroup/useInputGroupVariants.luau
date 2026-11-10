local InputSize = require("../../Enums/InputSize")

local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local VariantsContext = require("../../Providers/Style/VariantsContext")

local Types = require("../Types")
type InputGroupSize = Types.InputGroupSize

type InputGroupVariantProps = {
	container: { tag: string },
	children: { tag: string },
	legend: { tag: string },
}

local function variantsFactory(_tokens: Tokens)
	local common = {
		container = {
			tag = "col auto-xy",
		},
		children = {
			tag = "col auto-xy",
		},
		legend = {
			tag = "auto-xy text-wrap text-align-x-left content-emphasis",
		},
	}

	local sizes: { [InputGroupSize]: VariantProps } = {
		[InputSize.XSmall] = {
			container = {
				tag = "gap-medium",
			},
			children = {
				tag = "gap-small",
			},
			legend = {
				tag = "text-title-small",
			},
		},
		[InputSize.Small] = {
			container = {
				tag = "gap-large",
			},
			children = {
				tag = "gap-medium",
			},
			legend = {
				tag = "text-title-small",
			},
		},
		[InputSize.Medium] = {
			container = {
				tag = "gap-large",
			},
			children = {
				tag = "gap-medium",
			},
			legend = {
				tag = "text-title-medium",
			},
		},
	}

	return {
		common = common,
		sizes = sizes,
	}
end

local function useInputGroupVariants(tokens: Tokens, size: InputGroupSize): InputGroupVariantProps
	local props = VariantsContext.useVariants("InputGroup", variantsFactory, tokens)
	return (composeStyleVariant :: any)(props.common, props.sizes[size])
end

return useInputGroupVariants
