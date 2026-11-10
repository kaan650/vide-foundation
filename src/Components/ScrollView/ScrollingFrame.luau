local Vide = require("../../Packages/Vide")

local ControlState = require("../../Enums/ControlState")
local Motion = require("../../Utility/Motion")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local Visibility = require("../../Enums/Visibility")
local create = require("../../Utility/create")
local useCursor = require("../../Providers/Cursor/useCursor")
local useTokens = require("../../Providers/Style/useTokens")
local withDefaults = require("../../Utility/withDefaults")

type ControlState = ControlState.ControlState
type Visibility = Visibility.Visibility
type Selection = Types.Selection
type Value<T> = Types.Value<T>

local HIDE_SCROLLBAR_DELAY = 3
local ANIMATION_CONFIG: Motion.SpringOptions = {
	frequency = 2,
}

export type ScrollingFrameProps = {
	controlState: () -> ControlState,
	selection: Selection?,
	scrollBarVisibility: Value<Visibility>?,
	onCanvasPositionChanged: ((instance: ScrollingFrame) -> ())?,
	onAbsoluteCanvasSizeChanged: ((instance: ScrollingFrame) -> ())?,
	onAbsoluteWindowSizeChanged: ((instance: ScrollingFrame) -> ())?,
	children: Types.Children?,

	AutomaticSize: Value<Enum.AutomaticSize>?,
	AutomaticCanvasSize: Value<Enum.AutomaticSize>?,
	CanvasSize: Value<UDim2>?,
	ClipsDescendants: Value<boolean>?,
	ScrollingDirection: Value<Enum.ScrollingDirection>?,
	ScrollingEnabled: Value<boolean>?,
	VerticalScrollBarInset: Value<Enum.ScrollBarInset>?,
	HorizontalScrollBarInset: Value<Enum.ScrollBarInset>?,
}

local defaultProps = {
	scrollBarVisibility = Visibility.Auto,
}

local function isShowingState(state: ControlState): boolean
	return state == ControlState.Hover or state == ControlState.Selected or state == ControlState.Pressed
end

--- The invisible ScrollingFrame inside ScrollView. Its scroll bar fades in while the view is hovered, selected or
--- scrolled, depending on `scrollBarVisibility`.
local function ScrollingFrame(scrollingFrameProps: ScrollingFrameProps): ScrollingFrame
	local props = withDefaults(scrollingFrameProps, defaultProps)
	local tokens = useTokens()
	local cursor = useCursor()
	local selection: Selection = props.selection or {}

	local function scrollBarVisibility(): Visibility
		return Value.read(props.scrollBarVisibility)
	end
	local function scrollBarStyle(): Types.ColorStyleValue
		return tokens().Color.Shift.Shift_400 :: any
	end

	local scrollBarTransparency, setScrollBarTransparency = Motion.useAnimatedBinding(1)
	local delayThread: thread? = nil

	local function cancelDelay()
		if delayThread then
			task.cancel(delayThread)
			delayThread = nil
		end
	end

	local function setIsScrollBarVisible(isVisible: boolean, delay: number?)
		cancelDelay()
		if isVisible then
			setScrollBarTransparency(Motion.spring(Vide.untrack(scrollBarStyle).Transparency :: number, ANIMATION_CONFIG))
		end
		if delay ~= nil then
			delayThread = task.delay(delay, function()
				delayThread = nil
				setScrollBarTransparency(Motion.spring(1, ANIMATION_CONFIG))
			end)
		end
	end
	Vide.cleanup(cancelDelay)

	Vide.effect(function()
		local visibility = scrollBarVisibility()
		local state = props.controlState()
		Vide.untrack(function()
			if visibility == Visibility.None then
				setIsScrollBarVisible(false, 0)
			elseif visibility == Visibility.Always then
				setIsScrollBarVisible(true)
			else
				setIsScrollBarVisible(isShowingState(state), if state == ControlState.Default then 0 else nil)
			end
		end)
	end)

	local properties: { [any]: any } = {
		AutomaticCanvasSize = props.AutomaticCanvasSize,
		CanvasSize = props.CanvasSize,
		ClipsDescendants = props.ClipsDescendants,
		ScrollingDirection = props.ScrollingDirection,
		ScrollingEnabled = props.ScrollingEnabled,
		ScrollBarImageColor3 = function()
			return scrollBarStyle().Color3 :: Color3
		end,
		ScrollBarImageTransparency = scrollBarTransparency,
		ScrollBarThickness = function()
			return if scrollBarVisibility() == Visibility.None then 0 else tokens().Size.Size_150
		end,
		VerticalScrollBarInset = props.VerticalScrollBarInset,
		HorizontalScrollBarInset = props.HorizontalScrollBarInset,

		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = props.AutomaticSize,
		Size = UDim2.fromScale(1, 1),

		Selectable = selection.Selectable,
		NextSelectionUp = selection.NextSelectionUp,
		NextSelectionDown = selection.NextSelectionDown,
		NextSelectionLeft = selection.NextSelectionLeft,
		NextSelectionRight = selection.NextSelectionRight,
		SelectionImageObject = function(): GuiObject?
			return Value.read(selection.SelectionImageObject) or cursor()
		end,
		SelectionOrder = selection.SelectionOrder,

		props.children,
	}
	local frame = (create :: any)("ScrollingFrame")(properties) :: ScrollingFrame

	local onCanvasPositionChanged = props.onCanvasPositionChanged
	Vide.cleanup(frame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if Vide.untrack(scrollBarVisibility) == Visibility.Auto then
			setIsScrollBarVisible(true, HIDE_SCROLLBAR_DELAY)
		end
		if onCanvasPositionChanged then
			onCanvasPositionChanged(frame)
		end
	end))
	local onAbsoluteCanvasSizeChanged = props.onAbsoluteCanvasSizeChanged
	if onAbsoluteCanvasSizeChanged then
		Vide.cleanup(frame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
			onAbsoluteCanvasSizeChanged(frame)
		end))
	end
	local onAbsoluteWindowSizeChanged = props.onAbsoluteWindowSizeChanged
	if onAbsoluteWindowSizeChanged then
		Vide.cleanup(frame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
			onAbsoluteWindowSizeChanged(frame)
		end))
	end

	return frame
end

return ScrollingFrame
