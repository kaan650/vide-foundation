local Vide = require("../../Packages/Vide")

local ColorMode = require("../../Enums/ColorMode")
local Device = require("../../Enums/Device")
local StyleSheetContext = require("./StyleSheetContext")
local StyleSheetRegistry = require("../../StyleSheet/StyleSheetRegistry")
local TagsContext = require("./TagsContext")
local TextSizeOffsetContext = require("./TextSizeOffsetContext")
local ThemeName = require("../../Enums/ThemeName")
local Tokens = require("./Tokens")
local TokensContext = require("./TokensContext")
local Value = require("../../Utility/Value")
local Types = require("../../Components/Types")
local create = require("../../Utility/create")
local getTextSizeOffset = require("../../Utility/getTextSizeOffset")
local usePreferences = require("../Preferences/usePreferences")

local read = Value.read

type ColorMode = ColorMode.ColorMode
type Device = Device.Device
type ThemeName = ThemeName.ThemeName
type Tokens = Tokens.Tokens
type TokenOverrides = Tokens.TokenOverrides
type Value<T> = Types.Value<T>

export type StyleProviderProps = {
	-- The app-level theme (Default, Kids...) to resolve tokens and styles for.
	themeName: Value<ThemeName?>?,
	-- The color mode (Light/Dark). Takes precedence over `theme`.
	colorMode: Value<ColorMode?>?,
	-- **Deprecated**. Use `colorMode`.
	theme: Value<ColorMode?>?,
	device: Value<Device?>?,
	scale: Value<number?>?,
	-- Partial token overrides applied on top of the base tokens. Keep the same table while it is in use: a new
	-- table makes a new StyleSheet.
	tokenOverrides: Value<TokenOverrides?>?,
	-- Builds the content. It runs inside the provider, so Foundation components in it find the styles.
	children: (() -> any)?,
}

local function StyleProvider(props: StyleProviderProps)
	local themeName = function(): ThemeName
		return read(props.themeName) or ThemeName.Default
	end
	local colorMode = function(): ColorMode
		return read(props.colorMode) or read(props.theme) or ColorMode.Dark
	end
	local device = function(): Device
		return read(props.device) or Device.Desktop
	end
	local scale = function(): number
		return read(props.scale) or 1
	end
	local tokenOverrides = function(): TokenOverrides?
		return read(props.tokenOverrides :: any)
	end

	local tokens = Vide.derive(function(): Tokens
		return Tokens.getTokens(colorMode(), device(), scale(), tokenOverrides(), themeName())
	end)

	local preferences = usePreferences()
	local textSizeOffset = Vide.derive(function(): number
		local _ = preferences().preferredTextSize
		return getTextSizeOffset() or 0
	end)

	local styleSheet = Vide.derive(function(): StyleSheet
		return StyleSheetRegistry.resolveStyleSheet(colorMode(), device(), scale(), tokenOverrides(), themeName())
	end)

	local requestedTags: { [string]: boolean } = {}

	-- A new sheet (theme or mode switch) gets every tag already in use, so mounted UI restyles at once.
	Vide.effect(function()
		local sheet = styleSheet()
		local tags = {}
		for tag in requestedTags do
			table.insert(tags, tag)
		end
		StyleSheetRegistry.addStyleTags(sheet, tags)
		StyleSheetRegistry.acquireStyleSheet(sheet)
		Vide.cleanup(function()
			StyleSheetRegistry.releaseStyleSheet(sheet)
		end)
	end)

	local function addStyleTags(tags: { string })
		local newTags = {}
		for _, tag in tags do
			if not requestedTags[tag] then
				requestedTags[tag] = true
				table.insert(newTags, tag)
			end
		end
		if #newTags > 0 then
			StyleSheetRegistry.addStyleTags(Vide.untrack(styleSheet), newTags)
		end
	end

	local styleSheetSource = function(): StyleSheet?
		return styleSheet()
	end

	return TokensContext(tokens, function()
		return TextSizeOffsetContext(textSizeOffset, function()
			return TagsContext(addStyleTags, function()
				return StyleSheetContext.context(styleSheetSource, function()
					return {
						create("StyleLink")({
							Name = "FoundationStyleLink",
							StyleSheet = styleSheet,
						}),
						if props.children then props.children() else nil,
					}
				end)
			end)
		end)
	end)
end

return StyleProvider
