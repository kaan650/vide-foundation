local Vide = require("../../Packages/Vide")

export type Preferences = {
	preferredTextSize: Enum.PreferredTextSize,
	preferredTransparency: number,
	reducedMotion: boolean,
}

local DEFAULT_PREFERENCES: Preferences = {
	preferredTextSize = Enum.PreferredTextSize.Medium,
	preferredTransparency = 1,
	reducedMotion = false,
}

local function defaultPreferences(): Preferences
	return DEFAULT_PREFERENCES
end

return {
	context = Vide.context(defaultPreferences :: () -> Preferences),
	DEFAULT_PREFERENCES = DEFAULT_PREFERENCES,
}
