local Dash = require("../../Utility/Dash")

local Types = require("../Types")
type ColorStyle = Types.ColorStyle
type ColorStyleValue = Types.ColorStyleValue
type FontStyle = Types.FontStyle
type Tags = Types.Tags

local InputSize = require("../../Enums/InputSize")
type InputSize = InputSize.InputSize

local InputVariant = require("../../Enums/InputVariant")
type InputVariant = InputVariant.InputVariant

local IconSize = require("../../Enums/IconSize")
type IconSize = IconSize.IconSize

local Radius = require("../../Enums/Radius")
type Radius = Radius.Radius

local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

type InputVariantProps = {
	container: {
		bgStyle: ColorStyleValue?,
		strokeStyle: ColorStyleValue?,
		strokeThickness: number?,
		tag: string?,
	},
}

local function getInputVariantsFactory(tokens: Tokens)
	local common: InputVariantProps = {
		container = {
			strokeStyle = tokens.Color.Stroke.Emphasis :: ColorStyleValue,
			strokeThickness = tokens.Stroke.Standard,
		},
	}

	local sizes: { [InputSize]: VariantProps } = {
		[InputSize.XSmall] = { container = { tag = "size-full-600" } },
		[InputSize.Small] = { container = { tag = "size-full-800" } },
		[InputSize.Medium] = { container = { tag = "size-full-1000" } },
		[InputSize.Large] = { container = { tag = "size-full-1200" } },
	}

	local variants: { [InputVariant]: VariantProps } = {
		[InputVariant.Standard] = {},
		[InputVariant.Contrast] = {
			container = {
				bgStyle = tokens.Color.Shift.Shift_200,
				strokeStyle = Dash.None,
			},
		},
		[InputVariant.Utility] = {
			container = {
				bgStyle = Dash.None,
				strokeStyle = Dash.None,
			},
		},
	}

	local errorState: { [boolean]: VariantProps } = {
		[true] = { container = { strokeStyle = tokens.Color.System.Alert } },
		[false] = {},
	}

	local focusedState: { [boolean]: VariantProps } = {
		[true] = {
			container = {
				strokeStyle = tokens.Color.System.Emphasis,
				strokeThickness = tokens.Stroke.Standard * 2,
			},
		},
		[false] = {},
	}

	local hoverState: { [boolean]: VariantProps } = {
		[true] = { container = { strokeThickness = tokens.Stroke.Standard * 2 } },
		[false] = {},
	}

	local defaultRadius: { [InputSize]: VariantProps } = {
		[InputSize.XSmall] = { container = { tag = { ["radius-small"] = true } } },
		[InputSize.Small] = { container = { tag = { ["radius-medium"] = true } } },
		[InputSize.Medium] = { container = { tag = { ["radius-medium"] = true } } },
		[InputSize.Large] = { container = { tag = { ["radius-medium"] = true } } },
	}
	local radius: { [Radius]: VariantProps } = {
		[Radius.None] = { container = { tag = { ["radius-none"] = true } } },
		[Radius.XSmall] = { container = { tag = { ["radius-xsmall"] = true } } },
		[Radius.Small] = { container = { tag = { ["radius-small"] = true } } },
		[Radius.Medium] = { container = { tag = { ["radius-medium"] = true } } },
		[Radius.Large] = { container = { tag = { ["radius-large"] = true } } },
		--* No Circle: a multi-line input is circular at its single-line height, which the component computes.
	}

	return {
		common = common,
		sizes = sizes,
		variants = variants,
		defaultRadius = defaultRadius,
		radius = radius,
		errorState = errorState,
		focusedState = focusedState,
		hoverState = hoverState,
	}
end

return getInputVariantsFactory
