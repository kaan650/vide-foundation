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
local isBuilderIcon = require("../../Utility/isBuilderIcon")
local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local useAlertVariants = require("./useAlertVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local IconVariant = BuilderIcons.IconVariant
type IconVariant = BuilderIcons.IconVariant

type AlertSeverity = AlertSeverity.AlertSeverity
type AlertVariant = AlertVariant.AlertVariant
type ButtonGroupItem = ButtonGroup.ButtonGroupItem
type IconConfig = Types.IconConfig
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
	-- Replaces the glyph on `Info` alerts, keeping the severity color. Other severities ignore it.
	-- Builder Icons only. Nil, empty, or non-Builder Icons fall back to the Info glyph.
	icon: Value<IconConfig?>?,
	-- Message shown in the alert
	text: Value<string>,
	-- Interprets markup in `text` (e.g. bold, color, links).
	richText: Value<boolean?>?,
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
-- Trailing content stacks once it needs more than 30% of the alert width.
local STACKING_TRAILING_MAX_WIDTH_RATIO = 0.3

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

type WrappingRichTextProps = {
	slotTag: () -> string,
	padding: Types.PaddingTable,
	text: Value<string>,
	LayoutOrder: number,
	testId: string,
	alertWidth: () -> number,
	onActivated: ((self: GuiObject, inputObject: InputObject, clickCount: number) -> ())?,
	stateLayer: Types.StateLayer?,
}

--- Rich text that wraps at its slot's measured width. Foundation's workaround for UIBLOX-5430.
local function WrappingRichText(props: WrappingRichTextProps): GuiObject
	local slotWidth = Vide.source(0)
	local labelKey = Vide.derive(function()
		return math.floor(slotWidth())
	end)

	--! A MaxSize alone clamps the label but doesn't always make the engine re-solve the wrap, so the label is
	--! rebuilt (React remounts it under a new key) each time the settled width changes by a whole pixel.
	local label = rebuildOn(labelKey, function(key: number)
		local instance = Text({
			Text = props.text,
			RichText = true,
			tag = function(): Types.Tags
				return { ["size-full-0"] = true, [props.slotTag()] = true }
			end,
			padding = props.padding,
			sizeConstraint = function(): Types.SizeConstraint?
				local width = slotWidth()
				return if width > 0 then { MaxSize = Vector2.new(width, math.huge) } else nil
			end,
			stateLayer = props.stateLayer,
			onActivated = props.onActivated,
			testId = props.testId,
		})
		instance.Name = `Label-{key}`
		return instance
	end)

	return View({
		tag = props.slotTag,
		LayoutOrder = props.LayoutOrder,
		onAbsoluteSizeChanged = function(rbx: GuiObject)
			local width = rbx.AbsoluteSize.X
			local alertWidth = props.alertWidth()
			if alertWidth <= 0 or width <= alertWidth then
				slotWidth(width)
			end
		end,
		children = label,
	})
end

--- A message with a severity icon, and an optional link or action buttons and close button. It measures its own
--- width and stacks the trailing slot under the message when the alert is narrow or the trailing slot needs more
--- than 30% of it.
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

	local isStacked = Vide.derive(function(): boolean
		local width = alertSize().X
		local isNarrow = width > 0 and width <= STACK_MAX_WIDTH
		local maxTrailing = width * STACKING_TRAILING_MAX_WIDTH_RATIO
		return isNarrow or (maxTrailing > 0 and trailingWidth() > maxTrailing)
	end)
	local function alertWidth(): number
		return alertSize().X
	end

	local variantProps = Vide.derive(function()
		return useAlertVariants(tokens(), severity(), variant(), isStacked())
	end)

	type LeadingIcon = { name: string, variant: IconVariant, isCustom: boolean }
	local leadingIcon = Vide.derive(function(): LeadingIcon
		local current = severity()
		local custom: IconConfig? = Value.read(props.icon)
		if custom ~= nil and current == AlertSeverity.Info then
			local customName = if typeof(custom) == "string" then custom else custom.name
			if isBuilderIcon(customName) then
				return {
					name = customName,
					variant = if typeof(custom) == "table" and custom.variant
						then custom.variant
						else IconVariant.Filled,
					isCustom = true,
				}
			end
		end
		return { name = AlertConstants.SEVERITY_TO_ICON[current], variant = IconVariant.Filled, isCustom = false }
	end)

	local function severityIcon(): GuiObject
		return Icon({
			name = function()
				return leadingIcon().name
			end,
			size = IconSize.Medium,
			variant = function()
				return leadingIcon().variant
			end,
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
					--* The disc fills the knockout in the severity glyphs; a custom glyph may not have one.
					return if leadingIcon().isCustom then nil else variantProps().iconBackplate
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

	local function messageTag(): string
		return variantProps().message.tag
	end
	local messagePadding: Types.PaddingTable = {
		top = function()
			return variantProps().message.padding.top :: UDim
		end,
	}

	local richTextProp = props.richText
	local isRichText: Value<boolean> = if type(richTextProp) == "function"
		then Vide.derive(function()
			return (richTextProp :: () -> boolean?)() == true
		end)
		else richTextProp == true

	local function message()
		return named(
			"Message",
			rebuildOn(isRichText, function(richText: boolean): GuiObject
				if richText then
					return WrappingRichText({
						slotTag = messageTag,
						padding = messagePadding,
						text = props.text,
						LayoutOrder = 2,
						testId = `{testId}--message`,
						alertWidth = alertWidth,
					})
				end
				return Text({
					Text = props.text,
					tag = messageTag,
					padding = messagePadding,
					LayoutOrder = 2,
					testId = `{testId}--message`,
				})
			end)
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
		--* Measuring while stacked would feed the stacked width back into the overflow check.
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
		local function linkTag(): string
			return variantProps().link.tag
		end

		return Vide.switch(trailingKind)({
			link = function()
				local current = lastPresent(link)
				local function linkText(): string
					return `<u>{escapeRichText(current().text)}</u>`
				end
				if stacked then
					--* Stacked, the underlined link wraps at the slot's full width.
					return named(
						"Trailing",
						WrappingRichText({
							slotTag = linkTag,
							padding = { top = linkPadding("top"), bottom = linkPadding("bottom") },
							text = linkText,
							LayoutOrder = 3,
							testId = `{testId}--link`,
							alertWidth = alertWidth,
							onActivated = function()
								current().onActivated()
							end,
							stateLayer = { affordance = StateLayerAffordance.None },
						})
					)
				end
				return named(
					"Trailing",
					Text({
						Text = linkText,
						RichText = true,
						tag = linkTag,
						padding = { top = linkPadding("top") },
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
