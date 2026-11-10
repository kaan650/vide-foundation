
local InputLabelSize = require("../../Enums/InputLabelSize")
type InputLabelSize = InputLabelSize.InputLabelSize

local OptionSelectorGroupSize = require("../../Enums/OptionSelectorGroupSize")
type OptionSelectorGroupSize = OptionSelectorGroupSize.OptionSelectorGroupSize

local Orientation = require("../../Enums/Orientation")
type Orientation = Orientation.Orientation

local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local Types = require("../Types")
type Tags = Types.Tags

local VariantsContext = require("../../Providers/Style/VariantsContext")

type OptionSelectorGroupVariantProps = {
	container: { tag: string },
	list: { tag: Tags },
	legend: { size: InputLabelSize },
}

local function variantsFactory(_tokens: Tokens)
	local common = {
		container = {
			tag = "col gap-small size-full-0 auto-y",
		},
		list = {
			tag = "gap-medium size-full-0 auto-y",
		},
	}

	local sizes: { [OptionSelectorGroupSize]: VariantProps } = {
		[OptionSelectorGroupSize.XSmall] = {
			legend = { size = InputLabelSize.Small },
		},
		[OptionSelectorGroupSize.Small] = {
			legend = { size = InputLabelSize.Small },
		},
		[OptionSelectorGroupSize.Medium] = {
			legend = { size = InputLabelSize.Medium },
		},
	}

	local orientations: { [Orientation]: VariantProps } = {
		[Orientation.Vertical] = {
			list = {
				tag = {
					["col"] = true,
				},
			},
		},
		[Orientation.Horizontal] = {
			list = {
				tag = {
					["row"] = true,
				},
			},
		},
	}

	return {
		common = common,
		sizes = sizes,
		orientations = orientations,
	}
end

return function(
	tokens: Tokens,
	size: OptionSelectorGroupSize,
	orientation: Orientation
): OptionSelectorGroupVariantProps
	local props = VariantsContext.useVariants("OptionSelectorGroup", variantsFactory, tokens)
	return (composeStyleVariant :: any)(props.common, props.sizes[size], props.orientations[orientation])
end
