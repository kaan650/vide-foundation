local Ripple = require("../../Packages/Ripple")

local easing = require("./easing")
local goals = require("./goals")

type Goal = goals.Goal

export type Motor = {
	setGoal: (goal: Goal) -> (),
	getValue: () -> number,
	destroy: () -> (),
}

--- One animated number, driven by Ripple. An ease runs a linear Ripple tween over its duration and maps its progress
--- through Otter's curve; a spring is a Ripple spring with Otter's damping ratio and frequency. A new goal starts
--- from the current value, as Otter's motors do.
local function createMotor(initial: number, onStep: (value: number) -> (), onComplete: () -> ()): Motor
	local value = initial
	local tween: Ripple.Tween<number>? = nil
	local spring: Ripple.Spring<number>? = nil
	local generation = 0

	local function stopTween()
		if tween then
			tween:destroy()
			tween = nil
		end
	end

	local function stopSpring()
		if spring then
			spring:destroy()
			spring = nil
		end
	end

	local function finish(target: number, ownGeneration: number)
		if ownGeneration ~= generation then
			return
		end
		value = target
		onStep(value)
		--! Completion callbacks may destroy scopes that own other Ripple animations; doing that inside Ripple's step
		--! crashes its scheduler (littensy/ripple#23), so they run after it.
		task.defer(function()
			if ownGeneration == generation then
				onComplete()
			end
		end)
	end

	local function setGoal(goal: Goal)
		generation += 1
		local ownGeneration = generation

		if goal.kind == "instant" then
			stopTween()
			stopSpring()
			finish(goal.target, ownGeneration)
		elseif goal.kind == "ease" then
			stopSpring()
			stopTween()
			local from = value
			local target = goal.target
			if goal.duration <= 0 or from == target then
				finish(target, ownGeneration)
				return
			end
			local easingStyle = goal.easingStyle
			local newTween = Ripple.createTween(0, { duration = goal.duration, easing = "linear", start = true })
			newTween:onChange(function(progress: number)
				if ownGeneration == generation then
					value = from + (target - from) * easing.ease(progress, easingStyle)
					onStep(value)
				end
			end)
			newTween:onComplete(function()
				finish(target, ownGeneration)
			end)
			newTween:setGoal(1)
			tween = newTween
		else
			stopTween()
			local target = goal.target
			if spring then
				spring:configure({ dampingRatio = goal.dampingRatio, frequency = goal.frequency })
				spring:setGoal(target)
			else
				local newSpring = Ripple.createSpring(value, {
					dampingRatio = goal.dampingRatio,
					frequency = goal.frequency,
					start = true,
				})
				newSpring:onChange(function(position: number)
					value = position
					onStep(value)
				end)
				newSpring:setGoal(target)
				spring = newSpring
			end
			local activeSpring = spring :: Ripple.Spring<number>
			local disconnect: (() -> ())? = nil
			disconnect = activeSpring:onComplete(function()
				if disconnect then
					disconnect()
				end
				finish(target, ownGeneration)
			end)
		end
	end

	return {
		setGoal = setGoal,
		getValue = function()
			return value
		end,
		destroy = function()
			generation += 1
			stopTween()
			stopSpring()
		end,
	}
end

return createMotor
