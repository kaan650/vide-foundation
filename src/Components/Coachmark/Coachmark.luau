local Vide = require("../../Packages/Vide")

local Button = require("../Button")
local ButtonGroup = require("../ButtonGroup")
local CloseAffordance = require("../CloseAffordance")
local CloseAffordanceVariant = require("../../Enums/CloseAffordanceVariant")
local ColorNamespace = require("../../Enums/ColorNamespace")
local FillBehavior = require("../../Enums/FillBehavior")
local InputSize = require("../../Enums/InputSize")
local Logger = require("../../Utility/Logger")
local Popover = require("../Popover")
local PopoverAlign = require("../../Enums/PopoverAlign")
local PopoverSide = require("../../Enums/PopoverSide")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local Radius = require("../../Enums/Radius")
local Text = require("../Text")
local Translator = require("../../Utility/Localization/Translator")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local create = require("../../Utility/create")
local named = require("../../Utility/named")
local useScaledValue = require("../../Utility/useScaledValue")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ButtonGroupItem = ButtonGroup.ButtonGroupItem
type ColorStyleValue = Types.ColorStyleValue
type FillBehavior = FillBehavior.FillBehavior
type PopoverAlign = PopoverAlign.PopoverAlign
type PopoverAnchor = Types.PopoverAnchor
type PopoverAnchorProps = Popover.PopoverAnchorProps
type PopoverSide = PopoverSide.PopoverSide
type Value<T> = Types.Value<T>

export type CoachmarkSteps = {
	current: number,
	total: number,
}

export type CoachmarkProps = {
	-- A title for the coachmark. To omit, set it to an empty string.
	title: Value<string>,
	-- Body text for the coachmark.
	text: Value<string?>?,
	-- Media displayed at the top of the coachmark, built each time it opens.
	media: (() -> Types.Children)?,
	-- Actions array (up to 2 buttons supported)
	actions: Value<{ ButtonGroupItem }?>?,
	-- How action buttons size along the tooltip width. Unused: 1.123 reads it only with the educational tooltip
	-- refresh, which is off, so the actions always fill.
	actionsFillBehavior: Value<FillBehavior?>?,
	isOpen: Value<boolean>?,
	-- Close callback (optional) - if provided, displays a close affordance in the header
	onClose: (() -> ())?,
	-- Callback invoked when the backdrop (outside the tooltip) is pressed.
	onPressedOutside: (() -> ())?,
	-- Step indicator (optional) - shows "X of Y" above the header
	steps: Value<CoachmarkSteps?>?,
	align: Value<PopoverAlign>?,
	side: Value<PopoverSide>?,
	-- Whether the tooltip should have an arrow. Defaults to true.
	hasArrow: Value<boolean>?,
	-- The element that serves as the anchor, instead of `children`.
	anchorRef: Value<PopoverAnchor?>?,
	-- Receives the coachmark's content frame when it opens, and nil when it closes.
	ref: ((content: GuiObject?) -> ())?,
	children: Types.Children?,
	-- Selection behavior
	selection: Types.Selection?,
	selectionGroup: (Value<boolean> | Types.SelectionGroup)?,
} & Types.CommonProps

local defaultProps = {
	isOpen = false,
	align = PopoverAlign.Start,
	side = PopoverSide.Right,
	hasArrow = true,
	testId = "--foundation-coachmark",
}

local MAX_BUTTON_COUNT = 2
local MAX_WIDTH = 320

local INVERSE_PRESENTATION: PresentationContext.PresentationContextValue = {
	isIconSize = false,
	colorNamespace = ColorNamespace.Inverse,
}

local function stepsText(current: number, total: number): string
	return Translator:FormatByKey("CommonUI.Controls.Label.PageCount", { current = current, total = total })
end

--- A popover that points at a feature: optional media, steps, title, text, actions and a close button. Returns the
--- anchor (unless `anchorRef` names one), plus the coachmark itself when there is no overlay to render it into.
local function Coachmark(coachmarkProps: CoachmarkProps): { any }
	local props = withDefaults(coachmarkProps, defaultProps)
	local tokens = useTokens()
	local maxXSize = useScaledValue(MAX_WIDTH)
	local testId = props.testId
	local onClose = props.onClose
	--* Without media the close affordance sits over the text, so the content pads its right side clear of it.
	local needsCloseAffordancePadding = onClose ~= nil and props.media == nil

	local function title(): string
		return Value.read(props.title)
	end
	local function text(): string?
		return Value.read(props.text)
	end
	local function steps(): CoachmarkSteps?
		return Value.read(props.steps)
	end
	local function actions(): { ButtonGroupItem }?
		return Value.read(props.actions)
	end

	local function CloseAffordanceContainer(close: () -> ()): Instance
		local closeAffordance = CloseAffordance({
			onActivated = close,
			size = InputSize.Small,
			variant = CloseAffordanceVariant.Utility,
			Position = function()
				local padding = tokens().Padding.Small
				return UDim2.new(1, -padding, 0, padding)
			end,
			AnchorPoint = Vector2.new(1, 0),
			ZIndex = 2,
			testId = `{testId}--close-affordance`,
		})
		return create("Folder")({
			Name = "CloseAffordanceContainer",
			named("CloseAffordance", closeAffordance) :: any,
		})
	end

	local function Media(buildMedia: () -> Types.Children): GuiObject
		local media = View({
			LayoutOrder = 1,
			tag = "size-full-0 auto-y",
			children = buildMedia(),
		})
		media.Name = "Media"
		return media
	end

	local function StepIndicator(): GuiObject
		local label = Text({
			LayoutOrder = 1,
			Text = function()
				local current = steps()
				return if current then stepsText(current.current, current.total) else ""
			end,
			tag = "auto-xy text-label-small text-align-x-left text-truncate-end content-inverse-default",
			testId = `{testId}--step-indicator`,
		})
		label.Name = "StepIndicator"
		return label
	end

	local function Header(): GuiObject
		local label = Text({
			LayoutOrder = 2,
			Text = title,
			tag = "auto-xy text-title-large text-align-x-left text-truncate-split content-inverse-emphasis",
			testId = `{testId}--header`,
		})
		label.Name = "Header"
		return label
	end

	local function BodyText(): GuiObject
		local label = Text({
			LayoutOrder = 3,
			Text = function()
				return text() or ""
			end,
			tag = "auto-xy text-body-medium text-wrap text-align-x-left content-inverse-default",
			testId = `{testId}--text`,
		})
		label.Name = "Text"
		return label
	end

	local function ContentSection(): GuiObject
		local section = View({
			LayoutOrder = 2,
			tag = if needsCloseAffordancePadding
				then "col gap-xsmall auto-xy"
				else "col gap-xsmall auto-xy padding-x-medium padding-bottom-xsmall padding-top-medium",
			padding = if needsCloseAffordancePadding
				then {
					top = function()
						return UDim.new(0, tokens().Padding.Medium)
					end,
					bottom = function()
						return UDim.new(0, tokens().Padding.XSmall)
					end,
					left = function()
						return UDim.new(0, tokens().Padding.Medium)
					end,
					right = function()
						return UDim.new(0, tokens().Size.Size_1200)
					end,
				}
				else nil,
			children = {
				Vide.show(function()
					return steps() ~= nil
				end, StepIndicator),
				Vide.show(function()
					return title() ~= ""
				end, Header),
				Vide.show(function()
					local value = text()
					return value ~= nil and value ~= ""
				end, BodyText),
			},
		})
		section.Name = "ContentSection"
		return section
	end

	local function actionButton(item: ButtonGroupItem, index: number): GuiObject
		local button = Button({
			text = item.text,
			onActivated = item.onActivated,
			variant = item.variant,
			isDisabled = item.isDisabled,
			isLoading = item.isLoading,
			icon = item.icon,
			inputDelay = item.inputDelay,
			LayoutOrder = index,
			size = InputSize.Medium,
			fillBehavior = FillBehavior.Fill,
			testId = `{testId}--action-{index}`,
		})
		button.Name = `CoachmarkButton{index}`
		if item.ref then
			item.ref(button)
		end
		return button
	end

	local function shownActions(): { ButtonGroupItem }
		local list = actions() or {}
		if #list <= MAX_BUTTON_COUNT then
			return list
		end
		return table.move(list, 1, MAX_BUTTON_COUNT, 1, {})
	end

	local function Actions(): GuiObject
		Vide.effect(function()
			local list = actions()
			if list and #list > MAX_BUTTON_COUNT then
				Logger:warning(`Coachmark only supports up to {MAX_BUTTON_COUNT} actions`)
			end
		end)

		local buttons
		if type(props.actions) == "function" then
			buttons = Vide.indexes(shownActions, function(item: () -> ButtonGroupItem, index: number)
				local function field(key: string): () -> any
					return function()
						return Value.read((item() :: any)[key])
					end
				end
				return actionButton({
					text = field("text"),
					onActivated = function()
						item().onActivated()
					end,
					variant = field("variant"),
					isDisabled = field("isDisabled"),
					isLoading = field("isLoading"),
					icon = field("icon"),
					inputDelay = field("inputDelay"),
					ref = Vide.untrack(item).ref,
				}, index)
			end)
		else
			buttons = {}
			for index, item in shownActions() do
				table.insert(buttons, actionButton(item, index))
			end
		end

		local actionsView = View({
			LayoutOrder = 3,
			tag = "row gap-small size-full-0 auto-y padding-x-medium",
			children = buttons,
		})
		actionsView.Name = "Actions"
		return actionsView
	end

	local function Body(): GuiObject
		return PresentationContext.context(INVERSE_PRESENTATION, function()
			local body = View({
				tag = "col gap-medium auto-xy padding-bottom-medium",
				sizeConstraint = {
					MaxSize = function()
						return Vector2.new(maxXSize(), math.huge)
					end,
				},
				testId = testId,
				children = {
					if onClose then CloseAffordanceContainer(onClose) else nil,
					if props.media then Media(props.media) else nil,
					ContentSection(),
					Vide.show(function()
						local list = actions()
						return list ~= nil and #list > 0
					end, Actions),
				},
			})
			body.Name = "Children"
			return body
		end)
	end

	return Popover.Root({
		isOpen = props.isOpen,
		testId = testId,
		children = function()
			return {
				Popover.Anchor(withCommonProps(
					props,
					{
						anchorRef = props.anchorRef,
						children = props.children,
					} :: PopoverAnchorProps
				)),
				Popover.Content({
					hasArrow = props.hasArrow,
					align = props.align,
					DO_NOT_USE_hasContentInputSink = true,
					onPressedOutside = props.onPressedOutside,
					side = function()
						return {
							position = Value.read(props.side),
							offset = tokens().Size.Size_200,
						}
					end,
					radius = Radius.Medium,
					backgroundStyle = function()
						return tokens().Inverse.Surface.Surface_0 :: ColorStyleValue
					end,
					selection = props.selection,
					selectionGroup = props.selectionGroup,
					ref = props.ref,
					children = Body,
				}),
			}
		end,
	})
end

return Coachmark
