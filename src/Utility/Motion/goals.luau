-- Otter's goal constructors (ease, spring, instant), as plain descriptions a motor runs on Ripple.
local easing = require("./easing")

export type EasingStyle = easing.EasingStyle

export type EaseOptions = {
	-- Seconds. Otter defaults to 1.
	duration: number?,
	-- Defaults to Linear.
	easingStyle: EasingStyle?,
}

export type SpringOptions = {
	dampingRatio: number?,
	frequency: number?,
	-- Figma-style parameters; used instead of dampingRatio and frequency when all three are set.
	stiffness: number?,
	damping: number?,
	mass: number?,
}

export type EaseGoal = { kind: "ease", target: number, duration: number, easingStyle: EasingStyle? }
export type SpringGoal = { kind: "spring", target: number, dampingRatio: number, frequency: number }
export type InstantGoal = { kind: "instant", target: number }
export type Goal = EaseGoal | SpringGoal | InstantGoal

local function ease(target: number, options: EaseOptions?): Goal
	return {
		kind = "ease",
		target = target,
		duration = if options and options.duration then options.duration else 1,
		easingStyle = if options then options.easingStyle else nil,
	}
end

local function spring(target: number, options: SpringOptions?): Goal
	local dampingRatio, frequency = 1, 1
	if options then
		if options.stiffness and options.damping and options.mass then
			dampingRatio = options.damping / (2 * math.sqrt(options.mass * options.stiffness))
			frequency = math.sqrt(options.stiffness / options.mass) / 2 / math.pi
		else
			dampingRatio = options.dampingRatio or dampingRatio
			frequency = options.frequency or frequency
		end
	end
	return { kind = "spring", target = target, dampingRatio = dampingRatio, frequency = frequency }
end

local function instant(target: number): Goal
	return { kind = "instant", target = target }
end

return {
	ease = ease,
	spring = spring,
	instant = instant,
}
