local BuilderIcons = require("../Packages/BuilderIcons")

--- The Builder Icon for `keycode` on the current input platform, or nil when BuilderIcons has none.
local function getBuilderIconForKeycode(keycode: Enum.KeyCode): string?
	local success, icon = pcall(BuilderIcons.getBuilderIconForKeycode, keycode)
	return if success then icon else nil
end

return getBuilderIconForKeycode
