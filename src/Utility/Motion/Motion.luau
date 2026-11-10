-- Roblox's Motion package (0.1.0): animation states with per-property transitions.
local easing = require("./easing")

export type TransitionPreset = "default" | "quick" | "slow"

export type TransitionConfig = {
	duration: number?,
	easingStyle: easing.EasingStyle?,
	delay: number?,
	onComplete: (() -> ())?,
}

export type MotionState = {
	[string]: any,
	transition: {
		default: TransitionConfig,
		[string]: TransitionConfig?,
	}?,
}

local TransitionPreset = {
	Default = "default" :: "default",
	Quick = "quick" :: "quick",
	Slow = "slow" :: "slow",
}

--* Material's emphasized curve, which Motion uses for every preset.
local EMPHASIZED = { 0.2, 0.0, 0.0, 1.0 }

local presets: { [string]: TransitionConfig } = {
	default = { duration = 0.3, easingStyle = EMPHASIZED, delay = 0 },
	quick = { duration = 0.05, easingStyle = EMPHASIZED, delay = 0 },
	slow = { duration = 1.0, easingStyle = EMPHASIZED, delay = 0 },
}

local defaultTransition = presets.default

local function createState(values: { [string]: any }, transitions: { [string]: TransitionConfig }?): MotionState
	local transition: { default: TransitionConfig, [string]: TransitionConfig? } = {
		default = if transitions and transitions.default
			then transitions.default :: TransitionConfig
			else defaultTransition,
	}
	local state: MotionState = { transition = transition }
	for name, value in values do
		state[name] = value
		if transitions and transitions[name] then
			transition[name] = transitions[name]
		end
	end
	return state
end

local function transition(
	presetOrConfig: (TransitionPreset | string | TransitionConfig)?,
	overrides: TransitionConfig?
): TransitionConfig
	local config: TransitionConfig? = if type(presetOrConfig) == "string"
		then presets[presetOrConfig] or defaultTransition
		else presetOrConfig :: TransitionConfig?

	local result: TransitionConfig = {
		duration = if config and config.duration then config.duration else defaultTransition.duration,
		easingStyle = if config and config.easingStyle then config.easingStyle else defaultTransition.easingStyle,
		delay = if config and config.delay then config.delay else defaultTransition.delay,
	}
	if overrides then
		result.duration = overrides.duration or result.duration
		result.easingStyle = overrides.easingStyle or result.easingStyle
		result.delay = overrides.delay or result.delay
	end
	return result
end

return {
	createState = createState,
	transition = transition,
	TransitionPreset = TransitionPreset,
	presets = presets,
	defaultTransition = defaultTransition,
}
