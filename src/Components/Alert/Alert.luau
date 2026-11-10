local Vide = require("../../Packages/Vide")

local AlertConstants = require("../AlertActions/AlertConstants")
local AlertSeverity = require("../../Enums/AlertSeverity")
local AlertVariant = require("../../Enums/AlertVariant")
local Breakpoint = require("../../Enums/Breakpoint")
local BreakpointConfig = require("../../Utility/Responsive/BreakpointConfig")
local BuilderIcons = require("../../Packages/BuilderIcons")
local ButtonGroup = require("../ButtonGroup")
local ButtonVariant = require("../../Enums/ButtonVariant")
local CloseAffordance = require("../CloseAffordance")
local CloseAffordanceVariant = require("../../Enums/CloseAffordanceVariant")
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
local useAlertVariants = require("./useAlertVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type AlertSeverity = AlertSeverity.AlertSeverity
type AlertVariant = AlertVariant.AlertVariant
type ButtonGroupItem = ButtonGroup.ButtonGroupItem
type Value<T> = Types.Value<T>

type AlertInteraction = {
	text: string,
	onActivated: () -> (),
}

type AlertActionButtons = {
	-- Required primary action (Standard variant)
	primary: AlertInteraction,
	-- Optional secondary action (Utility variant)
	secondary: AlertInteraction?,
}

export type AlertProps = {
	-- Visual treatment of the alert
	variant: Value<AlertVariant?>?,
	-- Semantic severity, which drives color and icon
	severity: Value<AlertSeverity?>?,
	-- Message shown in the alert
	text: Value<string>,
	-- The close affordance is only rendered when the alert is dismissable.
	onClose: (() -> ())?,
	-- Text link in the trailing slot. Takes the place of `actions` while set.
	link: Value<AlertInteraction?>?,
	-- Action buttons in the trailing slot
	actions: Value<AlertActionButtons?>?,
} & Types.CommonProps

local defaultProps = {
	variant = AlertVariant.Feedback,
	severity = AlertSeverity.Info,
	testId = "--foundation-alert",
}

-- Alert renders Feedback and System only; the SystemBanner values collapse onto the default.
local VARIANT_FALLBACKS: { [AlertVariant]: AlertVariant } = {
	[AlertVariant.Standard] = AlertVariant.Feedback,
	[AlertVariant.Emphasis] = AlertVariant.Feedback,
}

-- Inclusive XSmall cutoff on the alert, not the viewport.
local STACK_MAX_WIDTH = BreakpointConfig.widths[Breakpoint.XSmall]
-- Arbitrary 40% cap so the message keeps some min width.
local TRAILING_MAX_WIDTH_RATIO = 0.4

-- Any label change remeasures the trailing slot, so a shorter one can go back inline.
local function getTrailingLabels(link: AlertInteraction?, actions: AlertActionButtons?): string
	if link then
		return link.text
	end
	if actions then
		return `{actions.primary.text}|{if actions.secondary then actions.secondary.text else ""}`
	end
	return ""
end

--- `read()`, or its last non-nil value: effects inside a branch can run once after the value that built the
--- branch is gone, before the branch is destroyed.
local function lastPresent<T>(read: () -> T?): () -> T
	local last: T? = Vide.untrack(read)
	return function()
		local value = read()
		if value ~= nil then
			last = value
		end
		return last :: T
	end
end

type TrailingKind = "link" | "actions"

--- A one-line message with a severity icon, and an optional link or action buttons and close button. It measures
--- its own width and stacks the trailing slot under the message when the alert is narrow or the buttons too wide.
local function Alert(alertProps: AlertProps): GuiObject
	local props = withDefaults(alertProps, defaultProps)
	local tokens = useTokens()
	local testId = props.testId
	local onClose = props.onClose

	local function variant(): AlertVariant
		local value: AlertVariant = Value.read(props.variant)
		return VARIANT_FALLBACKS[value] or value
	end
	local function severity(): AlertSeverity
		return Value.read(props.severity)
	end
	local function link(): AlertInteraction?
		return Value.read(props.link)
	end
	local function actions(): AlertActionButtons?
		return Value.read(props.actions)
	end

	--* Stacking keys off the alert's own width, not the viewport, so it must be measured.
	local alertSize = Vide.source(Vector2.zero)
	local trailingWidth = Vide.source(0)

	local trailingLabels = Vide.derive(function()
		return getTrailingLabels(link(), actions())
	end)
	--* Nothing to reset before the first measurement; clearing it would drop the only one a never-resized alert takes.
	local measuredLabels = Vide.untrack(trailingLabels)
	Vide.effect(function()
		local labels = trailingLabels()
		if labels ~= measuredLabels then
			measuredLabels = labels
			Vide.untrack(function()
				trailingWidth(0)
			end)
		end
	end)

	local function maxTrailingWidth(): number
		return alertSize().X * TRAILING_MAX_WIDTH_RATIO
	end
	local isStacked = Vide.derive(function(): boolean
		local width = alertSize().X
		local isNarrow = width > 0 and width <= STACK_MAX_WIDTH
		local maxTrailing = maxTrailingWidth()
		return isNarrow or (actions() ~= nil and maxTrailing > 0 and trailingWidth() > maxTrailing)
	end)

	local variantProps = Vide.derive(function()
		return useAlertVariants(tokens(), severity(), variant(), isStacked())
	end)

	local function severityIcon(): GuiObject
		return Icon({
			name = function()
				return AlertConstants.SEVERITY_TO_ICON[severity()]
			end,
			size = IconSize.Medium,
			variant = BuilderIcons.IconVariant.Filled,
			style = function()
				return variantProps().icon.style :: any
			end,
			LayoutOrder = 2,
			ZIndex = 2,
			testId = `{testId}--icon`,
		})
	end

	local function icon(): GuiObject
		return named(
			"Icon",
			View({
				tag = "align-y-center size-0-800 auto-x",
				LayoutOrder = 1,
				children = Vide.show(function()
					return variantProps().iconBackplate
				end, function(backplate: () -> useAlertVariants.AlertBackplate)
					return named(
						"Content",
						View({
							Size = function()
								return variantProps().iconFrame.Size
							end,
							LayoutOrder = 1,
							children = {
								named(
									"Backplate",
									View({
										Size = function()
											return backplate().Size
										end,
										Position = function()
											return backplate().Position
										end,
										tag = function()
											return backplate().tag
										end,
										backgroundStyle = function()
											return backplate().backgroundStyle
										end,
										LayoutOrder = 1,
										ZIndex = 1,
										testId = `{testId}--icon-backplate`,
									})
								),
								named("Icon", severityIcon()),
							},
						})
					)
				end, function()
					return named("Content", severityIcon())
				end),
			})
		)
	end

	local function message(): GuiObject
		return named(
			"Message",
			Text({
				Text = props.text,
				tag = function()
					return variantProps().message.tag
				end,
				padding = {
					top = function()
						return variantProps().message.padding.top :: UDim
					end,
				},
				LayoutOrder = 2,
				testId = `{testId}--message`,
			})
		)
	end

	local trailingKind = Vide.derive(function(): TrailingKind?
		if link() then
			return "link"
		elseif actions() then
			return "actions"
		end
		return nil
	end)

	local function trailing(stacked: boolean)
		--* Measuring while stacked would feed the stacked width back into the 40% check.
		local measure = if stacked
			then nil
			else function(rbx: GuiObject)
				trailingWidth(rbx.AbsoluteSize.X)
			end

		local function linkPadding(side: "top" | "bottom"): () -> UDim
			return function()
				return (variantProps().link.padding :: any)[side]
			end
		end

		return Vide.switch(trailingKind)({
			link = function()
				local current = lastPresent(link)
				return named(
					"Trailing",
					Text({
						Text = function()
							return `<u>{escapeRichText(current().text)}</u>`
						end,
						RichText = true,
						tag = function()
							return variantProps().link.tag
						end,
						padding = if stacked
							then { top = linkPadding("top"), bottom = linkPadding("bottom") }
							else { top = linkPadding("top") },
						sizeConstraint = if stacked
							then nil
							else function(): Types.SizeConstraint?
								local maxWidth = maxTrailingWidth()
								return if maxWidth > 0 then { MaxSize = Vector2.new(maxWidth, math.huge) } else nil
							end,
						stateLayer = { affordance = StateLayerAffordance.None },
						onActivated = function()
							current().onActivated()
						end,
						LayoutOrder = 3,
						testId = `{testId}--link`,
						onAbsoluteSizeChanged = measure,
					})
				)
			end,
			actions = function()
				local current = lastPresent(actions)
				return named(
					"Trailing",
					ButtonGroup({
						buttons = function(): { ButtonGroupItem }
							local buttons = current()
							local items: { ButtonGroupItem } = {
								{
									text = buttons.primary.text,
									onActivated = buttons.primary.onActivated,
									variant = ButtonVariant.Standard,
								},
							}
							if buttons.secondary then
								table.insert(items, {
									text = buttons.secondary.text,
									onActivated = buttons.secondary.onActivated,
									variant = ButtonVariant.Utility,
								})
							end
							return items
						end,
						size = InputSize.Small,
						LayoutOrder = 3,
						testId = `{testId}--actions`,
						onAbsoluteSizeChanged = measure,
					})
				)
			end,
		})
	end

	local function close(): any
		if not onClose then
			return nil
		end
		return named(
			"Close",
			CloseAffordance({
				onActivated = onClose,
				size = InputSize.Small,
				variant = CloseAffordanceVariant.Utility,
				LayoutOrder = 4,
				testId = `{testId}--close`,
			})
		)
	end

	local function content(): { any }
		return {
			icon(),
			Vide.switch(isStacked)({
				[false] = function()
					return { message(), trailing(false) }
				end,
				[true] = function()
					return named(
						"Stack",
						View({
							LayoutOrder = 2,
							tag = function()
								return variantProps().stack.tag
							end,
							testId = `{testId}--stack`,
							children = { message(), trailing(true) },
						})
					)
				end,
			}),
			close(),
		}
	end

	local function border(name: string, layoutOrder: number, suffix: string): GuiObject
		return named(
			name,
			View({
				Size = function()
					return variantProps().border.Size
				end,
				backgroundStyle = function()
					return variantProps().border.backgroundStyle
				end,
				LayoutOrder = layoutOrder,
				testId = `{testId}--{suffix}`,
			})
		)
	end

	local isSystem = Vide.derive(function()
		return variant() == AlertVariant.System
	end)

	local onAbsoluteSizeChanged = props.onAbsoluteSizeChanged
	local containerProps = withCommonProps(props, {
		tag = function()
			return variantProps().container.tag
		end,
		backgroundStyle = function()
			return variantProps().container.backgroundStyle
		end,
		--* UIStroke can't draw a single edge, so System draws its borders as views.
		children = Vide.switch(isSystem)({
			[true] = function()
				return {
					border("TopBorder", 1, "top-border"),
					named(
						"Main",
						View({
							tag = function()
								return variantProps().main.tag
							end,
							LayoutOrder = 2,
							children = content(),
						})
					),
					border("BottomBorder", 3, "bottom-border"),
				}
			end,
			[false] = content,
		}),
	}) :: any
	containerProps.onAbsoluteSizeChanged = function(rbx: GuiObject)
		alertSize(rbx.AbsoluteSize)
		if onAbsoluteSizeChanged then
			onAbsoluteSizeChanged(rbx)
		end
	end

	return View(containerProps)
end

return Alert
