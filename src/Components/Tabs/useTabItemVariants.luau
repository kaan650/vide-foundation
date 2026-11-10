local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local VariantsContext = require("../../Providers/Style/VariantsContext")

local InputSize = require("../../Enums/InputSize")
type InputSize = InputSize.InputSize

local IconSize = require("../../Enums/IconSize")
type IconSize = IconSize.IconSize

type TabVariantProps = {
	container: {
		tag: string,
	},
	text: {
		tag: string,
	},
	content: {
		tag: string,
		Size: UDim2?,
	},
	icon: {
		size: IconSize,
	},
}

local function variantsFactory(_tokens: Tokens)
	local common: VariantProps = {
		text = { tag = "auto-x" },
		content = { tag = "row align-x-center align-y-center gap-small" },
	}

	local sizes: { [InputSize]: VariantProps } = {
		[InputSize.XSmall] = {
			text = { tag = "size-0-400 text-label-small" },
			content = { tag = "padding-y-small" },
			icon = { size = IconSize.XSmall },
		},
		[InputSize.Small] = {
			text = { tag = "size-0-600 text-label-medium" },
			content = { tag = "padding-y-small" },
			icon = { size = IconSize.Medium },
		},
		[InputSize.Medium] = {
			text = { tag = "size-0-600 text-label-medium" },
			content = { tag = "padding-y-medium" },
			icon = { size = IconSize.Medium },
		},
		[InputSize.Large] = {
			text = { tag = "size-0-600 text-label-medium" },
			content = { tag = "padding-y-xlarge" },
			icon = { size = IconSize.Medium },
		},
	}

	local paddings: { [InputSize]: VariantProps } = {
		[InputSize.XSmall] = { content = { tag = "padding-x-xsmall" } },
		[InputSize.Small] = { content = { tag = "padding-x-small" } },
		[InputSize.Medium] = { content = { tag = "padding-x-medium" } },
		[InputSize.Large] = { content = { tag = "padding-x-large" } },
	}

	local isFill: { [boolean]: VariantProps } = {
		[false] = { container = { tag = "auto-xy" }, content = { tag = "size-0-0 auto-xy" } },
		[true] = {
			container = { tag = "grow auto-xy" },
			content = { tag = "auto-y", Size = UDim2.fromScale(1, 0) },
		},
	}

	return { common = common, sizes = sizes, isFill = isFill, paddings = paddings }
end

return function(tokens: Tokens, size: InputSize, isFill: boolean): TabVariantProps
	local props = VariantsContext.useVariants("Tab", variantsFactory, tokens)

	return composeStyleVariant(props.common, props.sizes[size], props.isFill[isFill], props.paddings[size])
end
