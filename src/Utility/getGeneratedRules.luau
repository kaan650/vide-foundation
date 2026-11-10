local ColorMode = require("../Enums/ColorMode")
local Device = require("../Enums/Device")
local FontName = require("../Enums/FontName")
local ThemeName = require("../Enums/ThemeName")

type ColorMode = ColorMode.ColorMode
type Device = Device.Device
type ThemeName = ThemeName.ThemeName

local TypographyVariants: { [ThemeName]: string } = require("../Generated/StyleRules/TypographyVariants") :: any

local function commonRules(): any
	return require("../Generated/StyleRules/CommonAttribute")
end

local function sizeRules(): any
	return require("../Generated/StyleRules/DesktopAttribute")
end

-- Color rules are baked per theme, so they are keyed by ThemeName then ColorMode.
local colorRulePaths: { [ThemeName]: { [ColorMode]: () -> any } } = {
	[ThemeName.CircuitRush] = {
		Dark = function()
			return require("../Generated/StyleRules/CircuitRush/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/CircuitRush/LightAttribute")
		end,
	},
	[ThemeName.Classic] = {
		Dark = function()
			return require("../Generated/StyleRules/Classic/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/Classic/LightAttribute")
		end,
	},
	[ThemeName.CosmicDust] = {
		Dark = function()
			return require("../Generated/StyleRules/CosmicDust/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/CosmicDust/LightAttribute")
		end,
	},
	[ThemeName.Default] = {
		Dark = function()
			return require("../Generated/StyleRules/Default/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/Default/LightAttribute")
		end,
	},
	[ThemeName.ElectricLime] = {
		Dark = function()
			return require("../Generated/StyleRules/ElectricLime/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/ElectricLime/LightAttribute")
		end,
	},
	[ThemeName.HyperPlum] = {
		Dark = function()
			return require("../Generated/StyleRules/HyperPlum/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/HyperPlum/LightAttribute")
		end,
	},
	[ThemeName.InfernoBlast] = {
		Dark = function()
			return require("../Generated/StyleRules/InfernoBlast/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/InfernoBlast/LightAttribute")
		end,
	},
	[ThemeName.Kids] = {
		Dark = function()
			return require("../Generated/StyleRules/Kids/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/Kids/LightAttribute")
		end,
	},
	[ThemeName.KidsClassic] = {
		Dark = function()
			return require("../Generated/StyleRules/KidsClassic/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/KidsClassic/LightAttribute")
		end,
	},
	[ThemeName.KineticEnergy] = {
		Dark = function()
			return require("../Generated/StyleRules/KineticEnergy/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/KineticEnergy/LightAttribute")
		end,
	},
	[ThemeName.LavaGlow] = {
		Dark = function()
			return require("../Generated/StyleRules/LavaGlow/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/LavaGlow/LightAttribute")
		end,
	},
	[ThemeName.NebulaDrift] = {
		Dark = function()
			return require("../Generated/StyleRules/NebulaDrift/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/NebulaDrift/LightAttribute")
		end,
	},
	[ThemeName.NitroFrost] = {
		Dark = function()
			return require("../Generated/StyleRules/NitroFrost/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/NitroFrost/LightAttribute")
		end,
	},
	[ThemeName.PixelPop] = {
		Dark = function()
			return require("../Generated/StyleRules/PixelPop/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/PixelPop/LightAttribute")
		end,
	},
	[ThemeName.PolarFreeze] = {
		Dark = function()
			return require("../Generated/StyleRules/PolarFreeze/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/PolarFreeze/LightAttribute")
		end,
	},
	[ThemeName.QuantumPulse] = {
		Dark = function()
			return require("../Generated/StyleRules/QuantumPulse/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/QuantumPulse/LightAttribute")
		end,
	},
	[ThemeName.StarBurst] = {
		Dark = function()
			return require("../Generated/StyleRules/StarBurst/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/StarBurst/LightAttribute")
		end,
	},
	[ThemeName.SuperCharge] = {
		Dark = function()
			return require("../Generated/StyleRules/SuperCharge/DarkAttribute")
		end,
		Light = function()
			return require("../Generated/StyleRules/SuperCharge/LightAttribute")
		end,
	},
}

local DEFAULT_TYPOGRAPHY_VARIANT = FontName.BuilderSans

local typographyVariantPaths: { [string]: { Desktop: () -> any } } = {
	[FontName.BuilderSans] = {
		Desktop = function()
			return require("../Generated/StyleRules/Typography/BuilderSans/DesktopAttribute")
		end,
	},
	[FontName.Cartoon] = {
		Desktop = function()
			return require("../Generated/StyleRules/Typography/Cartoon/DesktopAttribute")
		end,
	},
}

--* FoundationDisableTokenScaling is live, so console uses the desktop size and typography rules.
local function getGeneratedRules(themeNameInput: ThemeName?, colorMode: ColorMode, _device: Device?): any
	local themeName: ThemeName = themeNameInput or ThemeName.Default
	local themeColorPaths = colorRulePaths[themeName] or colorRulePaths[ThemeName.Default]

	local combinedRules: { [string]: any } = table.clone(sizeRules())
	for key, value in commonRules() :: { [string]: any } do
		combinedRules[key] = value
	end
	for key, value in themeColorPaths[colorMode]() :: { [string]: any } do
		combinedRules[key] = value
	end

	local variant = TypographyVariants[themeName] or DEFAULT_TYPOGRAPHY_VARIANT
	local variantPaths = typographyVariantPaths[variant] or typographyVariantPaths[DEFAULT_TYPOGRAPHY_VARIANT]
	for key, value in variantPaths.Desktop() :: { [string]: any } do
		combinedRules[key] = value
	end

	return combinedRules
end

return getGeneratedRules
