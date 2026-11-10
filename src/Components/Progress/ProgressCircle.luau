local Vide = require("../../Packages/Vide")

local Constants = require("./constants")
local Image = require("../Image")
local Text = require("../Text")
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
type FontStyle = Types.FontStyle
type Value<T> = Types.Value<T>

export type ProgressCircleProps = {
	shape: typeof(ProgressShape.Circle),
	size: Value<ProgressSize>?,
	-- Progress from 0 to 100. Without it the circle spins.
	value: Value<number?>?,
} & Types.CommonProps

local defaultProps = {
	size = ProgressSize.Medium,
}

local RADIAL_FILL_IMAGE = "rbxasset://textures/ui/Controls/RadialFill.png"

--* RadialFill.png bakes a 5px ring into a 58px circle, so anything on the ring is sized as a fraction of the circle.
local RING_IMAGE_DIAMETER = 58
local RING_IMAGE_THICKNESS = 5
local RING_THICKNESS_SCALE = RING_IMAGE_THICKNESS / RING_IMAGE_DIAMETER
local CAP_CENTER_SCALE = RING_THICKNESS_SCALE / 2
local CAP_Z_INDEX = 2

-- The spinner rotates the whole circle, so its arc length is fixed.
local INDETERMINATE_ARC_FRACTION = 0.8

local function getRotationFromProgress(progress: number?, side: Enum.HorizontalAlignment): number
	local minRotation = if side == Enum.HorizontalAlignment.Left then 180 else 0
	local maxRotation = if side == Enum.HorizontalAlignment.Left then 360 else 180
	return if progress == nil then 0 else math.clamp(progress * 360, minRotation, maxRotation)
end

local function getLabelFromProgress(progress: number?): string
	return if progress == nil then "0%" else `{math.floor(progress * 100)}%`
end

type RingProps = {
	progress: () -> number?,
	isIndeterminate: () -> boolean,
	pulse: (() -> number)?,
	hasCaps: () -> boolean,
	testId: string?,
}

--* A UIGradient cuts along a straight line, so the swept arc ends flat. An opaque circle the width of the ring, turned
--* to the arc's end around the circle's center, rounds it off.
local function ArcCap(name: string, angle: () -> number, isVisible: () -> boolean, testId: string): GuiObject
	local tokens = useTokens()

	local cap = View({
		Position = UDim2.fromScale(0.5, CAP_CENTER_SCALE),
		Size = UDim2.fromScale(RING_THICKNESS_SCALE, RING_THICKNESS_SCALE),
		backgroundStyle = function(): ColorStyleValue
			return tokens().Color.Content.Emphasis :: ColorStyleValue
		end,
		tag = "anchor-center-center radius-circle",
		ZIndex = CAP_Z_INDEX,
	})
	cap.Name = "Cap"

	local wrapper = View({
		Size = UDim2.fromScale(1, 1),
		Rotation = angle,
		Visible = isVisible,
		ZIndex = CAP_Z_INDEX,
		testId = testId,
		children = cap,
	})
	wrapper.Name = name
	return wrapper
end

local function ProgressGradient(side: Enum.HorizontalAlignment, props: RingProps): UIGradient
	local tokens = useTokens()
	local preferences = usePreferences()
	local pulse = props.pulse

	local function pulseValue(): number?
		if pulse and props.isIndeterminate() and preferences().reducedMotion then
			return pulse()
		end
		return nil
	end

	return create("UIGradient")({
		Name = "Gradient",
		Transparency = function()
			local color = tokens().Color
			local fillTransparency = color.Content.Emphasis.Transparency
			local trackTransparency = color.Shift.Shift_200.Transparency
			local pulsed = pulseValue()
			if pulsed then
				return NumberSequence.new(math.lerp(fillTransparency, trackTransparency, pulsed))
			end
			if props.isIndeterminate() then
				trackTransparency = 1
			end
			return NumberSequence.new({
				NumberSequenceKeypoint.new(0, fillTransparency),
				NumberSequenceKeypoint.new(0.4999, fillTransparency),
				NumberSequenceKeypoint.new(0.5, trackTransparency),
				NumberSequenceKeypoint.new(1, trackTransparency),
			})
		end,
		Color = function()
			local color = tokens().Color
			local fill = color.Content.Emphasis.Color3
			local track = color.Shift.Shift_200.Color3
			local pulsed = pulseValue()
			if pulsed then
				return ColorSequence.new(fill:Lerp(track, pulsed))
			end
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, fill),
				ColorSequenceKeypoint.new(0.4999, fill),
				ColorSequenceKeypoint.new(0.5, track),
				ColorSequenceKeypoint.new(1, track),
			})
		end,
		Rotation = function()
			if pulseValue() then
				return if side == Enum.HorizontalAlignment.Left then 0 else 180
			end
			return getRotationFromProgress(props.progress(), side)
		end,
	})
end

--* Each half clips its own copy of the RadialFill ring, because one swept gradient cannot cover 360 degrees.
local function ProgressRing(props: RingProps): { any }
	local function half(name: string, side: Enum.HorizontalAlignment): GuiObject
		local isLeft = side == Enum.HorizontalAlignment.Left
		local image = Image({
			Image = RADIAL_FILL_IMAGE,
			Size = UDim2.fromScale(2, 1),
			Position = if isLeft then nil else UDim2.fromScale(-1, 0),
			tag = if isLeft then "position-top-left content-emphasis" else "content-emphasis",
			children = ProgressGradient(side, props),
		})
		image.Name = "Image"

		local container = View({
			Size = UDim2.fromScale(0.5, 1),
			tag = if isLeft then "position-top-left clip" else "position-top-center clip",
			testId = `{props.testId}--{if isLeft then "left" else "right"}-gradient`,
			children = image,
		})
		container.Name = name
		return container
	end

	local function isVisible(): boolean
		return (props.progress() or 0) > 0
	end

	return {
		half("LeftGradient", Enum.HorizontalAlignment.Left),
		half("RightGradient", Enum.HorizontalAlignment.Right),
		Vide.show(props.hasCaps, function()
			return {
				ArcCap("StartCap", function()
					return 0
				end, isVisible, `{props.testId}--start-cap`),
				ArcCap("EndCap", function()
					return math.clamp(props.progress() or 0, 0, 1) * 360
				end, isVisible, `{props.testId}--end-cap`),
			}
		end),
	}
end

--- A circular progress ring, with a percentage label at the Large size.
local function ProgressCircle(progressProps: ProgressCircleProps): GuiObject
	local props = withDefaults(progressProps, defaultProps)
	local tokens = useTokens()
	local preferences = usePreferences()
	local variants = Vide.derive(function()
		return useProgressVariants(tokens(), Value.read(props.size))
	end)
	local progress, isIndeterminate = useProgressBinding(props.value)
	local rotation = useRotation(1)
	local pulse = usePulseBinding(1 / Constants.INDETERMINATE_SHIMMER_SPEED)

	local function circleSize(): UDim2
		local size = variants().circle.size
		return UDim2.fromOffset(size, size)
	end

	local isSpinning = Vide.derive(function()
		return isIndeterminate() and not preferences().reducedMotion
	end)

	local content = Vide.switch(function()
		return if isSpinning() then "spinning" else "ring"
	end)({
		--* Rotating an element inside a list layout does not rotate it, so the spinner has its own wrapper.
		spinning = function()
			local container = View({
				Size = circleSize,
				Rotation = rotation,
				testId = `{props.testId}--indeterminate-container`,
				children = ProgressRing({
					progress = function()
						return INDETERMINATE_ARC_FRACTION
					end,
					isIndeterminate = function()
						return true
					end,
					hasCaps = function()
						return true
					end,
					testId = props.testId,
				}),
			})
			container.Name = "IndeterminateContainer"
			return container
		end,
		ring = function()
			return {
				ProgressRing({
					progress = progress,
					isIndeterminate = isIndeterminate,
					pulse = pulse,
					--* A reduced-motion indeterminate ring pulses as a whole, so it has no arc ends to round.
					hasCaps = function()
						return not isIndeterminate()
					end,
					testId = props.testId,
				}),
				Vide.show(function()
					return variants().circle.labelFont ~= nil and not isIndeterminate()
				end, function()
					local label = Text({
						Text = function()
							return getLabelFromProgress(progress())
						end,
						fontStyle = function(): FontStyle?
							return variants().circle.labelFont
						end,
						tag = "position-center-center anchor-center-center",
						testId = `{props.testId}--label`,
					})
					label.Name = "ProgressLabel"
					return label
				end),
			}
		end,
	})

	return View(withCommonProps(props, {
		tag = function()
			return if isSpinning() then "auto-xy" else nil
		end,
		children = {
			Value.bindProperty("Size", function(): UDim2?
				return if isSpinning() then nil else circleSize()
			end),
			content,
		},
	}) :: any)
end

return ProgressCircle
