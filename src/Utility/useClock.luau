local RunService = game:GetService("RunService")

local Vide = require("../Packages/Vide")

--- Seconds since the component was created, as a source updated every frame. Replaces ReactUtils' useClock.
local function useClock(): () -> number
	local elapsed = Vide.source(0)
	Vide.cleanup(RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed(Vide.untrack(elapsed) + deltaTime)
	end))
	return function()
		return elapsed()
	end
end

return useClock
