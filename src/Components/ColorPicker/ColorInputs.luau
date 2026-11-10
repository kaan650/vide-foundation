local Vide = require("../../Packages/Vide")

local ColorInputMode = require("../../Enums/ColorInputMode")
local Dropdown = require("../Dropdown")
local InputSize = require("../../Enums/InputSize")
local NumberInput = require("../NumberInput")
local NumberInputControlsVariant = require("../../Enums/NumberInputControlsVariant")
local TextInput = require("../TextInput")
local Types = require("../Types")
local View = require("../View")
local colorInputUtils = require("./colorInputUtils")
local colorUtils = require("./colorUtils")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")

type ColorInputMode = ColorInputMode.ColorInputMode
type DropdownItem = Dropdown.DropdownItem
type ItemId = Types.ItemId
type PartialColorHSV = Types.PartialColorHSV
type Config = colorInputUtils.Config
type RawRGB = colorInputUtils.RawRGB
type RawHSV = colorInputUtils.RawHSV

local EMPTY_CHANNEL_VALUE = -1
local RGB_MAX_VALUE = 255

export type ColorInputsProps = {
	color: () -> Color3 | PartialColorHSV,
	alpha: (() -> number)?,
	onColorChanged: (color: Color3) -> (),
	onAlphaChanged: ((alpha: number) -> ())?,
	mode: () -> ColorInputMode,
	onModeChanged: ((mode: ColorInputMode) -> ())?,
	availableModes: () -> { ColorInputMode },
} & Types.CommonProps

local function defaultAlpha(): number
	return 1
end

local function formatNumber(value: number): string
	return tostring(value)
end

local function noop() end

-- A nil value is a partial HSV's missing channel, shown empty.
local function numberInput(config: Config, index: number, testId: string): GuiObject
	--! Each input gets its own derived value. NumberInput reacts to a shared source badly under immediate signals:
	--! when its Text binding runs before its own sync effect, the TextBox handler writes the binding's dependency
	--! during the binding, Vide errors inside the signal and drops the rest of the update.
	local channel = Vide.derive(function()
		return config.value()
	end)
	local function isEmpty(): boolean
		return channel() == nil
	end

	local input = NumberInput({
		value = function(): number
			local value = channel()
			return if value == nil then EMPTY_CHANNEL_VALUE else value
		end,
		onChanged = function(value: number)
			if Vide.untrack(isEmpty) and value == EMPTY_CHANNEL_VALUE then
				return
			end
			config.handler(value, config.component)
		end,
		controlsVariant = NumberInputControlsVariant.None,
		minimum = config.minimum or 0,
		maximum = config.maximum or 255,
		step = config.step or 1,
		precision = config.precision or 0,
		formatAsString = function(value: number): string
			return if isEmpty() then "" else formatNumber(value)
		end,
		size = InputSize.XSmall,
		label = "",
		width = UDim.new(1, 0),
		LayoutOrder = index,
		testId = testId,
	})
	input.Name = "Input"
	return input
end

local function renderInput(config: Config, index: number, mode: string, testId: string): GuiObject
	local configKey = if mode == config.key:lower() then "" else `-{config.key:lower()}`
	local inputTestId = `{testId}-{mode}{configKey}`

	local input: GuiObject
	if config.key == ColorInputMode.Hex then
		input = TextInput({
			text = config.value,
			onChanged = function(text: string)
				config.handler(text, config.component)
			end,
			placeholder = config.placeholder or "#000000",
			size = InputSize.XSmall,
			label = "",
			width = UDim.new(1, 0),
			testId = inputTestId,
		})
		input.Name = "Input"
	else
		input = numberInput(config, index, inputTestId)
	end

	-- grow-1: the inputs share the width left of the dropdown equally.
	local wrapper = View({
		tag = "grow-1 size-0-full",
		LayoutOrder = index,
		children = input,
	})
	wrapper.Name = `{config.key}Input`
	return wrapper
end

--- The mode dropdown and the text inputs of the current mode (RGB, RGBA, HSV, Hex or the brick color's name).
local function ColorInputs(props: ColorInputsProps): GuiObject
	local tokens = useTokens()
	local testId: string = props.testId or ""
	local color = props.color
	local alpha = props.alpha or defaultAlpha
	local mode = props.mode
	local showAlpha = props.onAlphaChanged ~= nil

	local function onColorChanged(newColor: Color3)
		props.onColorChanged(newColor)
	end

	local rgbValues = Vide.derive(function(): RawRGB
		local value = color()
		if colorUtils.isPartialHSV(value) then
			return { r = nil, g = nil, b = nil }
		end
		local currentColor = colorUtils.toColor3(value)
		return {
			r = math.round(currentColor.R * RGB_MAX_VALUE),
			g = math.round(currentColor.G * RGB_MAX_VALUE),
			b = math.round(currentColor.B * RGB_MAX_VALUE),
		}
	end)

	local hsvValues = Vide.derive(function(): RawHSV
		local value = color()
		if typeof(value) ~= "Color3" then
			return { h = value.H, s = value.S, v = value.V }
		end
		local h, s, v = value:ToHSV()
		return {
			h = math.round(h * 360),
			s = math.round(s * 100),
			v = math.round(v * 100),
		}
	end)

	local function hexValue(): string
		local values = rgbValues()
		if values.r ~= nil and values.g ~= nil and values.b ~= nil then
			return string.format("#%02X%02X%02X", values.r, values.g, values.b)
		end
		return ""
	end

	local function handleRGBChange(value: number, component: string?)
		local clampedValue = math.clamp(value, 0, RGB_MAX_VALUE)
		local rgb: { [string]: number? } = table.clone(Vide.untrack(rgbValues)) :: any
		rgb[component :: string] = clampedValue

		local r, g, b = rgb.r, rgb.g, rgb.b
		if r == nil or g == nil or b == nil then
			return
		end
		onColorChanged(Color3.fromRGB(r, g, b))
	end

	local function handleAlphaChange(value: number)
		if props.onAlphaChanged then
			props.onAlphaChanged(value)
		end
	end

	local function handleHSVChange(value: number, component: string?)
		local hsv: { [string]: number? } = table.clone(Vide.untrack(hsvValues)) :: any
		-- NumberInput commits 0 on blur; ignore it so an empty partial HSV channel stays empty.
		if hsv[component :: string] == nil and value == 0 then
			return
		end
		hsv[component :: string] = math.clamp(value, 0, if component == "h" then 360 else 100)

		onColorChanged(Color3.fromHSV((hsv.h :: number) / 360, (hsv.s or 100) / 100, (hsv.v or 100) / 100))
	end

	local function handleHexChange(value: string)
		local cleanHex = value:gsub("#", ""):upper()
		--* The hex field's own Text binding dispatches onChanged too. React commits that echo, snapping the color to
		--* 8-bit RGB and resetting H/S/V after every drag in Hex mode; it is dropped here.
		if `#{cleanHex}` == Vide.untrack(hexValue) then
			return
		end

		if cleanHex:match("^%x%x%x%x%x%x$") then
			local r = tonumber(cleanHex:sub(1, 2), 16)
			local g = tonumber(cleanHex:sub(3, 4), 16)
			local b = tonumber(cleanHex:sub(5, 6), 16)

			if r and g and b then
				onColorChanged(Color3.fromRGB(r, g, b))
			end
		end
	end

	local dropdownOptions = Vide.derive(function(): { DropdownItem }
		local allOptions: { DropdownItem } = {
			{ id = ColorInputMode.RGB, text = ColorInputMode.RGB },
			{ id = ColorInputMode.HSV, text = ColorInputMode.HSV },
			{ id = ColorInputMode.Hex, text = ColorInputMode.Hex },
			{ id = ColorInputMode.Brick, text = ColorInputMode.Brick },
		}

		if showAlpha then
			table.insert(allOptions, 2, { id = ColorInputMode.RGBA, text = ColorInputMode.RGBA })
		end

		local availableModes = props.availableModes()
		local filteredOptions: { DropdownItem } = {}
		for _, option in allOptions do
			local modeId = option.id
			for _, availableMode in availableModes do
				local shouldInclude = modeId == availableMode
					or (modeId == ColorInputMode.RGBA and availableMode == ColorInputMode.RGB and showAlpha)

				if shouldInclude then
					table.insert(filteredOptions, option)
					break
				end
			end
		end
		return filteredOptions
	end)

	local modeDropdown = Vide.show(function()
		return #dropdownOptions() > 1
	end, function()
		return Dropdown.Root({
			items = function()
				return dropdownOptions() :: any
			end,
			value = function(): ItemId?
				return mode()
			end,
			onItemChanged = function(newMode: ItemId)
				if props.onModeChanged then
					props.onModeChanged(newMode :: ColorInputMode)
				end
			end,
			size = InputSize.XSmall,
			label = "",
			-- ~64px, fits "RGB" and the chevron.
			width = function()
				return UDim.new(0, tokens().Size.Size_1600)
			end,
			testId = `{testId}--mode-dropdown`,
		})
	end)

	local configs = colorInputUtils.createInputConfigs(
		rgbValues,
		hsvValues,
		hexValue,
		alpha,
		handleRGBChange,
		handleHSVChange,
		handleHexChange,
		handleAlphaChange
	)

	local function renderConfigs(currentMode: ColorInputMode): { GuiObject }
		local inputs = {}
		for index, config in configs[currentMode] do
			table.insert(inputs, renderInput(config, index, currentMode:lower(), testId))
		end
		return inputs
	end

	local function brickColorName(): GuiObject
		local input = TextInput({
			text = function()
				return BrickColor.new(colorUtils.toColor3(color())).Name
			end,
			onChanged = noop,
			isDisabled = true,
			size = InputSize.XSmall,
			label = "",
			width = UDim.new(1, 0),
			testId = `{testId}-brick-name`,
		})
		input.Name = "Input"
		local wrapper = View({
			tag = "grow-1 size-0-full",
			LayoutOrder = 1,
			children = input,
		})
		wrapper.Name = "BrickColorName"
		return wrapper
	end

	local inputs = Vide.switch(mode)({
		[ColorInputMode.RGB] = function()
			return renderConfigs(ColorInputMode.RGB)
		end,
		[ColorInputMode.RGBA] = function()
			return renderConfigs(ColorInputMode.RGBA)
		end,
		[ColorInputMode.HSV] = function()
			return renderConfigs(ColorInputMode.HSV)
		end,
		[ColorInputMode.Hex] = function()
			return renderConfigs(ColorInputMode.Hex)
		end,
		[ColorInputMode.Brick] = brickColorName,
	} :: any)

	return View(withCommonProps(props, {
		tag = "row gap-xsmall size-full-600",
		children = { modeDropdown, inputs },
	}) :: any)
end

return ColorInputs
