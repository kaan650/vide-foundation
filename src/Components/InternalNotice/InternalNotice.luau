local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
type IconVariant = BuilderIcons.IconVariant

local CloseAffordance = require("../CloseAffordance")
local CloseAffordanceVariant = require("../../Enums/CloseAffordanceVariant")
local Icon = require("../Icon")
local InputSize = require("../../Enums/InputSize")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local escapeRichText = require("../../Utility/escapeRichText")
local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local useInternalNoticeLayout = require("./useInternalNoticeLayout")
local useInternalNoticeVariantsProps = require("./useInternalNoticeVariantsProps")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")

type ColorStyleValue = Types.ColorStyleValue
type IconConfig = Types.IconConfig
type SizeConstraint = Types.SizeConstraint
type Value<T> = Types.Value<T>

export type InternalNoticeLink = {
	text: string,
	onActivated: () -> (),
}

export type InternalNoticeVariantProps = useInternalNoticeVariantsProps.InternalNoticeVariantProps

export type InternalNoticeProps = {
	text: Value<string>,
	link: Value<InternalNoticeLink?>?,
	onClose: (() -> ())?,
	icon: Value<IconConfig?>?,
	-- Truncates the message and link to one line. Wrap when false.
	truncation: Value<boolean>?,
	variantProps: Value<InternalNoticeVariantProps>,
} & Types.CommonProps

type IconTable = { name: string, variant: IconVariant? }
type Border = { Size: UDim2, backgroundStyle: ColorStyleValue }

type Resolved = {
	variantProps: InternalNoticeVariantProps,
	isStacked: boolean,
}

-- Centers the icon and close against the first line.
local ICON_SLOT_TAG = "col align-y-center auto-x"

--- The layout BannerContext is built on: an optional icon, a message, an optional underlined link and an optional
--- close button, with the link stacked under the message when the notice is narrow.
local function InternalNotice(props: InternalNoticeProps): GuiObject
	local testId = props.testId or "--foundation-internal-notice"
	local tokens = useTokens()

	-- Holds the first line to the design's content-row height. A taller trailing slot grows the
	-- row past it, since the content row is auto-y and this is only a minimum.
	local function iconSlotSize(): UDim2
		return UDim2.fromOffset(0, tokens().Size.Size_600)
	end
	local function firstLineSlot(): SizeConstraint
		return { MinSize = Vector2.new(0, tokens().Size.Size_600) }
	end

	local layout = useInternalNoticeLayout(props.onAbsoluteSizeChanged)

	local resolved = Vide.derive(function(): Resolved
		local isStacked = layout.isStacked()
		return {
			variantProps = useInternalNoticeVariantsProps(
				Value.read(props.variantProps),
				isStacked,
				Value.read(props.truncation) == true
			),
			isStacked = isStacked,
		}
	end)

	local function icon(): IconTable?
		local config: IconConfig? = Value.read(props.icon)
		return if typeof(config) == "string" then { name = config, variant = nil } else config
	end
	local function link(): InternalNoticeLink?
		return Value.read(props.link)
	end

	--* Padding and the slots' structure follow the variant and the stacking, so the row is built again when they change,
	--* as React remounts the elements that move between the leading and stack views.
	local function buildContent(state: Resolved): GuiObject
		local variantProps = state.variantProps
		local isStacked = state.isStacked

		local leadingIcon = Vide.show(icon, function(current: () -> IconTable)
			local glyph = Icon({
				name = function()
					return current().name
				end,
				variant = function(): IconVariant
					return current().variant :: IconVariant
				end,
				size = variantProps.icon.size,
				style = variantProps.icon.style,
				LayoutOrder = 1,
				testId = `{testId}--icon`,
			})
			glyph.Name = "Icon"
			local slot = View({
				tag = ICON_SLOT_TAG,
				Size = iconSlotSize,
				LayoutOrder = 1,
				children = glyph,
			})
			slot.Name = "Icon"
			return slot
		end)

		local message = Text({
			Text = props.text,
			tag = variantProps.message.tag,
			padding = variantProps.message.padding,
			LayoutOrder = 2,
			testId = `{testId}--message`,
		})
		message.Name = "Message"

		local linkText = Vide.show(link, function(current: () -> InternalNoticeLink)
			local label = Text({
				Text = function()
					return `<u>{escapeRichText(current().text)}</u>`
				end,
				RichText = true,
				tag = variantProps.link.tag,
				padding = variantProps.link.padding,
				sizeConstraint = if isStacked then layout.stackedLinkConstraint else nil,
				stateLayer = { affordance = StateLayerAffordance.None },
				onActivated = function()
					current().onActivated()
				end,
				LayoutOrder = if isStacked then 3 else 2,
				testId = `{testId}--link`,
				onAbsoluteSizeChanged = if isStacked then nil else layout.measureInlineLink,
			})
			label.Name = "Link"
			return label
		end)

		local close: GuiObject? = nil
		local onClose = props.onClose
		if onClose then
			close = View({
				tag = ICON_SLOT_TAG,
				Size = iconSlotSize,
				LayoutOrder = 3,
				children = named(
					"Close",
					CloseAffordance({
						onActivated = onClose,
						size = InputSize.Small,
						variant = CloseAffordanceVariant.Utility,
						--* Padded close is taller than the content row, so it would drive the banner height.
						hasPadding = false,
						LayoutOrder = 1,
						testId = `{testId}--close`,
					})
				),
			})
			close.Name = "Close"
		end

		local children
		if isStacked then
			local stack = View({
				LayoutOrder = 2,
				tag = variantProps.stack.tag,
				sizeConstraint = firstLineSlot,
				onAbsoluteSizeChanged = layout.onStackedColumnAbsoluteSizeChanged,
				testId = `{testId}--stack`,
				children = { message, linkText },
			})
			stack.Name = "Stack"
			children = { leadingIcon, stack, close }
		else
			local leading = View({
				tag = variantProps.leading.tag,
				sizeConstraint = firstLineSlot,
				LayoutOrder = 1,
				testId = `{testId}--leading`,
				children = { leadingIcon, message },
			})
			leading.Name = "Leading"
			children = { leading, linkText, close }
		end

		local content = View({
			tag = variantProps.content.tag,
			padding = variantProps.content.padding,
			LayoutOrder = if variantProps.border then 2 else 1,
			children = children,
		})
		return content
	end

	local function border(): Border?
		return resolved().variantProps.border
	end

	local function borderView(name: string, layoutOrder: number, suffix: string)
		return Vide.show(border, function(current: () -> Border)
			local view = View({
				Size = function()
					return current().Size
				end,
				backgroundStyle = function(): ColorStyleValue
					return current().backgroundStyle
				end,
				LayoutOrder = layoutOrder,
				testId = `{testId}--{suffix}`,
			})
			view.Name = name
			return view
		end)
	end

	local containerProps = withCommonProps(props, {
		tag = function()
			local container = resolved().variantProps.container
			return if container then container.tag else nil
		end,
		backgroundStyle = function(): ColorStyleValue?
			local container = resolved().variantProps.container
			return if container then container.backgroundStyle else nil
		end,
		children = {
			borderView("TopBorder", 1, "top-border"),
			named("Main", rebuildOn(resolved, buildContent)),
			borderView("BottomBorder", 3, "bottom-border"),
		},
	})
	containerProps.onAbsoluteSizeChanged = layout.onNoticeAbsoluteSizeChanged

	return View(containerProps :: any)
end

return InternalNotice
