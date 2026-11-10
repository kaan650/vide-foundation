local Vide = require("../../Packages/Vide")

local createMotor = require("./createMotor")
local goals = require("./goals")

type Goal = goals.Goal
type Motor = createMotor.Motor

--- ReactOtter's useAnimatedBinding: an animated number, or table of numbers, as a Vide source, and a setter that
--- takes a goal (or a table of goals by key). `onComplete` runs when every key reaches its goal. Call it while the
--- component is being created; the motors stop with the component.
local function useAnimatedBinding<V>(initial: V, onComplete: ((value: V) -> ())?): (() -> V, (goal: any) -> ())
	if type(initial) == "number" then
		local value = Vide.source(initial :: number)
		local motor = createMotor(initial :: number, function(position)
			value(position)
		end, function()
			if onComplete then
				onComplete(Vide.untrack(value) :: any)
			end
		end)
		Vide.cleanup(motor.destroy)
		return value :: any, function(goal: Goal)
			motor.setGoal(goal)
		end
	end

	local current: { [string]: number } = table.clone(initial :: any)
	local value = Vide.source(table.clone(current))
	local motors: { [string]: Motor } = {}
	local pending: { [string]: boolean } = {}

	for key, start in current do
		motors[key] = createMotor(start, function(position)
			current[key] = position
			value(table.clone(current))
		end, function()
			pending[key] = nil
			if next(pending) == nil and onComplete then
				onComplete(table.clone(current) :: any)
			end
		end)
	end

	Vide.cleanup(function()
		for _, motor in motors do
			motor.destroy()
		end
	end)

	return value :: any, function(goal: { [string]: Goal })
		for key, keyGoal in goal do
			local motor = motors[key]
			if motor then
				pending[key] = true
				motor.setGoal(keyGoal)
			end
		end
	end
end

return useAnimatedBinding
