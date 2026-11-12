local Vide = require("../../Packages/Vide")

local ControlState = require("../../Enums/ControlState")
local InputSize = require("../../Enums/InputSize")
local Motion = require("../../Utility/Motion")
local Scrim = require("./Scrim")
local ScrollView = require("../ScrollView")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local Visibility = require("../../Enums/Visibility")
local createMotor = require("../../Utility/Motion/createMotor")
local useClippingRect = require("./useClippingRect")
local usePreferredInput = require("../../Utility/usePreferredInput")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ControlState = ControlState.ControlState
type InputSize = InputSize.InputSize
type Value<T> = Types.Value<T>

export type OverflowScrollContainerProps = {
	size: Value<InputSize>?,
	-- Height at the bottom of the container the scrims leave uncovered, for a rule drawn there.
	scrimBottomInset: Value<number>?,
	children: Types.Children?,
	-- Debug overrides for stories: pin the scrims and the input treatment.
	forceHovered: Value<boolean?>?,
	forceScrimsVisible: Value<boolean?>?,
	forcePreferredInput: Value<Enum.PreferredInput?>?,
} & Types.CommonProps

--* A scrim click scrolls most of the viewport, leaving a sliver of the previous content to anchor against.
local SCROLL_OVERLAP_FACTOR = 0.8

local defaultProps = {
	size = InputSize.Medium,
	scrimBottomInset = 0,
	testId = "--foundation-overflow-scroll-container",
}

local function isHoverState(state: ControlState): boolean
	return state == ControlState.Hover or state == ControlState.Pressed
end

--- A horizontally scrolling row whose overflowing ends fade under scrims that scroll it on click.
local function OverflowScrollContainer(overflowScrollContainerProps: OverflowScrollContainerProps): GuiObject
	local props = withDefaults(overflowScrollContainerProps, defaultProps)
	local tokens = useTokens()
	local resolvedPreferredInput = usePreferredInput()

	local isEndVisible = Vide.source(false)
	local isStartVisible = Vide.source(false)
	local isContentHovered = Vide.source(false)
	local isStartHovered = Vide.source(false)
	local isEndHovered = Vide.source(false)
	local rowHeight = Vide.source(0)
	local scrollingFrame = Vide.source(nil :: ScrollingFrame?)
	local getScrollingFrame: () -> ScrollingFrame? = scrollingFrame :: any

	local function isHovered(): boolean
		return Value.read(props.forceHovered) == true or isContentHovered() or isStartHovered() or isEndHovered()
	end
	local function preferredInput(): Enum.PreferredInput
		return Value.read(props.forcePreferredInput) or resolvedPreferredInput()
	end
	local function size(): InputSize
		return Value.read(props.size)
	end

	local clippingRect, hasClippingAncestor = useClippingRect(getScrollingFrame :: () -> GuiObject?)

	local motor = createMotor(0, function(value: number)
		local frame = Vide.untrack(getScrollingFrame)
		if frame then
			frame.CanvasPosition = Vector2.new(value, 0)
		end
	end, function() end)
	Vide.cleanup(motor.destroy)

	local function updateOverflow(frame: ScrollingFrame)
		rowHeight(frame.AbsoluteWindowSize.Y)
		if frame.AbsoluteWindowSize.X == 0 then
			return
		end
		isStartVisible(frame.CanvasPosition.X > 0)
		isEndVisible((frame.AbsoluteWindowSize.X + frame.CanvasPosition.X) < (frame.AbsoluteCanvasSize.X - 1))
	end

	local function moveScrollInDirection(direction: number)
		local frame = Vide.untrack(getScrollingFrame)
		if not frame then
			return
		end

		local maxCanvasPosition = math.max(frame.AbsoluteCanvasSize.X - frame.AbsoluteWindowSize.X, 0)
		local scrollStep = frame.AbsoluteWindowSize.X * SCROLL_OVERLAP_FACTOR
		local snapThreshold = frame.AbsoluteWindowSize.X * (1 - SCROLL_OVERLAP_FACTOR)
		local nextCanvasPosition = frame.CanvasPosition.X + direction * scrollStep

		if direction > 0 and maxCanvasPosition - nextCanvasPosition <= snapThreshold then
			nextCanvasPosition = maxCanvasPosition
		elseif direction < 0 and nextCanvasPosition <= snapThreshold then
			nextCanvasPosition = 0
		end

		nextCanvasPosition = math.clamp(nextCanvasPosition, 0, maxCanvasPosition)
		--* The user may have scrolled since the last animation, so it starts from where the canvas is now.
		motor.setGoal(Motion.instant(frame.CanvasPosition.X))
		motor.setGoal(Motion.ease(nextCanvasPosition, {
			duration = Vide.untrack(tokens).Time.Time_200,
			easingStyle = Enum.EasingStyle.Quad,
		}))
	end

	local scroll = ScrollView({
		tag = "size-full-0 auto-y",
		ClipsDescendants = function()
			return not hasClippingAncestor()
		end,
		onStateChanged = function(state: ControlState)
			isContentHovered(isHoverState(state))
		end,
		stateLayer = {
			affordance = StateLayerAffordance.None,
		},
		onCanvasPositionChanged = updateOverflow,
		onAbsoluteCanvasSizeChanged = updateOverflow,
		onAbsoluteWindowSizeChanged = updateOverflow,
		scrollingFrameRef = function(frame: ScrollingFrame)
			scrollingFrame(frame)
			updateOverflow(frame)
		end,
		selection = {
			Selectable = false,
		},
		layout = {
			FillDirection = Enum.FillDirection.Horizontal,
		},
		scroll = {
			AutomaticSize = Enum.AutomaticSize.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			CanvasSize = UDim2.fromScale(0, 1),
			ScrollingDirection = Enum.ScrollingDirection.X,
			scrollBarVisibility = Visibility.None,
		},
		testId = `{props.testId}--scroll`,
		children = props.children,
	})
	scroll.Name = "Scroll"

	local function scrim(alignment: Enum.HorizontalAlignment): GuiObject
		local isStart = alignment == Enum.HorizontalAlignment.Left
		local isVisible: () -> boolean = if isStart then isStartVisible else isEndVisible
		local setScrimHovered: (boolean) -> boolean = if isStart then isStartHovered else isEndHovered
		local view = Scrim({
			LayoutOrder = if isStart then 1 else 2,
			size = size,
			rowHeight = rowHeight,
			alignment = alignment,
			isHovered = isHovered,
			preferredInput = preferredInput,
			isVisible = function()
				return Value.read(props.forceScrimsVisible) == true or isVisible()
			end,
			onActivated = function()
				moveScrollInDirection(if isStart then -1 else 1)
			end,
			onStateChanged = function(state: ControlState)
				setScrimHovered(isHoverState(state))
			end,
			testId = `{props.testId}--scrim-{if isStart then "start" else "end"}`,
		})
		view.Name = if isStart then "ScrimStart" else "ScrimEnd"
		return view
	end

	local scrimLayer = View({
		tag = "row flex-between",
		Position = function()
			return UDim2.fromOffset(clippingRect().Min.X, 0)
		end,
		--* Scale height keeps the layer out of the root's automatic size, which would otherwise measure the layer
		--* to decide the height the layer is measured against.
		Size = function()
			local rect = clippingRect()
			return UDim2.new(0, rect.Max.X - rect.Min.X, 1, -Value.read(props.scrimBottomInset))
		end,
		ZIndex = 2,
		testId = `{props.testId}--scrim-layer`,
		children = {
			scrim(Enum.HorizontalAlignment.Left),
			scrim(Enum.HorizontalAlignment.Right),
		},
	})
	scrimLayer.Name = "ScrimLayer"

	return View(withCommonProps(props, {
		tag = "size-full-0 auto-y",
		children = { scroll, scrimLayer },
	}) :: any)
end

return OverflowScrollContainer
