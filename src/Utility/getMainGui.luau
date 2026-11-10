local Wrappers = require("./Wrappers")
local CoreGui = Wrappers.Services.CoreGui
local Players = Wrappers.Services.Players
local RunService = Wrappers.Services.RunService

local isPluginSecurity = require("./isPluginSecurity")

local playerGui: Instance?

local function getPlayerGui(): Instance?
	if not RunService:IsClient() or not Players.LocalPlayer or not RunService:IsRunning() then
		return nil
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui", 3)
end

--- The container overlays mount into: CoreGui for plugins, PlayerGui for games, nil when neither exists (Edit mode).
local function getMainGui(): Instance?
	if isPluginSecurity() then
		return CoreGui
	end
	if playerGui == nil then
		playerGui = getPlayerGui()
	end
	return playerGui
end

return getMainGui
