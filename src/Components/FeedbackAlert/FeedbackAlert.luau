local Vide = require("../../Packages/Vide")

local AlertActions = require("../AlertActions")
local AlertConstants = require("../AlertActions/AlertConstants")
local AlertSeverity = require("../../Enums/AlertSeverity")
local BuilderIcons = require("../../Packages/BuilderIcons")
local CloseAffordance = require("../CloseAffordance")
local CloseAffordanceVariant = require("../../Enums/CloseAffordanceVariant")
local ControlState = require("../../Enums/ControlState")
local Icon = require("../Icon")
local IconSize = require("../../Enums/IconSize")
local InputSize = require("../../Enums/InputSize")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local escapeRichText = require("../../Utility/escapeRichText")
local named = require("../../Utility/named")
local useFeedbackAlertVariants = require("./useFeedbackAlertVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type AlertSeverity = AlertSeverity.AlertSeverity
type AlertAction = AlertConstants.AlertAction
type ControlState = ControlState.ControlState
type Value<T> = Types.Value<T>

type FeedbackAlertLink = {
	text: string,
	onActivated: () -> (),
}

export type FeedbackAlertProps = {
	severity: Value<AlertSeverity>,
	title: Value<string>,
	subtitle: Value<string?>?,
	description: Value<string?>?,
	link: Value<FeedbackAlertLink?>?,
	actions: Value<{ AlertAction }?>?,
	onClose: (() -> ())?,
} & Types.CommonProps

local defaultProps = {
	testId = "--foundation-feedback-alert",
}

--- A card with a severity icon, a title row with an optional subtitle and link, a description and action buttons.
local function FeedbackAlert(feedbackAlertProps: FeedbackAlertProps): GuiObject
	local props = withDefaults(feedbackAlertProps, defaultProps)
	local tokens = useTokens()
	local testId = props.testId

	local function severity(): AlertSeverity
		return Value.read(props.severity)
	end
	local function subtitle(): string?
		return Value.read(props.subtitle)
	end
	local function description(): string?
		return Value.read(props.description)
	end
	local function link(): FeedbackAlertLink?
		return Value.read(props.link)
	end

	local variantProps = Vide.derive(function()
		return useFeedbackAlertVariants(tokens(), severity())
	end)

	local isLinkHovered = Vide.source(false)

	local function hasLink(): boolean
		return link() ~= nil
	end

	local content = View({
		LayoutOrder = 2,
		tag = "row align-y-center fill gap-xsmall auto-y",
		testId = `{testId}--content`,
		children = {
			named(
				"Title",
				Text({
					Text = props.title,
					tag = function()
						return variantProps().title.tag
					end,
					LayoutOrder = 1,
					testId = `{testId}--title`,
				})
			),
			Vide.show(subtitle, function(current: () -> string)
				return named(
					"Subtitle",
					Text({
						Text = current,
						tag = function()
							return variantProps().subtitle.tag
						end,
						LayoutOrder = 2,
						testId = `{testId}--subtitle`,
					})
				)
			end),
			Vide.show(hasLink, function()
				return named(
					"Separator",
					Text({
						Text = "·",
						tag = "auto-xy text-body-medium content-default",
						LayoutOrder = 3,
						testId = `{testId}--separator`,
					})
				)
			end),
			Vide.show(link, function(current: () -> FeedbackAlertLink)
				return named(
					"Link",
					Text({
						Text = function()
							local text = escapeRichText(current().text)
							return if isLinkHovered() then `<u>{text}</u>` else text
						end,
						RichText = true,
						tag = function()
							return variantProps().link.tag
						end,
						LayoutOrder = 4,
						stateLayer = { affordance = StateLayerAffordance.None },
						onStateChanged = function(state: ControlState)
							isLinkHovered(state == ControlState.Hover)
						end,
						onActivated = function()
							Vide.untrack(current).onActivated()
						end,
						testId = `{testId}--link`,
					})
				)
			end),
		},
	})
	content.Name = "Content"

	local headerRow = View({
		LayoutOrder = 1,
		tag = function()
			return variantProps().headerRow.tag
		end,
		testId = `{testId}--header`,
		children = {
			named(
				"Icon",
				Icon({
					LayoutOrder = 1,
					name = function()
						return AlertConstants.SEVERITY_TO_ICON[severity()]
					end,
					size = IconSize.Large,
					variant = BuilderIcons.IconVariant.Filled,
					style = function()
						return variantProps().icon.style
					end,
					testId = `{testId}--icon`,
				})
			),
			content,
			if props.onClose
				then named(
					"Close",
					CloseAffordance({
						onActivated = props.onClose,
						size = InputSize.XSmall,
						variant = CloseAffordanceVariant.Utility,
						LayoutOrder = 3,
						testId = `{testId}--close`,
					})
				)
				else nil,
		},
	})
	headerRow.Name = "HeaderRow"

	return View(withCommonProps(props, {
		tag = function()
			return variantProps().container.tag
		end,
		stroke = function()
			return variantProps().stroke
		end,
		backgroundStyle = function()
			return variantProps().backgroundStyle
		end,
		children = {
			headerRow,
			Vide.show(description, function(current: () -> string)
				return named(
					"Description",
					Text({
						Text = current,
						tag = function()
							return variantProps().description.tag
						end,
						LayoutOrder = 2,
						testId = `{testId}--description`,
					})
				)
			end),
			named(
				"Actions",
				AlertActions({
					actions = props.actions,
					testId = `{testId}--actions`,
					LayoutOrder = 3,
				})
			),
		},
	}) :: any)
end

return FeedbackAlert
