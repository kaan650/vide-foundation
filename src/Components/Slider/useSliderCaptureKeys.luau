local Vide = require("../../Packages/Vide")

local UserInputService = require("../../Utility/Wrappers/Services").UserInputService

local constants = require("./constants")

local function isCaptureKey(keyCode: Enum.KeyCode): boolean
	return table.find(constants.enter, keyCode) ~= nil or table.find(constants.thumbSwitch, keyCode) ~= nil
end

--- Calls `onCapture` when Enter or A is pressed while `isListening` is true. Call it while the component is being
--- created.
local function useSliderCaptureKeys(isListening: () -> boolean, onCapture: () -> ())
	Vide.effect(function()
		if not isListening() then
			return
		end
		Vide.untrack(function()
			Vide.cleanup(UserInputService.InputBegan:Connect(function(input: InputObject)
				if isCaptureKey(input.KeyCode) then
					onCapture()
				end
			end))
		end)
	end)
end

return useSliderCaptureKeys
