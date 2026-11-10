local ColorInputMode = require("../../Enums/ColorInputMode")
type ColorInputMode = ColorInputMode.ColorInputMode

local RGB_MAX_VALUE = 255

export type Config = {
	key: string,
	value: () -> any,
	handler: (value: any, component: string?) -> (),
	component: string?,
	placeholder: string?,
	width: UDim?,
	minimum: number?,
	maximum: number?,
	step: number?,
	precision: number?,
}

export type RawRGB = { r: number?, g: number?, b: number? }
export type RawHSV = { h: number, s: number?, v: number? }

local function createInputConfigs(
	rgbValues: () -> RawRGB,
	hsvValues: () -> RawHSV,
	hexValue: () -> string,
	alpha: () -> number,
	handleRGBChange: (value: number, component: string?) -> (),
	handleHSVChange: (value: number, component: string?) -> (),
	handleHexChange: (value: string) -> (),
	handleAlphaChange: (value: number) -> ()
): { [ColorInputMode]: { Config } }
	local rgbConfig: { Config } = {}
	for _, key in { "R", "G", "B" } do
		local component = key:lower()
		table.insert(rgbConfig, {
			key = key,
			component = component,
			value = function()
				return (rgbValues() :: any)[component]
			end,
			handler = handleRGBChange,
			minimum = 0,
			maximum = RGB_MAX_VALUE,
			step = 1,
		})
	end

	local rgbaConfig = table.clone(rgbConfig)
	table.insert(rgbaConfig, {
		key = "A",
		value = alpha,
		handler = handleAlphaChange,
		minimum = 0,
		maximum = 1,
		step = 0.01,
		precision = 3,
	})

	local hsvConfig: { Config } = {}
	for _, key in { "H", "S", "V" } do
		local component = key:lower()
		table.insert(hsvConfig, {
			key = key,
			component = component,
			value = function()
				return (hsvValues() :: any)[component]
			end,
			handler = handleHSVChange,
			minimum = 0,
			maximum = if key == "H" then 360 else nil,
		})
	end

	local hexConfig: { Config } = {
		{
			key = ColorInputMode.Hex,
			value = hexValue,
			handler = handleHexChange,
			placeholder = "#000000",
			width = UDim.new(1, 0),
		},
	}

	return {
		[ColorInputMode.RGB] = rgbConfig,
		[ColorInputMode.RGBA] = rgbaConfig,
		[ColorInputMode.HSV] = hsvConfig,
		[ColorInputMode.Hex] = hexConfig,
	}
end

return {
	createInputConfigs = createInputConfigs,
}
