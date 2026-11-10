local Vide = require("../../Packages/Vide")

local BrickColorPicker = require("./BrickColorPicker")
local ColorInputMode = require("../../Enums/ColorInputMode")
local ColorInputs = require("./ColorInputs")
local ColorSlider = require("./ColorSlider")
local ColorSliderType = require("../../Enums/ColorSliderType")
local SVPicker = require("./SVPicker")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local colorUtils = require("./colorUtils")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ColorInputMode = ColorInputMode.ColorInputMode
type PartialColorHSV = Types.PartialColorHSV
type Value<T> = Types.Value<T>

export type ColorPickerProps = {
	-- The color shown first: a Color3, or an HSV whose missing S or V shows as empty inputs and no selection knob.
	-- A source keeps the picker in sync: a value different from the picker's current color resets it to that color.
	initialColor: Value<(Color3 | PartialColorHSV)?>?,
	initialAlpha: Value<number?>?,
	onColorChanged: (newColor: Color3, brickColor: BrickColor?) -> (),
	-- Shows the alpha slider and the RGBA mode.
	onAlphaChanged: ((newAlpha: number) -> ())?,
	onDragStarted: (() -> ())?,
	onDragEnded: (() -> ())?,
	availableModes: Value<{ ColorInputMode }?>?,

	initialMode: Value<ColorInputMode?>?,
} & Types.CommonProps

local defaultProps = {
	initialAlpha = 1,
	initialMode = ColorInputMode.RGB,
	testId = "--foundation-color-picker",
}

local DEFAULT_MODES: { ColorInputMode } =
	{ ColorInputMode.RGB, ColorInputMode.HSV, ColorInputMode.Hex, ColorInputMode.Brick }

-- Value from the Figma spec; no size token matches.
local SV_PICKER_HEIGHT = 156

--- A color picker: a saturation/value area, hue and optional alpha sliders, and text inputs whose format (RGB,
--- RGBA, HSV, Hex, Brick) a dropdown picks.
local function ColorPicker(colorPickerProps: ColorPickerProps): GuiObject
	local props = withDefaults(colorPickerProps, defaultProps)
	local tokens = useTokens()
	local testId: string = props.testId
	local showAlpha = props.onAlphaChanged ~= nil

	local function availableModes(): { ColorInputMode }
		return Value.read(props.availableModes) or DEFAULT_MODES
	end

	local function resolveColor(): Color3 | PartialColorHSV
		local initialColor: (Color3 | PartialColorHSV)? = Value.read(props.initialColor)
		return initialColor or Vide.untrack(tokens).Color.Extended.Magenta.Magenta_700.Color3 :: Color3
	end

	--* React's ColorInputs also switches RGBA without alpha to RGB in an effect. Done here: writing the mode from an
	--* effect that reads it re-enters that effect during creation and breaks Vide's update queue.
	local function resolveMode(initialMode: ColorInputMode): ColorInputMode
		local modes = Vide.untrack(availableModes)
		local mode = initialMode
		if table.find(modes, initialMode) == nil then
			warn(`ColorPicker: initialMode {initialMode} is not in availableModes. Using first available mode.`)
			mode = modes[1]
		end
		return if mode == ColorInputMode.RGBA and not showAlpha then ColorInputMode.RGB else mode
	end

	local initialColor = Vide.untrack(resolveColor)
	local initialH, initialS, initialV = colorUtils.toColor3(initialColor):ToHSV()
	local function readInitialMode(): ColorInputMode
		return Value.read(props.initialMode) :: any
	end
	local initialMode = Vide.untrack(readInitialMode)

	local color = Vide.source(initialColor)
	local currentHue = Vide.source(initialH)
	local currentSaturation = Vide.source(initialS)
	local currentValue = Vide.source(initialV)
	local alpha = Vide.source(Vide.untrack(function(): number
		return Value.read(props.initialAlpha)
	end))
	local currentMode = Vide.source(resolveMode(initialMode))

	--* A source color the picker emitted (onColorChanged written back) equals `color` and is skipped, so H/S/V keep
	--* the hue a gray or black color has lost. Any other value resets the picker as React mounting with it would.
	Vide.effect(function()
		local newColor = resolveColor()
		Vide.untrack(function()
			if newColor == color() then
				return
			end
			color(newColor)
			local h, s, v = colorUtils.toColor3(newColor):ToHSV()
			currentHue(h)
			currentSaturation(s)
			currentValue(v)
		end)
	end)

	Vide.effect(function()
		local newAlpha: number = Value.read(props.initialAlpha)
		Vide.untrack(function()
			alpha(newAlpha)
		end)
	end)

	local lastInitialMode = initialMode
	Vide.effect(function()
		local newMode = readInitialMode()
		if newMode == lastInitialMode then
			return
		end
		lastInitialMode = newMode
		Vide.untrack(function()
			currentMode(resolveMode(newMode))
		end)
	end)

	local function displayColor(): Color3
		return colorUtils.toColor3(color())
	end

	local function hasFullColor(): boolean
		return not colorUtils.isPartialHSV(color())
	end

	local isUpdatingFromHSV = { current = false }

	local function onColorChanged(newColor: Color3, brickColor: BrickColor?)
		color(newColor)
		props.onColorChanged(newColor, brickColor)
	end

	local function onAlphaChanged(newAlpha: number)
		alpha(newAlpha)
		if props.onAlphaChanged then
			props.onAlphaChanged(newAlpha)
		end
	end

	local function onBrickColorChanged(newBrickColor: BrickColor)
		onColorChanged(newBrickColor.Color, newBrickColor)
	end

	local function onCustomColorChanged(newColor: Color3)
		onColorChanged(newColor, nil)
	end

	local updateColor = colorUtils.createHSVUpdateHandler(
		currentHue,
		currentSaturation,
		currentValue,
		onCustomColorChanged,
		isUpdatingFromHSV
	)

	local onColorInputChanged = colorUtils.createColorInputChangeHandler(
		onCustomColorChanged,
		isUpdatingFromHSV,
		currentHue,
		currentSaturation,
		currentValue
	)

	local colorInputs = ColorInputs({
		color = color,
		alpha = alpha,
		onColorChanged = onColorInputChanged,
		onAlphaChanged = if showAlpha then onAlphaChanged else nil,
		mode = currentMode,
		onModeChanged = function(mode: ColorInputMode)
			currentMode(mode)
		end,
		availableModes = availableModes,
		LayoutOrder = 1,
		testId = `{testId}--input`,
	})
	colorInputs.Name = "ColorInputs"

	local function isBrickMode(): boolean
		return currentMode() == ColorInputMode.Brick
	end

	local brickPicker = Vide.show(isBrickMode, function()
		local picker = BrickColorPicker({
			selectedColor = displayColor,
			onBrickColorChanged = onBrickColorChanged,
			LayoutOrder = 2,
			testId = `{testId}--brick-picker`,
		})
		picker.Name = "BrickPicker"
		return picker
	end)

	local colorArea = Vide.show(function()
		return not isBrickMode()
	end, function()
		local svPicker = SVPicker({
			hue = currentHue,
			saturation = currentSaturation,
			value = currentValue,
			onChanged = function(newS: number, newV: number)
				updateColor(Vide.untrack(currentHue), newS, newV)
			end,
			onDragStarted = props.onDragStarted,
			onDragEnded = props.onDragEnded,
			showSelectionKnob = hasFullColor,
			testId = `{testId}--sv-picker`,
		})
		svPicker.Name = "SVPicker"

		local svPickerContainer = View({
			Size = UDim2.new(1, 0, 0, SV_PICKER_HEIGHT),
			LayoutOrder = 2,
			children = svPicker,
		})
		svPickerContainer.Name = "SVPickerContainer"

		local hueSlider = ColorSlider({
			sliderType = ColorSliderType.Hue,
			value = currentHue,
			onValueChanged = function(newH: number)
				updateColor(newH, Vide.untrack(currentSaturation), Vide.untrack(currentValue))
			end,
			onDragStarted = props.onDragStarted,
			onDragEnded = props.onDragEnded,
			LayoutOrder = 3,
			testId = `{testId}--hue-slider`,
		})
		hueSlider.Name = "HueSlider"

		return { svPickerContainer, hueSlider }
	end)

	local children: { any } = { colorInputs, brickPicker, colorArea }
	if showAlpha then
		local alphaSlider = ColorSlider({
			sliderType = ColorSliderType.Alpha,
			value = alpha,
			baseColor = displayColor,
			onValueChanged = onAlphaChanged,
			onDragStarted = props.onDragStarted,
			onDragEnded = props.onDragEnded,
			LayoutOrder = 4,
			testId = `{testId}--alpha-slider`,
		})
		alphaSlider.Name = "AlphaSlider"
		table.insert(children, alphaSlider)
	end

	return View(withCommonProps(props, {
		tag = "col gap-small size-full-0 auto-y padding-small",
		children = children,
	}) :: any)
end

return ColorPicker
