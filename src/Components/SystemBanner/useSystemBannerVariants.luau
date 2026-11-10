local Types = require("../Types")
type ColorStyleValue = Types.ColorStyleValue
type ColorToken = { Color3: Color3, Transparency: number }

local ColorNamespace = require("../../Enums/ColorNamespace")
type ColorNamespace = ColorNamespace.ColorNamespace

local AlertVariant = require("../../Enums/AlertVariant")
type AlertVariant = AlertVariant.AlertVariant

local AlertSeverity = require("../../Enums/AlertSeverity")
type AlertSeverity = AlertSeverity.AlertSeverity

local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local VariantsContext = require("../../Providers/Style/VariantsContext")

type AlertVariantProps = {
	container: { tag: string, colorNamespace: ColorNamespace },
	icon: { style: ColorStyleValue },
	title: { style: ColorStyleValue, tag: string },
	description: { style: ColorStyleValue, tag: string },
}

local function createStandardVariantStyles(tokens: Tokens, iconStyle: ColorToken): VariantProps
	return {
		container = {
			tag = "bg-shift-200",
			colorNamespace = ColorNamespace.Color,
		},
		title = { style = tokens.Color.Content.Emphasis },
		description = { style = tokens.Color.Content.Default },
		icon = { style = iconStyle },
	}
end

local function createEmphasisVariantStyles(
	tokens: Tokens,
	containerTag: string,
	colorNamespace: ColorNamespace
): VariantProps
	return {
		container = {
			tag = containerTag,
			colorNamespace = colorNamespace,
		},
		title = { style = (tokens :: any)[colorNamespace].Content.Emphasis },
		description = { style = (tokens :: any)[colorNamespace].Content.Default },
		icon = { style = (tokens :: any)[colorNamespace].Content.Emphasis },
	}
end

local function variantsFactory(tokens: Tokens)
	local common = {
		container = {
			tag = "row gap-medium size-full-0 auto-y padding-x-medium padding-y-large",
		},
		title = {
			tag = "auto-xy padding-y-xxsmall text-title-medium text-wrap text-align-x-left",
		},
		description = {
			tag = "auto-xy text-body-medium text-wrap text-align-x-left",
		},
	}

	local severity: { [AlertVariant]: { [AlertSeverity]: VariantProps } } = {
		[AlertVariant.Standard] = {
			[AlertSeverity.Info] = createStandardVariantStyles(tokens, tokens.Color.System.Emphasis),
			[AlertSeverity.Warning] = createStandardVariantStyles(tokens, tokens.Color.System.Warning),
			[AlertSeverity.Success] = createStandardVariantStyles(tokens, tokens.Color.System.Success),
			[AlertSeverity.Error] = createStandardVariantStyles(tokens, tokens.Color.System.Alert),
		},
		[AlertVariant.Emphasis] = {
			[AlertSeverity.Info] = createEmphasisVariantStyles(tokens, "bg-system-emphasis", ColorNamespace.DarkMode),
			[AlertSeverity.Warning] = createEmphasisVariantStyles(
				tokens,
				"bg-system-warning",
				ColorNamespace.LightMode
			),
			[AlertSeverity.Success] = createEmphasisVariantStyles(
				tokens,
				"bg-system-success",
				ColorNamespace.LightMode
			),
			[AlertSeverity.Error] = createEmphasisVariantStyles(tokens, "bg-system-alert", ColorNamespace.DarkMode),
		},
	}

	return { common = common, severity = severity }
end

return function(tokens: Tokens, variant: AlertVariant, severity: AlertSeverity): AlertVariantProps
	local props = VariantsContext.useVariants("SystemBanner", variantsFactory, tokens)
	return (composeStyleVariant :: any)(props.common, props.severity[variant][severity])
end
