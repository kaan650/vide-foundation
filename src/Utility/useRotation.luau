local RunService = game:GetService("RunService")

local Vide = require("../Packages/Vide")

local NUM_DEGREES = 360

--- A rotation in degrees that turns `speed` times a second, as a source, from when the component was created.
local function useRotation(speed: number?): () -> number
	local elapsed = Vide.source(0)
	Vide.cleanup(RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed(Vide.untrack(elapsed) + deltaTime)
	end))
	return function()
		return elapsed() * NUM_DEGREES * (speed or 1)
	end
end

return useRotation
