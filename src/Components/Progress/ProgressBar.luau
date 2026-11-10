local Vide = require("../../Packages/Vide")

local Constants = require("./constants")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local create = require("../../Utility/create")
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
type ProgressSize = ProgressSize.ProgressSize

type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

local function getBarSequenceFromProgress(progressValue: number?): NumberSequence
	local value = progressValue or 0
	if value == 0 then
		return NumberSequence.new(1)
	elseif value == 1 then
		return NumberSequence.new(0)
	end

	local keypoints = {
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(value, 0),
		NumberSequenceKeypoint.new(math.min(value + 0.001, 1), 1),
	}
	if value < 0.999 then
		table.insert(keypoints, NumberSequenceKeypoint.new(1, 1))
	end
	return NumberSequence.new(keypoints)
end

export type ProgressBarProps = {
	shape: typeof(ProgressShape.Bar)?,
	size: Value<ProgressSize>?,
	-- Progress from 0 to 100. Without it the bar shows an indeterminate shimmer.
	value: Value<number?>?,
	width: Value<UDim>?,
} & Types.CommonProps

local defaultProps = {
	size = ProgressSize.Medium,
	width = UDim.new(1, 0),
}

--- A horizontal progress bar.
local function ProgressBar(progressProps: ProgressBarProps): GuiObject
	local props = withDefaults(progressProps, defaultProps)
	local tokens = useTokens()
	local preferences = usePreferences()
	local variants = Vide.derive(function()
		return useProgressVariants(tokens(), Value.read(props.size))
	end)
	local progress, isIndeterminate = useProgressBinding(props.value)
	local rotation = useRotation(1)
	local pulse = usePulseBinding(1 / Constants.INDETERMINATE_SHIMMER_SPEED)

	local function emphasis(): ColorStyleValue
		return tokens().Color.Content.Emphasis :: ColorStyleValue
	end

	local gradient = create("UIGradient")({
		Name = "Gradient",
		Color = function()
			return ColorSequence.new(emphasis().Color3 :: Color3)
		end,
		Transparency = function()
			if not isIndeterminate() then
				return getBarSequenceFromProgress(progress())
			elseif preferences().reducedMotion then
				return NumberSequence.new(pulse())
			end
			return NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, 1),
				NumberSequenceKeypoint.new(0.5, emphasis().Transparency :: number),
				NumberSequenceKeypoint.new(0.8, 1),
				NumberSequenceKeypoint.new(1, 1),
			})
		end,
		Value.bindProperty("Offset", function(): Vector2?
			if not isIndeterminate() then
				return nil
			elseif preferences().reducedMotion then
				return Vector2.zero
			end
			return Vector2.new(((rotation() * Constants.INDETERMINATE_SHIMMER_SPEED) % 360) / 360 * 2 - 1, 0)
		end),
	})

	local fill = View({
		backgroundStyle = emphasis,
		tag = "size-full radius-small",
		testId = `{props.testId}--fill`,
		children = gradient,
	})
	fill.Name = "Fill"

	return View(withCommonProps(props, {
		tag = "radius-small bg-shift-400",
		Size = function()
			return UDim2.new(Value.read(props.width), UDim.new(0, variants().bar.height))
		end,
		children = fill,
	}) :: any)
end

return ProgressBar
