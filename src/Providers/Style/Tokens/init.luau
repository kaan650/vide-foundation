local RbxDesignFoundations = require("../../Packages/RbxDesignFoundations")

local ColorMode = require("../../Enums/ColorMode")
local DeprecatedTokenUtilities = require("@self/DeprecatedTokenUtilities")
local Device = require("../../Enums/Device")
local ThemeName = require("../../Enums/ThemeName")
local TokenProcessingUtilities = require("@self/TokenProcessingUtilities")
local Types = require("../../Components/Types")
local themeGenerators = require("@self/themeGenerators")

type ColorMode = ColorMode.ColorMode
type Device = Device.Device
type ThemeName = ThemeName.ThemeName
type ColorStyleValue = Types.ColorStyleValue

export type Tokens = RbxDesignFoundations.Tokens
export type TokenPath = RbxDesignFoundations.TokenPath
-- Non-string values are literals. Literals and path remaps must match the target's type or table shape.
export type TokenOverrideValue = TokenPath | Color3 | ColorStyleValue | number | UDim | UDim2
export type TokenOverrides = { [TokenPath]: TokenOverrideValue }

local function applyTokenOverrides(tokens: any, overrides: TokenOverrides): any
	for targetPath, source in overrides do
		local sourceValue = TokenProcessingUtilities.resolveTokenOverride(tokens, targetPath, source)
		if sourceValue ~= nil then
			TokenProcessingUtilities.setTokenValue(tokens, targetPath, sourceValue)
		end
	end
	return tokens
end

local function getTokens(
	colorMode: ColorMode,
	_device: Device?,
	_scaleFactor: number?,
	tokenOverrides: TokenOverrides?,
	themeName: ThemeName?
): Tokens
	--* FoundationDisableTokenScaling is live, so tokens are always generated at scale 1, console included.
	local tokens = themeGenerators.getGenerator(themeName or ThemeName.Default, colorMode)(1)

	local filteredTokens = {
		Color = tokens.Color,
		Config = tokens.Config,
		DarkMode = tokens.DarkMode,
		Ease = tokens.Ease,
		LightMode = tokens.LightMode,
		Inverse = tokens.Inverse,
		Size = tokens.Size,
		Padding = tokens.Padding,
		Margin = tokens.Margin,
		Gap = tokens.Gap,
		Gutter = tokens.Gutter,
		Radius = tokens.Radius,
		Stroke = tokens.Stroke,
		LineHeight = tokens.LineHeight,
		FontSize = tokens.FontSize,
		FontWeight = tokens.FontWeight,
		Time = tokens.Time,
		Typography = tokens.Typography,
	}

	if tokenOverrides then
		applyTokenOverrides(filteredTokens, tokenOverrides)
	end

	--* FoundationRemoveDeprecatedSemanticTokens is off: the old Semantic names are still built from the new tokens.
	(filteredTokens :: any).Semantic = DeprecatedTokenUtilities.getDeprecatedSemanticTokens(filteredTokens, 1)

	return (filteredTokens :: any) :: Tokens
end

local defaultTokens = getTokens(ColorMode.Dark, Device.Desktop)

return {
	getTokens = getTokens,
	defaultTokens = defaultTokens,
}
