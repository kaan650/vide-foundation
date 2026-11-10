local Vide = require("../Packages/Vide")

local Services = require("./Wrappers/Services")
local UserInputService = Services.UserInputService

--- The player's preferred input as a source. Call it while the component is being created.
local function usePreferredInput(): () -> Enum.PreferredInput
	local preferredInput = Vide.source(UserInputService.PreferredInput)
	Vide.cleanup(UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
		preferredInput(UserInputService.PreferredInput)
	end))
	return preferredInput
end

return usePreferredInput
