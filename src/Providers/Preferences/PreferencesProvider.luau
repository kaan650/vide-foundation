local Vide = require("../../Packages/Vide")

local PreferencesContext = require("./PreferencesContext")
local Value = require("../../Utility/Value")
local Types = require("../../Components/Types")
type Preferences = PreferencesContext.Preferences
type Value<T> = Types.Value<T>

export type PreferencesProps = {
	preferredTextSize: Enum.PreferredTextSize?,
	preferredTransparency: number?,
	reducedMotion: boolean?,
	scale: number?,
}

export type PreferencesProviderProps = {
	preferences: Value<PreferencesProps?>?,
	children: (() -> any)?,
}

local function PreferencesProvider(props: PreferencesProviderProps)
	local defaults = PreferencesContext.DEFAULT_PREFERENCES
	local preferences = Vide.derive(function(): Preferences
		local given: PreferencesProps = Value.read(props.preferences) or {}
		return {
			preferredTextSize = given.preferredTextSize or defaults.preferredTextSize,
			preferredTransparency = given.preferredTransparency or defaults.preferredTransparency,
			reducedMotion = if given.reducedMotion ~= nil then given.reducedMotion else defaults.reducedMotion,
		}
	end)

	return PreferencesContext.context(preferences, function()
		return if props.children then props.children() else nil
	end)
end

return PreferencesProvider
