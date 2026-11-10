local Dash = require("../../Utility/Dash")

local Types = require("../Types")
type ColorStyleValue = Types.ColorStyleValue

local ControlState = require("../../Enums/ControlState")
type ControlState = ControlState.ControlState

local InputSize = require("../../Enums/InputSize")
type InputSize = InputSize.InputSize

local IconSize = require("../../Enums/IconSize")
type IconSize = IconSize.IconSize

local InputVariant = require("../../Enums/InputVariant")
type InputVariant = InputVariant.InputVariant

local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local VariantsContext = require("../../Providers/Style/VariantsContext")
local getInputVariantsFactory = require("../InputField/getInputVariantsFactory")

export type DropdownVariantProps = {
	container: {
		bgStyle: ColorStyleValue?,
		strokeStyle: ColorStyleValue?,
		strokeThickness: number,
		tag: string,
	},
	text: { tag: string },
	arrow: { size: IconSize },
}

local function variantsFactory()
	local common: VariantProps = {
		container = {
			tag = "row flex-x-between align-y-center",
		},
		text = {
			tag = "shrink auto-xy text-truncate-split content-emphasis",
		},
	}

	local sizes: { [InputSize]: VariantProps } = {
		[InputSize.XSmall] = {
			container = {
				tag = "gap-small size-full-600 padding-small radius-small",
			},
			text = { tag = "text-body-small" },
			arrow = { size = IconSize.XSmall },
		},
		[InputSize.Small] = {
			container = {
				tag = "gap-small size-full-800 padding-medium radius-medium",
			},
			text = { tag = "text-body-small" },
			arrow = { size = IconSize.Small },
		},
		[InputSize.Medium] = {
			container = {
				tag = "gap-small size-full-1000 padding-medium radius-medium",
			},
			text = { tag = "text-body-medium" },
			arrow = { size = IconSize.Medium },
		},
		[InputSize.Large] = {
			container = {
				tag = "gap-small size-full-1200 padding-medium radius-medium",
			},
			text = { tag = "text-body-large" },
			arrow = { size = IconSize.Large },
		},
	}

	local states: { [ControlState]: VariantProps } = {
		[ControlState.Disabled] = {
			text = { tag = "content-muted" },
		},
		[ControlState.Initialize] = {
			text = { tag = "content-default" },
		},
	}

	--! Meant to keep a placeholder muted in every state, but it maps only the states listed above, as in Foundation:
	--! a hovered or pressed placeholder falls back to the common content-emphasis.
	local placeholderStates: { [ControlState]: VariantProps } = Dash.map(states, function(state)
		return Dash.join(state, {
			text = { tag = "content-muted" },
		})
	end)

	return {
		common = common,
		sizes = sizes,
		states = states,
		placeholderStates = placeholderStates,
	}
end

return function(
	tokens: Tokens,
	size: InputSize,
	variant: InputVariant,
	controlState: ControlState,
	isPlaceholderShown: boolean,
	hasError: boolean,
	focused: boolean,
	hover: boolean
): DropdownVariantProps
	local props = VariantsContext.useVariants("Dropdown", variantsFactory, tokens)
	local inputProps = VariantsContext.useVariants("InputField", getInputVariantsFactory, tokens)
	local variantAttributes = inputProps.variants[variant or InputVariant.Standard]

	return composeStyleVariant(
		inputProps.common :: any,
		props.common,
		inputProps.sizes[size],
		props.sizes[size],
		if variant ~= InputVariant.Utility then variantAttributes else {},
		inputProps.hoverState[hover],
		inputProps.focusedState[focused],
		inputProps.errorState[hasError],
		if isPlaceholderShown then props.placeholderStates[controlState] else props.states[controlState],
		if variant == InputVariant.Utility then variantAttributes else {}
	) :: any
end
