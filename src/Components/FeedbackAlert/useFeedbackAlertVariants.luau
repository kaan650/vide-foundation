local Types = require("../Types")
type ColorToken = { Color3: Color3, Transparency: number }
type ColorStyleValue = Types.ColorStyleValue
type Stroke = Types.Stroke

local AlertSeverity = require("../../Enums/AlertSeverity")
type AlertSeverity = AlertSeverity.AlertSeverity

local composeStyleVariant = require("../../Utility/composeStyleVariant")
type VariantProps = composeStyleVariant.VariantProps

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local VariantsContext = require("../../Providers/Style/VariantsContext")

type FeedbackAlertVariantProps = {
	container: { tag: string },
	headerRow: { tag: string },
	icon: { style: ColorStyleValue },
	title: { tag: string },
	subtitle: { tag: string },
	description: { tag: string },
	link: { tag: string },
	stroke: Stroke,
	backgroundStyle: ColorStyleValue,
}

--* 5% opacity.
local BACKGROUND_TRANSPARENCY = 0.95

local function createSeverityStyles(severityStyle: ColorToken): VariantProps
	return {
		icon = { style = severityStyle },
		stroke = {
			Color = severityStyle.Color3,
			Transparency = severityStyle.Transparency,
			Thickness = 1,
		},
		backgroundStyle = {
			Color3 = severityStyle.Color3,
			Transparency = BACKGROUND_TRANSPARENCY,
		},
	}
end

local function variantsFactory(tokens: Tokens)
	local common = {
		container = {
			tag = "col align-x-left align-y-center gap-medium size-full-0 auto-y padding-large radius-medium",
		},
		headerRow = {
			tag = "row align-y-center gap-medium size-full-0 auto-y",
		},
		title = {
			tag = "shrink auto-xy text-title-medium text-truncate-split content-emphasis",
		},
		subtitle = {
			tag = "shrink auto-xy text-body-medium text-truncate-split content-default",
		},
		description = {
			tag = "size-full-0 auto-y text-body-medium text-wrap text-align-x-left text-truncate-split content-default",
		},
		link = {
			tag = "shrink auto-xy text-body-medium text-truncate-split content-emphasis",
		},
	}

	local severity: { [AlertSeverity]: VariantProps } = {
		[AlertSeverity.Info] = createSeverityStyles(tokens.Color.System.Emphasis),
		[AlertSeverity.Warning] = createSeverityStyles(tokens.Color.System.Warning),
		[AlertSeverity.Success] = createSeverityStyles(tokens.Color.System.Success),
		[AlertSeverity.Error] = createSeverityStyles(tokens.Color.System.Alert),
	}

	return { common = common, severity = severity }
end

return function(tokens: Tokens, severity: AlertSeverity): FeedbackAlertVariantProps
	local props = VariantsContext.useVariants("FeedbackAlert", variantsFactory, tokens)
	return (composeStyleVariant :: any)(props.common, props.severity[severity])
end
