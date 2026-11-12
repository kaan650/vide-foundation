local InputPlatform = require("../../Enums/InputPlatform")
local KeyCodeIconMappings = require("./KeyCodeIconMappings")

type InputPlatform = InputPlatform.InputPlatform

--- The Builder Icon for `keyCode` on `platform`, or nil when the key has none and should be drawn as text. Taking
--- the platform as an argument keeps the device probes out of per-key lookups.
local function getIconForKeyCode(keyCode: Enum.KeyCode, platform: InputPlatform): string?
	return KeyCodeIconMappings.getIconForKeyName(keyCode.Name, platform)
end

return getIconForKeyCode
