local Vide = require("../../Packages/Vide")

local ScrollView = require("../ScrollView")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local withCommonProps = require("../../Utility/withCommonProps")

type SizeConstraint = Types.SizeConstraint
type Tags = Types.Tags
type Value<T> = Types.Value<T>

export type ScrollContainerProps = {
	sizeConstraint: Value<SizeConstraint?>?,
	tag: Value<Tags?>?,
	InputSink: Value<Enum.InputSink>?,
	-- Receives the ScrollingFrame, so callers can scroll the open menu (e.g. to the selection).
	scrollingFrameRef: ((ScrollingFrame) -> ())?,
} & Types.CommonProps

export type BaseMenuScrollContainerProps = {
	-- The height after which the container starts scrolling.
	maxHeight: Value<number?>?,
	-- Whether the container sizes its width to the content. Defaults to true.
	autoSize: Value<boolean>?,
	-- Fixed width used when `autoSize` is false.
	width: Value<UDim?>?,
	-- Props forwarded to the underlying ScrollView.
	scrollViewProps: ScrollContainerProps,
	children: Types.Children?,
}

--- Menu content in a ScrollView that grows with its content up to `maxHeight`, then caps its height and scrolls.
--- A ScrollingFrame with `AutomaticSize.Y` grows to its full content height and never scrolls, so the content
--- height is measured here and the frame is capped explicitly. Shared by the root menu and submenus.
local function BaseMenuScrollContainer(props: BaseMenuScrollContainerProps): GuiObject
	local scrollViewProps = props.scrollViewProps
	local canvasSize = Vide.source(UDim2.fromScale(0, 1))

	local function maxHeight(): number?
		return Value.read(props.maxHeight)
	end

	local function autoSize(): boolean
		if props.autoSize == nil then
			return true
		end
		return Value.read(props.autoSize)
	end

	local isOverMaxHeight = Vide.derive(function()
		local height = maxHeight()
		return height ~= nil and canvasSize().Y.Offset > height
	end)

	local function automaticSize(): Enum.AutomaticSize
		return if autoSize()
			then if isOverMaxHeight() then Enum.AutomaticSize.X else Enum.AutomaticSize.XY
			else if isOverMaxHeight() then Enum.AutomaticSize.None else Enum.AutomaticSize.Y
	end

	local content = View({
		tag = "col size-full-0 auto-y",
		onAbsoluteSizeChanged = function(frame: GuiObject)
			canvasSize(UDim2.fromOffset(frame.AbsoluteSize.X, frame.AbsoluteSize.Y))
		end,
		children = props.children,
	})
	content.Name = "ScrollingFrame"

	return ScrollView(withCommonProps(scrollViewProps, {
		sizeConstraint = scrollViewProps.sizeConstraint,
		tag = scrollViewProps.tag,
		InputSink = scrollViewProps.InputSink,
		scrollingFrameRef = scrollViewProps.scrollingFrameRef,
		scroll = {
			--* XY works everywhere except the scroll itself, which would grow to the full content height.
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			AutomaticSize = automaticSize,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			CanvasSize = function()
				return canvasSize()
			end,
		},
		AutomaticSize = automaticSize,
		Size = function()
			local height = maxHeight()
			local y = if isOverMaxHeight() and height then UDim.new(0, height) else UDim.new()
			local width: UDim? = Value.read(props.width)
			return if autoSize() then UDim2.new(UDim.new(), y) else UDim2.new(width or UDim.new(), y)
		end,
		children = content,
	}) :: any)
end

return BaseMenuScrollContainer
