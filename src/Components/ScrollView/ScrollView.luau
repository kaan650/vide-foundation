local Vide = require("../../Packages/Vide")

local ControlState = require("../../Enums/ControlState")
local GuiObjectChildren = require("../../Utility/GuiObjectChildren")
local ScrollingFrame = require("./ScrollingFrame")
local Types = require("../Types")
local View = require("../View")
local Visibility = require("../../Enums/Visibility")
local withDefaults = require("../../Utility/withDefaults")

type ControlState = ControlState.ControlState
type Visibility = Visibility.Visibility
type ListLayout = Types.ListLayout
type Value<T> = Types.Value<T>

export type Scroll = {
	AutomaticSize: Value<Enum.AutomaticSize>?,
	AutomaticCanvasSize: Value<Enum.AutomaticSize>?,
	CanvasSize: Value<UDim2>?,
	ScrollingDirection: Value<Enum.ScrollingDirection>?,
	ScrollingEnabled: Value<boolean>?,
	VerticalScrollBarInset: Value<Enum.ScrollBarInset>?,
	HorizontalScrollBarInset: Value<Enum.ScrollBarInset>?,
	scrollBarVisibility: Value<Visibility>?,
}

export type ScrollViewProps = {
	scroll: Scroll?,
	-- Receives the inner ScrollingFrame, which holds the children.
	scrollingFrameRef: ((ScrollingFrame) -> ())?,
	onCanvasPositionChanged: ((instance: ScrollingFrame) -> ())?,
	onAbsoluteCanvasSizeChanged: ((instance: ScrollingFrame) -> ())?,
	onAbsoluteWindowSizeChanged: ((instance: ScrollingFrame) -> ())?,
} & Types.GuiObjectProps & Types.CommonProps

local defaultProps = {
	layout = {
		SortOrder = Enum.SortOrder.LayoutOrder,
	} :: ListLayout,
	scroll = {
		scrollBarVisibility = Visibility.Auto,
	} :: Scroll,
	AutoLocalize = false,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	isDisabled = false,
	testId = "--foundation-scroll-view",
}

--- A View whose children scroll. `layout` lays out the scrolled children, not the view.
local function ScrollView(scrollViewProps: ScrollViewProps): GuiObject
	local props = withDefaults(scrollViewProps, defaultProps)
	local scroll: Scroll = props.scroll
	local controlState = Vide.source(ControlState.Initialize :: ControlState)

	local function onStateChanged(state: ControlState)
		controlState(state)
		if props.onStateChanged ~= nil then
			props.onStateChanged(state)
		end
	end

	local layout = props.layout

	local frame = ScrollingFrame({
		controlState = function()
			return controlState()
		end,
		selection = props.selection,
		scrollBarVisibility = scroll.scrollBarVisibility,
		onCanvasPositionChanged = props.onCanvasPositionChanged,
		onAbsoluteCanvasSizeChanged = props.onAbsoluteCanvasSizeChanged,
		onAbsoluteWindowSizeChanged = props.onAbsoluteWindowSizeChanged,

		AutomaticSize = scroll.AutomaticSize,
		AutomaticCanvasSize = scroll.AutomaticCanvasSize,
		CanvasSize = scroll.CanvasSize,
		ClipsDescendants = false,
		ScrollingDirection = scroll.ScrollingDirection,
		ScrollingEnabled = scroll.ScrollingEnabled,
		VerticalScrollBarInset = scroll.VerticalScrollBarInset,
		HorizontalScrollBarInset = scroll.HorizontalScrollBarInset,

		children = {
			--* Foundation lays out the children only when there are some.
			if props.children ~= nil then GuiObjectChildren({ layout = layout } :: any) else nil,
			props.children,
		},
	})
	frame.Name = "ScrollingFrame"
	if props.scrollingFrameRef then
		props.scrollingFrameRef(frame)
	end

	local viewProps: any = table.clone(props)
	viewProps.onStateChanged = onStateChanged
	viewProps.stateLayer = if props.onStateChanged or props.onActivated
		then props.stateLayer
		else { affordance = "None" }
	viewProps.selection = {
		Selectable = false,
	}
	viewProps.scroll = nil
	viewProps.layout = nil
	viewProps.scrollingFrameRef = nil
	viewProps.onCanvasPositionChanged = nil
	viewProps.onAbsoluteCanvasSizeChanged = nil
	viewProps.onAbsoluteWindowSizeChanged = nil
	viewProps.children = frame

	return View(viewProps)
end

return ScrollView
