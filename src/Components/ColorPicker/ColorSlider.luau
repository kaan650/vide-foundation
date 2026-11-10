local ColorSliderType = require("../../Enums/ColorSliderType")
local Image = require("../Image")
local InputSize = require("../../Enums/InputSize")
local Knob = require("../Knob")
local Slider = require("../Slider")
local SliderVariant = require("../../Enums/SliderVariant")
local Types = require("../Types")
local View = require("../View")
local Visibility = require("../../Enums/Visibility")
local create = require("../../Utility/create")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")

type ColorSliderType = ColorSliderType.ColorSliderType
type ColorStyleValue = Types.ColorStyleValue

export type ColorSliderProps = {
	sliderType: ColorSliderType?,
	value: () -> number,
	onValueChanged: ((newValue: number) -> ())?,
	onDragStarted: (() -> ())?,
	onDragEnded: (() -> ())?,
	baseColor: (() -> Color3)?,
} & Types.CommonProps

local RAINBOW_GRADIENT = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
	ColorSequenceKeypoint.new(1 / 6, Color3.new(1, 1, 0)),
	ColorSequenceKeypoint.new(2 / 6, Color3.new(0, 1, 0)),
	ColorSequenceKeypoint.new(3 / 6, Color3.new(0, 1, 1)),
	ColorSequenceKeypoint.new(4 / 6, Color3.new(0, 0, 1)),
	ColorSequenceKeypoint.new(5 / 6, Color3.new(1, 0, 1)),
	ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0)),
})

local ALPHA_TRANSPARENCY = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0),
})

local CHECKERBOARD_IMAGE = "component_assets/checkerboard_12"
local WHITE = Color3.new(1, 1, 1)

local function white(): Color3
	return WHITE
end

--- A pill slider over a hue rainbow, or over a checkerboard fading in `baseColor` for alpha.
local function ColorSlider(props: ColorSliderProps): GuiObject
	local tokens = useTokens()
	local isAlpha = props.sliderType == ColorSliderType.Alpha
	local value = props.value
	local baseColor = props.baseColor or white

	local knobStyle: () -> ColorStyleValue = if isAlpha
		then function()
			return {
				Color3 = baseColor(),
				Transparency = 1 - value(),
			}
		end
		else function()
			return {
				Color3 = Color3.fromHSV(value(), 1, 1),
				Transparency = 0,
			}
		end

	local slider = Slider({
		value = value,
		onValueChanged = props.onValueChanged,
		onDragStarted = props.onDragStarted,
		onDragEnded = props.onDragEnded,
		size = InputSize.Medium,
		variant = SliderVariant.Utility,
		isContained = true,
		width = UDim.new(1, 0),
		knobVisibility = Visibility.Always,
		knob = Knob({
			size = InputSize.Small,
			style = knobStyle,
			stroke = function(): Types.Stroke
				local current = tokens()
				return {
					Color = current.Color.System.Contrast.Color3,
					Thickness = current.Stroke.Thicker,
					Transparency = current.Color.System.Contrast.Transparency,
				}
			end,
			hasShadow = true,
			isStyleBinding = true,
		}),
	})
	slider.Name = "Slider"

	if isAlpha then
		local checkerboard = Image({
			Image = CHECKERBOARD_IMAGE,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = function()
				local size = tokens().Size.Size_300
				return UDim2.fromOffset(size, size)
			end,
			cornerRadius = UDim.new(1, 0),
			tag = "size-full",
			ZIndex = 1,
		})
		checkerboard.Name = "Checkerboard"

		local gradientOverlay = View({
			tag = "size-full",
			backgroundStyle = {
				Color3 = WHITE,
				Transparency = 0,
			},
			cornerRadius = UDim.new(1, 0),
			ZIndex = 2,
			children = create("UIGradient")({
				Name = "Gradient",
				Color = function()
					local color = baseColor()
					return ColorSequence.new({ ColorSequenceKeypoint.new(0, color), ColorSequenceKeypoint.new(1, color) })
				end,
				Transparency = ALPHA_TRANSPARENCY,
			}),
		})
		gradientOverlay.Name = "GradientOverlay"

		--* Background and SliderContainer are split so ClipsDescendants hides the checkerboard's edges without clipping
		--* the knob.
		local background = View({
			tag = "size-full stroke-standard stroke-emphasis radius-circle",
			ClipsDescendants = true,
			ZIndex = 1,
			children = { checkerboard, gradientOverlay },
		})
		background.Name = "Background"

		local sliderContainer = View({
			tag = "row align-y-center size-full",
			ZIndex = 2,
			children = slider,
		})
		sliderContainer.Name = "SliderContainer"

		return View(withCommonProps(props, {
			tag = "size-full-300",
			children = { background, sliderContainer },
		}) :: any)
	end

	return View(withCommonProps(props, {
		tag = "row align-y-center size-full-300 stroke-standard stroke-emphasis radius-circle",
		backgroundStyle = function()
			return tokens().Color.Extended.White.White_100
		end,
		children = {
			create("UIGradient")({
				Name = "Gradient",
				Color = RAINBOW_GRADIENT,
			}),
			slider,
		},
	}) :: any)
end

return ColorSlider
