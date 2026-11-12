local Vide = require("../../Packages/Vide")

local Constants = require("./constants")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local create = require("../../Utility/create")
local getTestIdTag = require("../../Utility/getTestIdTag")
local tags = require("../../Utility/tags")
local usePreferences = require("../../Providers/Preferences/usePreferences")
local useProgressBinding = require("./useProgressBinding")
local useProgressVariants = require("./useProgressVariants")
local usePulseBinding = require("../../Utility/usePulseBinding")
local useRotation = require("../../Utility/useRotation")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local ProgressShape = require("../../Enums/ProgressShape")
local ProgressSize = require("../../Enums/ProgressSize")

type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

export type ProgressBarSize = typeof(ProgressSize.Small) | typeof(ProgressSize.Medium)

local function getFillSizeFromProgress(progress: number?): UDim2
	return UDim2.fromScale(progress or 0, 1)
end

local function getIndeterminateShimmerTransparency(
	pulseValue: number,
	reducedMotion: boolean,
	emphasisTransparency: number
): NumberSequence
	if reducedMotion then
		return NumberSequence.new(pulseValue)
	end
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 1),
		NumberSequenceKeypoint.new(0.5, emphasisTransparency),
		NumberSequenceKeypoint.new(0.8, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
end

local function getIndeterminateShimmerOffset(rotationValue: number, reducedMotion: boolean): Vector2
	if reducedMotion then
		return Vector2.zero
	end
	return Vector2.new(((rotationValue * Constants.INDETERMINATE_SHIMMER_SPEED) % 360) / 360 * 2 - 1, 0)
end

--* Its own clock, like Foundation's gradient component: the shimmer starts where it is mounted.
local function IndeterminateGradient(emphasis: () -> ColorStyleValue, testId: string): UIGradient
	local preferences = usePreferences()
	local rotation = useRotation(1)
	local pulse = usePulseBinding(1 / Constants.INDETERMINATE_SHIMMER_SPEED)

	return create("UIGradient")({
		Name = "Gradient",
		Color = function()
			return ColorSequence.new(emphasis().Color3 :: Color3)
		end,
		Transparency = function()
			return getIndeterminateShimmerTransparency(
				pulse(),
				preferences().reducedMotion,
				emphasis().Transparency :: number
			)
		end,
		Offset = function()
			return getIndeterminateShimmerOffset(rotation(), preferences().reducedMotion)
		end,
		tags(getTestIdTag(testId)),
	})
end

export type ProgressBarProps = {
	shape: typeof(ProgressShape.Bar)?,
	size: Value<ProgressBarSize>?,
	-- Progress from 0 to 100. Without it the bar shows an indeterminate shimmer.
	value: Value<number?>?,
	width: Value<UDim>?,
	-- Shows the min and max value labels below the bar (not while indeterminate).
	showLabel: Value<boolean>?,
	minValueLabel: Value<string>?,
	maxValueLabel: Value<string>?,
} & Types.CommonProps

local defaultProps = {
	size = ProgressSize.Medium :: ProgressBarSize,
	width = UDim.new(1, 0),
	showLabel = false,
	minValueLabel = "0",
	maxValueLabel = "100",
}

--- A horizontal progress bar on a rounded track, with optional value labels below it.
local function ProgressBar(progressProps: ProgressBarProps): GuiObject
	local props = withDefaults(progressProps, defaultProps)
	local tokens = useTokens()
	local variants = Vide.derive(function()
		local size = if Value.read(props.size) == ProgressSize.Small then ProgressSize.Small else ProgressSize.Medium
		return useProgressVariants(tokens(), size)
	end)
	local progress, isIndeterminate = useProgressBinding(props.value)

	local function emphasis(): ColorStyleValue
		return tokens().Color.Content.Emphasis :: ColorStyleValue
	end
	local function circleRadius(): UDim
		return UDim.new(0, tokens().Radius.Circle)
	end

	local fill = View({
		backgroundStyle = emphasis,
		cornerRadius = circleRadius,
		Size = function()
			return if isIndeterminate() then UDim2.fromScale(1, 1) else getFillSizeFromProgress(progress())
		end,
		tag = function()
			return if isIndeterminate() then "size-full" else nil
		end,
		testId = `{props.testId}--fill`,
		children = Vide.show(isIndeterminate, function()
			return IndeterminateGradient(emphasis, `{props.testId}--fill--gradient`)
		end),
	})
	fill.Name = "Fill"

	local track = View({
		Size = function()
			return UDim2.new(UDim.new(1, 0), UDim.new(0, variants().bar.height))
		end,
		cornerRadius = circleRadius,
		tag = "size-full-0 clip bg-shift-400",
		LayoutOrder = 1,
		testId = `{props.testId}--track`,
		children = fill,
	})
	track.Name = "Track"

	local function valueLabel(
		name: string,
		suffix: string,
		text: Value<string>,
		alignment: string,
		order: number
	): GuiObject
		local label = Text({
			Text = text,
			tag = `fill auto-xy text-label-medium text-align-x-{alignment} content-default`,
			LayoutOrder = order,
			testId = `{props.testId}--label-{suffix}`,
		})
		label.Name = name
		return label
	end

	local labels = Vide.show(function()
		return Value.read(props.showLabel) and not isIndeterminate()
	end, function()
		local row = View({
			tag = "row size-full-0 auto-y",
			LayoutOrder = 2,
			testId = `{props.testId}--labels`,
			children = {
				valueLabel("MinValue", "min", props.minValueLabel, "left", 1),
				valueLabel("MaxValue", "max", props.maxValueLabel, "right", 2),
			},
		})
		row.Name = "Labels"
		return row
	end)

	return View(withCommonProps(props, {
		tag = "col gap-xsmall size-full-0 auto-y",
		Size = function()
			return UDim2.new(Value.read(props.width), UDim.new(0, 0))
		end,
		children = { track, labels },
	}) :: any)
end

return ProgressBar
