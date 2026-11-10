local ColorMode = require("../Enums/ColorMode")
local Device = require("../Enums/Device")
local ThemeName = require("../Enums/ThemeName")
local TokenProcessingUtilities = require("../Providers/Style/Tokens/TokenProcessingUtilities")
local Tokens = require("../Providers/Style/Tokens")

type ColorMode = ColorMode.ColorMode
type Device = Device.Device
type ThemeName = ThemeName.ThemeName
type TokenOverrides = Tokens.TokenOverrides

export type OverrideAttributes = { [string]: unknown }

local function tokenPathToAttributeBase(tokenPath: string): string
	-- Convert "Color.Surface.Surface_100" to "ColorSurfaceSurface100"
	return (tokenPath:gsub("%.", ""):gsub("_", ""))
end

local function emitLeafAttributes(result: OverrideAttributes, attrBase: string, value: any)
	if type(value) == "table" then
		for key, nested in value do
			emitLeafAttributes(result, attrBase .. tostring(key), nested)
		end
	else
		result[attrBase] = value
	end
end

--- A map of StyleSheet attribute name to override value, in the form the generated rules use. Keys of `overrides`
--- are target token paths; a string value is a source token path, anything else a literal.

local function getOverrideAttributes(
	themeName: ThemeName?,
	colorMode: ColorMode,
	device: Device,
	overrides: TokenOverrides?
): OverrideAttributes
	local result: OverrideAttributes = {}

	if not overrides or not next(overrides) then
		return result
	end

	local baseTokens = Tokens.getTokens(colorMode, device, 1, nil, themeName)

	for targetPath, source in overrides do
		local sourceValue = TokenProcessingUtilities.resolveTokenOverride(baseTokens, targetPath, source)
		if sourceValue ~= nil then
			emitLeafAttributes(result, tokenPathToAttributeBase(targetPath), sourceValue)
		end
	end

	return result
end

return getOverrideAttributes
