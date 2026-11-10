local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
local IconName = BuilderIcons.Icon

local Dash = require("../../Utility/Dash")
local IconButton = require("../IconButton")
local InputSize = require("../../Enums/InputSize")
local Motion = require("../../Utility/Motion")
local ScrollView = require("../ScrollView")
local Types = require("../Types")
local View = require("../View")
local Visibility = require("../../Enums/Visibility")
local create = require("../../Utility/create")
local createMotor = require("../../Utility/Motion/createMotor")
local named = require("../../Utility/named")
local withCommonProps = require("../../Utility/withCommonProps")

type InputSize = InputSize.InputSize

local START_GRADIENT = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.8, 0),
	NumberSequenceKeypoint.new(1, 1),
})

local END_GRADIENT = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.2, 0),
	NumberSequenceKeypoint.new(1, 0),
})
local SCROLL_STEP = 90

type OverflowButtonProps = {
	size: () -> InputSize,
	gradient: NumberSequence,
	onActivated: () -> (),
	tag: string,
	icon: string,
} & Types.CommonProps

local function OverflowButton(props: OverflowButtonProps): GuiObject
	return View(withCommonProps(props, {
		tag = `col align-y-center size-0-full auto-x bg-surface-0 {props.tag}`,
		children = {
			create("UIGradient")({
				Name = "UIGradient",
				Transparency = props.gradient,
			}),
			named(
				"Button",
				IconButton({
					onActivated = props.onActivated,
					size = function()
						local size = props.size()
						return if size == InputSize.Large or size == InputSize.Medium
							then InputSize.Small
							else InputSize.XSmall
					end,
					icon = {
						name = props.icon,
					},
				})
			),
		},
	}) :: any)
end

export type OverflowScrollContainerProps = {
	size: () -> InputSize,
	children: Types.Children?,
} & Types.CommonProps

--- Tabs' horizontally scrolling row, with chevron buttons over the ends that overflow. Foundation keeps it for Tabs
--- while FoundationUnifiedScrimScrolling is off.
local function OverflowScrollContainer(props: OverflowScrollContainerProps): GuiObject
	local isEndOverflowVisible = Vide.source(false)
	local isStartVisible = Vide.source(false)
	local scrollingFrame: ScrollingFrame? = nil

	local motor = createMotor(0, function(value: number)
		if scrollingFrame then
			scrollingFrame.CanvasPosition = Vector2.new(value, 0)
		end
	end, function() end)
	Vide.cleanup(motor.destroy)

	local updateVisibility = Dash.throttle(function(frame: ScrollingFrame)
		if frame.AbsoluteWindowSize.X == 0 then
			return
		end
		isEndOverflowVisible((frame.AbsoluteWindowSize.X + frame.CanvasPosition.X) < (frame.AbsoluteCanvasSize.X - 1))
		isStartVisible(frame.CanvasPosition.X ~= 0)
	end, 0.2)

	--* Like Otter's motor, an ease starts from the motor's last value, not from where the user scrolled to.
	local function moveScrollByPixels(pixels: number)
		local frame = scrollingFrame
		if not frame then
			return
		end
		motor.setGoal(Motion.ease(frame.CanvasPosition.X + pixels, { duration = 0.2, easingStyle = Enum.EasingStyle.Quad }))
	end

	local scroll = ScrollView({
		LayoutOrder = 1,
		Size = UDim2.fromScale(1, 1),
		onCanvasPositionChanged = updateVisibility,
		onAbsoluteWindowSizeChanged = updateVisibility,
		scrollingFrameRef = function(frame: ScrollingFrame)
			scrollingFrame = frame
			updateVisibility(frame)
		end,
		selection = {
			Selectable = false,
		},
		scroll = {
			AutomaticSize = Enum.AutomaticSize.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			ScrollingDirection = Enum.ScrollingDirection.X,
			scrollBarVisibility = Visibility.None,
		},
		children = props.children,
	})
	scroll.Name = "Scroll"

	local overflowStart = OverflowButton({
		LayoutOrder = 3,
		Position = UDim2.fromScale(0, 0),
		size = props.size,
		ZIndex = 2,
		Visible = isStartVisible,
		onActivated = function()
			moveScrollByPixels(-SCROLL_STEP)
		end,
		gradient = START_GRADIENT,
		tag = "padding-right-small",
		icon = IconName.ChevronLargeLeft,
		testId = `{props.testId}--overflow-start`,
	})
	overflowStart.Name = "OverflowStart"

	local overflowEnd = OverflowButton({
		LayoutOrder = 4,
		Position = UDim2.fromScale(1, 0),
		size = props.size,
		ZIndex = 2,
		Visible = isEndOverflowVisible,
		onActivated = function()
			moveScrollByPixels(SCROLL_STEP)
		end,
		gradient = END_GRADIENT,
		tag = "anchor-top-right padding-left-small",
		icon = IconName.ChevronLargeRight,
		testId = `{props.testId}--overflow-end`,
	})
	overflowEnd.Name = "OverflowEnd"

	return View(withCommonProps(props, {
		tag = "auto-y",
		Size = UDim2.fromScale(1, 0),
		children = { scroll, overflowStart, overflowEnd },
	}) :: any)
end

return OverflowScrollContainer
