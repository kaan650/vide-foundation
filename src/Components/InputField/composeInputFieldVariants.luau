
local InputSize = require("../../Enums/InputSize")
type InputSize = InputSize.InputSize

local InputVariant = require("../../Enums/InputVariant")
type InputVariant = InputVariant.InputVariant

local Radius = require("../../Enums/Radius")
type Radius = Radius.Radius

local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local getInputVariantsFactory = require("./getInputVariantsFactory")

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

--- The input variant layers composed in the order TextInput and related inputs use.
local function composeInputFieldVariants(
	tokens: Tokens,
	size: InputSize,
	variant: InputVariant?,
	radius: Radius?,
	focused: boolean?,
	hover: boolean?,
	hasError: boolean?
): VariantProps
	local props = getInputVariantsFactory(tokens)
	local variantAttributes = props.variants[variant or InputVariant.Standard]

	return (composeStyleVariant :: any)(
		props.common,
		props.sizes[size],
		if variant ~= InputVariant.Utility then variantAttributes else {},
		if radius then props.radius[radius] else props.defaultRadius[size],
		if hover ~= nil then props.hoverState[hover] else {},
		if focused ~= nil then props.focusedState[focused] else {},
		if hasError ~= nil then props.errorState[hasError] else {},
		if variant == InputVariant.Utility then variantAttributes else {}
	)
end

return composeInputFieldVariants
