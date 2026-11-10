local Vide = require("../../Packages/Vide")

local InputMode = require("./InputMode")
local Services = require("../Wrappers/Services")
local getInputMode = require("./getInputMode")

type InputMode = InputMode.InputMode

local function getLastInputMode(): InputMode?
	return getInputMode(Services.UserInputService:GetLastInputType())
end

--- The input mode of the last input the user made, as a source. Call it while the component is being created.
local function useLastInputMode(): () -> InputMode?
	local lastInputMode = Vide.source(getLastInputMode())

	Vide.cleanup(Services.UserInputService.LastInputTypeChanged:Connect(function()
		lastInputMode(getLastInputMode())
	end))

	local get: () -> InputMode? = lastInputMode :: any
	return get
end

return useLastInputMode
