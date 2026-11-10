local Vide = require("../../Packages/Vide")

local ButtonGroup = require("../ButtonGroup")
local CloseAffordance = require("../CloseAffordance")
local CloseAffordanceVariant = require("../../Enums/CloseAffordanceVariant")
local ColorNamespace = require("../../Enums/ColorNamespace")
local Constants = require("../../Constants")
local InputSize = require("../../Enums/InputSize")
local Orientation = require("../../Enums/Orientation")
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
type PopoverAlign = PopoverAlign.PopoverAlign
type PopoverAnchor = Types.PopoverAnchor
type PopoverAnchorProps = Popover.PopoverAnchorProps
type PopoverSide = PopoverSide.PopoverSide
type SizeConstraint = Types.SizeConstraint
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
	isOpen: Value<boolean>?,
	-- Close callback (optional) - if provided, displays a close affordance in the header
	onClose: (() -> ())?,
	-- Callback invoked when the backdrop (outside the tooltip) is pressed.
	onPressedOutside: (() -> ())?,
	-- Step indicator (optional) - shows "X of Y" above the header
	steps: Value<CoachmarkSteps?>?,
	align: Value<PopoverAlign>?,
	side: Value<PopoverSide>?,
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
	testId = "--foundation-coachmark",
}

local MAX_BUTTON_COUNT = 2
local MIN_WIDTH = 240

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
	local maxXSize = useScaledValue(Constants.TOOLTIP_MAX_WIDTH)
	local minXSize = useScaledValue(MIN_WIDTH)
	local testId = props.testId
	local onClose = props.onClose

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

	--* Text stays clear of the close affordance in the top-right corner.
	local textSizeConstraint: SizeConstraint? = if onClose
		then {
			MaxSize = function()
				return Vector2.new(maxXSize() - tokens().Size.Size_1200, math.huge)
			end,
		}
		else nil

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
			tag = "auto-xy text-caption-medium text-align-x-left text-truncate-end content-inverse-default",
			sizeConstraint = textSizeConstraint,
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
			sizeConstraint = textSizeConstraint,
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
			tag = "size-full-0 auto-y text-body-medium text-wrap text-align-x-left content-inverse-default",
			padding = {
				top = function()
					return UDim.new(0, tokens().Size.Size_100)
				end,
			},
			testId = `{testId}--text`,
		})
		label.Name = "Text"
		return label
	end

	local function ContentSection(): GuiObject
		local section = View({
			LayoutOrder = 2,
			tag = "col auto-xy padding-medium",
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

	local function Actions(): GuiObject
		local buttonGroup = ButtonGroup({
			buttons = function()
				return actions() or {}
			end,
			maxButtonCount = MAX_BUTTON_COUNT,
			orientation = Orientation.Horizontal,
			size = InputSize.Small,
			testId = `{testId}--actions`,
		})
		buttonGroup.Name = "ButtonGroup"

		local actionsView = View({
			LayoutOrder = 3,
			tag = "row align-x-right size-full-0 auto-y padding-x-medium padding-bottom-medium",
			children = buttonGroup,
		})
		actionsView.Name = "Actions"
		return actionsView
	end

	local function Body(): GuiObject
		return PresentationContext.context(INVERSE_PRESENTATION, function()
			local body = View({
				tag = "col auto-xy",
				sizeConstraint = {
					MaxSize = function()
						return Vector2.new(maxXSize(), math.huge)
					end,
					MinSize = function()
						return Vector2.new(minXSize(), 0)
					end,
				},
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
				Popover.Anchor(withCommonProps(props, {
					anchorRef = props.anchorRef,
					children = props.children,
				} :: PopoverAnchorProps)),
				Popover.Content({
					hasArrow = true,
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
