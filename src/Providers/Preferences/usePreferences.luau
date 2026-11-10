local PreferencesContext = require("./PreferencesContext")
type Preferences = PreferencesContext.Preferences

local function usePreferences(): () -> Preferences
	return PreferencesContext.context()
end

return usePreferences
