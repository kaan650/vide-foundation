
local InputSize = require("../../Enums/InputSize")
type InputSize = InputSize.InputSize

local VariantsContext = require("../../Providers/Style/VariantsContext")
local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Tokens = require("../../Providers/Style/Tokens")
local Types = require("../Types")
type Tokens = Tokens.Tokens
type StateLayer = Types.StateLayer
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")

local IconSize = require("../../Enums/IconSize")
type IconSize = IconSize.IconSize

type AccordionItemVariantProps = {
	container: { tag: string, stateLayer: StateLayer },
	header: { tag: string },
	content: { tag: string },
	icon: { style: Types.ColorStyleValue, size: number },
	text: { tag: string },
}

local getVariants = function(tokens: Tokens)
	local common: VariantProps = {
		container = {
			tag = "col flex-y-between align-x-center size-full-0 auto-y",
			stateLayer = { affordance = StateLayerAffordance.None },
		},
		header = { tag = "row flex-x-between align-y-center" },
		content = { tag = "size-full-0 auto-y padding-top-xsmall" },
		icon = { style = tokens.Color.Content.Emphasis },
		text = { tag = "grow auto-y text-align-x-left text-truncate-end content-emphasis" },
	}

	local sizes: { [InputSize]: VariantProps } = {
		[InputSize.XSmall] = {
			container = { tag = "radius-small" },
			header = { tag = "gap-small size-full-600" },
			content = { tag = "padding-bottom-small" },
			icon = { size = IconSize.XSmall :: IconSize },
			text = { tag = "text-title-small" },
		},
		[InputSize.Small] = {
			container = { tag = "radius-medium" },
			header = { tag = "gap-small size-full-800" },
			content = { tag = "padding-bottom-large" },
			icon = { size = IconSize.Small :: IconSize },
			text = { tag = "text-title-small" },
		},
		[InputSize.Medium] = {
			container = { tag = "radius-medium" },
			header = { tag = "gap-small size-full-1000" },
			content = { tag = "padding-bottom-xlarge" },
			icon = { size = IconSize.Medium :: IconSize },
			text = { tag = "text-title-medium" },
		},
		[InputSize.Large] = {
			container = { tag = "radius-medium" },
			header = { tag = "gap-small size-full-1200" },
			content = { tag = "padding-bottom-xlarge" },
			icon = { size = IconSize.Large :: IconSize },
			text = { tag = "text-title-large" },
		},
	}

	local isContained: { [boolean]: VariantProps } = {
		[false] = { header = { tag = "padding-x-xsmall" } },
		[true] = { header = { tag = "padding-x-medium" } },
	}

	return { common = common, sizes = sizes, isContained = isContained }
end

return function(tokens: Tokens, size: InputSize, isContained: boolean): AccordionItemVariantProps
	local variants = VariantsContext.useVariants("AccordionItem", getVariants, tokens)
	return composeStyleVariant(variants.common, variants.sizes[size], variants.isContained[isContained])
end
