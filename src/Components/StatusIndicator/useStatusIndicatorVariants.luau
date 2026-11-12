local StatusIndicatorSize = require("../../Enums/StatusIndicatorSize")
type StatusIndicatorSize = StatusIndicatorSize.StatusIndicatorSize
local StatusIndicatorVariant = require("../../Enums/StatusIndicatorVariant")
type StatusIndicatorVariant = StatusIndicatorVariant.StatusIndicatorVariant
local StatusIndicatorShape = require("../../Enums/StatusIndicatorShape")
type StatusIndicatorShape = StatusIndicatorShape.StatusIndicatorShape

local Types = require("../Types")
type ColorStyleValue = Types.ColorStyleValue

local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Value = require("../../Utility/Value")
local devAssert = require("../../Utility/devAssert")

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local VariantsContext = require("../../Providers/Style/VariantsContext")

local Constants = require("../../Constants")

export type StatusIndicatorVariantProps = {
	container: { tag: string, backgroundStyle: ColorStyleValue?, size: UDim2? },
	content: {
		tag: string,
		style: ColorStyleValue?,
		font: Font,
		typography: { FontSize: number, LineHeight: number },
	},
	ring: { tag: string, size: UDim2? }?,
	stroke: Types.Stroke?,
}

--TODO Use a tag once BuilderSansSemiBold is a token.
local BuilderSansSemiBold = Font.new(Constants.BUILDER_SANS_FONT_ASSET, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)

local function variantsFactory(tokens: Tokens)
	local common: VariantProps = {
		content = {
			tag = "auto-xy text-align-x-left",
			font = BuilderSansSemiBold,
			typography = tokens.Typography.LabelSmall,
		},
		stroke = { Thickness = tokens.Stroke.Thicker },
	}

	local variants: { [StatusIndicatorVariant]: VariantProps } = {
		[StatusIndicatorVariant.Alert] = {
			container = { tag = "bg-system-alert" },
			content = { style = tokens.DarkMode.Content.Emphasis },
		},
		[StatusIndicatorVariant.Success] = {
			container = { tag = "bg-system-success" },
			content = { style = tokens.LightMode.Content.Emphasis },
		},
		[StatusIndicatorVariant.Warning] = {
			container = { tag = "bg-system-warning" },
			content = { style = tokens.LightMode.Content.Emphasis },
		},
		[StatusIndicatorVariant.Emphasis] = {
			container = { tag = "bg-system-emphasis" },
			content = { style = tokens.DarkMode.Content.Emphasis },
		},
		[StatusIndicatorVariant.Neutral] = {
			container = { tag = "bg-system-neutral" },
			content = { style = tokens.Inverse.Content.Emphasis },
		},
		[StatusIndicatorVariant.Standard] = {
			container = { tag = "bg-action-standard" },
			content = { style = tokens.Color.Content.Emphasis },
		},
		[StatusIndicatorVariant.Contrast_Experiment] = {
			container = { tag = "bg-system-contrast" },
			content = { style = tokens.Inverse.Content.Emphasis },
		},
		[StatusIndicatorVariant.Voice] = {
			--TODO Use a tag once system-voice tokens exist.
			container = { backgroundStyle = tokens.Color.Extended.Orange.Orange_600 },
		},
	}

	local hasValue: { [boolean]: VariantProps } = {
		[true] = {
			container = { tag = "row align-x-center align-y-center auto-x padding-xsmall" },
		},
	}

	local shape: { [StatusIndicatorShape]: VariantProps } = {
		[StatusIndicatorShape.Circle] = {
			container = { tag = "radius-circle" },
			stroke = { LineJoinMode = Enum.LineJoinMode.Round },
		},
		[StatusIndicatorShape.Ring] = {
			container = { tag = "align-x-center align-y-center radius-circle" },
			ring = { tag = "radius-circle bg-surface-100" },
			stroke = { LineJoinMode = Enum.LineJoinMode.Round },
		},
		[StatusIndicatorShape.Square] = {
			container = { tag = "radius-none" },
			stroke = { LineJoinMode = Enum.LineJoinMode.Miter },
		},
	}

	local function sizeVariant(size: number): VariantProps
		return {
			container = { size = UDim2.fromOffset(size, size) },
			ring = { size = UDim2.fromOffset(size / 2, size / 2) },
		}
	end
	local sizes: { [StatusIndicatorSize]: VariantProps } = {
		[StatusIndicatorSize.XSmall] = sizeVariant(tokens.Size.Size_150),
		[StatusIndicatorSize.Small] = sizeVariant(tokens.Size.Size_200),
		[StatusIndicatorSize.Medium] = sizeVariant(tokens.Size.Size_250),
		[StatusIndicatorSize.Large] = sizeVariant(tokens.Size.Size_500),
		[StatusIndicatorSize.Pictogram] = sizeVariant(tokens.Size.Size_500),
	}

	local numericDefault: VariantProps = {
		container = { size = UDim2.fromOffset(tokens.Size.Size_400, tokens.Size.Size_400) },
	}
	local numericLarge: VariantProps = {
		container = { size = UDim2.fromOffset(tokens.Size.Size_500, tokens.Size.Size_500) },
		content = { typography = tokens.Typography.LabelMedium },
	}
	local numericSizes: { [StatusIndicatorSize]: VariantProps } = {
		[StatusIndicatorSize.XSmall] = numericDefault,
		[StatusIndicatorSize.Small] = numericDefault,
		[StatusIndicatorSize.Medium] = numericDefault,
		[StatusIndicatorSize.Large] = numericLarge,
		[StatusIndicatorSize.Pictogram] = numericLarge,
	}

	return {
		common = common,
		variants = variants,
		hasValue = hasValue,
		shape = shape,
		sizes = sizes,
		numericSizes = numericSizes,
	}
end

return function(
	tokens: Tokens,
	variant: StatusIndicatorVariant,
	hasValue: boolean,
	shape: StatusIndicatorShape,
	size: StatusIndicatorSize,
	mask: Types.ColorStyle?
): StatusIndicatorVariantProps
	devAssert(
		variant ~= StatusIndicatorVariant.Contrast_Experiment,
		"Contrast is not a supported StatusIndicator variant."
	)
	devAssert(
		not (variant == StatusIndicatorVariant.Alert and hasValue),
		"Alert is not a supported numeric StatusIndicator variant."
	)

	local commonMask: VariantProps? = if mask
		then {
			stroke = {
				Color = Value.index(mask, "Color3"),
				Transparency = Value.index(mask, "Transparency"),
			},
		}
		else nil

	local props = VariantsContext.useVariants("StatusIndicator", variantsFactory, tokens)

	return composeStyleVariant(
		props.common,
		props.variants[variant],
		props.hasValue[hasValue],
		props.shape[shape],
		if hasValue then props.numericSizes[size] else props.sizes[size],
		commonMask :: VariantProps
	) :: any
end
