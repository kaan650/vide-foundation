local Vide = require("../../Packages/Vide")

local UserInputService = require("../Wrappers/Services").UserInputService

local InputPlatform = require("../../Enums/InputPlatform")
local detectInputPlatform = require("./detectInputPlatform")

type InputPlatform = InputPlatform.InputPlatform

--- The glyph platform of the connected input device as a source, detected again when a gamepad connects or
--- disconnects (`PreferredInput` does not tell console generations apart). Call it while the component is being
--- created, once per component tree that should agree on its glyphs.
local function useInputPlatform(): () -> InputPlatform
	local platform = Vide.source(detectInputPlatform())

	local function refresh()
		platform(detectInputPlatform())
	end
	Vide.cleanup(UserInputService.GamepadConnected:Connect(refresh))
	Vide.cleanup(UserInputService.GamepadDisconnected:Connect(refresh))

	return platform
end

return useInputPlatform
