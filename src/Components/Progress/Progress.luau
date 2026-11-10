local ProgressBar = require("./ProgressBar")
local ProgressCircle = require("./ProgressCircle")
local withDefaults = require("../../Utility/withDefaults")

local ProgressShape = require("../../Enums/ProgressShape")

export type ProgressBarProps = ProgressBar.ProgressBarProps
export type ProgressCircleProps = ProgressCircle.ProgressCircleProps

--* `shape` picks the component, so it is a plain value fixed for the life of the progress.
export type ProgressProps = ProgressBarProps | ProgressCircleProps

local defaultProps = {
	testId = "--foundation-progress",
}

--- A progress bar or circle. Without a `value` it shows an indeterminate animation.
local function Progress(progressProps: ProgressProps): GuiObject
	local props = withDefaults(progressProps, defaultProps)
	if props.shape == ProgressShape.Circle then
		return ProgressCircle(props :: ProgressCircleProps)
	end
	return ProgressBar(props :: ProgressBarProps)
end

return Progress
