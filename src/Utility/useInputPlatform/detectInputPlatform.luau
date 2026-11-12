local UserInputService = require("../Wrappers/Services").UserInputService

local InputPlatform = require("../../Enums/InputPlatform")

type InputPlatform = InputPlatform.InputPlatform

local function hasConnectedGamepad(): boolean
	local success, gamepads = pcall(function()
		return UserInputService:GetConnectedGamepads()
	end)
	return success and typeof(gamepads) == "table" and #gamepads > 0
end

--* Several keys, because a key may not have an image on every platform.
local PROBE_KEYCODES: { Enum.KeyCode } = {
	Enum.KeyCode.ButtonStart,
	Enum.KeyCode.ButtonSelect,
	Enum.KeyCode.ButtonA,
	Enum.KeyCode.ButtonL1,
	Enum.KeyCode.DPadUp,
}

--* The engine's image path names the console; the glyphs themselves still come from BuilderIcons.
local function getPlatformFromImage(keyCode: Enum.KeyCode): InputPlatform?
	local success, image = pcall(function()
		return UserInputService:GetImageForKeyCode(keyCode)
	end)

	if not success or typeof(image) ~= "string" or image == "" then
		return nil
	end

	local path = image:lower()
	if path:find("ps5") then
		return InputPlatform.PS5
	end
	if path:find("ps4") then
		return InputPlatform.PS4
	end
	if path:find("xbox") then
		return InputPlatform.Xbox
	end

	return nil
end

local function getPlatformFromGamepadAssets(): InputPlatform?
	for _, keyCode in PROBE_KEYCODES do
		local platform = getPlatformFromImage(keyCode)
		if platform ~= nil then
			return platform
		end
	end

	return nil
end

local function isPlaystation(): boolean
	local success, label = pcall(function()
		return UserInputService:GetStringForKeyCode(Enum.KeyCode.ButtonA)
	end)
	return success and label == "ButtonCross"
end

--- The glyph set for the connected input device: `Default` (keyboard and mouse) without a gamepad or when a probe
--- fails, otherwise the console the gamepad's images name.
local function detectInputPlatform(): InputPlatform
	if not hasConnectedGamepad() then
		return InputPlatform.Default
	end

	local platformFromAssets = getPlatformFromGamepadAssets()
	if platformFromAssets ~= nil then
		return platformFromAssets
	end

	--* Labels tell PlayStation from Xbox but not PS4 from PS5.
	return if isPlaystation() then InputPlatform.PS5 else InputPlatform.Xbox
end

return detectInputPlatform
