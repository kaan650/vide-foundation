local Image = require("../Image")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local create = require("../../Utility/create")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type Value<T> = Types.Value<T>

export type CircularProgressBarProps = {
	-- Progress from 0 to 1.
	progress: Value<number>,
} & Types.CommonProps

local defaultProps = {
	testId = "--foundation-circular-progress-bar",
}

local RADIAL_FILL_IMAGE = "rbxasset://textures/ui/Controls/RadialFill.png"

--- A ring that fills clockwise with `progress`, sized to its parent.
local function CircularProgressBar(circularProgressBarProps: CircularProgressBarProps): GuiObject
	local props = withDefaults(circularProgressBarProps, defaultProps)
	local tokens = useTokens()

	local function transparencySequence(): NumberSequence
		local content = tokens().Color.Content
		return NumberSequence.new({
			NumberSequenceKeypoint.new(0, content.Emphasis.Transparency),
			NumberSequenceKeypoint.new(0.4999, content.Emphasis.Transparency),
			NumberSequenceKeypoint.new(0.5, content.Muted.Transparency),
			NumberSequenceKeypoint.new(1, content.Muted.Transparency),
		})
	end

	local function colorSequence(): ColorSequence
		local content = tokens().Color.Content
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, content.Emphasis.Color3),
			ColorSequenceKeypoint.new(0.4999, content.Emphasis.Color3),
			ColorSequenceKeypoint.new(0.5, content.Muted.Color3),
			ColorSequenceKeypoint.new(1, content.Muted.Color3),
		})
	end

	local function half(
		name: string,
		containerTag: string,
		minRotation: number,
		maxRotation: number,
		imageProps: { [string]: any }
	): GuiObject
		local gradient = create("UIGradient")({
			Name = "Gradient",
			Transparency = transparencySequence,
			Color = colorSequence,
			Rotation = function()
				return math.clamp(Value.read(props.progress) * 360, minRotation, maxRotation)
			end,
		})

		imageProps.Image = RADIAL_FILL_IMAGE
		imageProps.Size = UDim2.fromScale(2, 1)
		imageProps.children = gradient
		local image = Image(imageProps :: any)
		image.Name = "Image"

		local container = View({
			Size = UDim2.fromScale(0.5, 1),
			tag = containerTag,
			children = image,
		})
		container.Name = name
		return container
	end

	return View(withCommonProps(props, {
		tag = "size-full-full",
		children = {
			half("LeftGradient", "position-top-left clip", 180, 360, {
				tag = "position-top-left content-emphasis",
				testId = `{props.testId}--left-gradient`,
			}),
			half("RightGradient", "position-top-center clip", 0, 180, {
				Position = UDim2.fromScale(-1, 0),
				tag = "content-emphasis",
				testId = `{props.testId}--right-gradient`,
			}),
		},
	}) :: any)
end

return CircularProgressBar
