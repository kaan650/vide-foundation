-- Replaces Roblox's Motion, Otter and ReactOtter for ported components, on top of Ripple.
local Motion = require("@self/Motion")
local goals = require("@self/goals")
local useAnimatedBinding = require("@self/useAnimatedBinding")
local useMotion = require("@self/useMotion")

export type TransitionConfig = Motion.TransitionConfig
export type MotionState = Motion.MotionState
export type TransitionPreset = Motion.TransitionPreset
export type Goal = goals.Goal
export type EaseOptions = goals.EaseOptions
export type SpringOptions = goals.SpringOptions
export type AnimationOptions = useMotion.AnimationOptions

return {
	-- Motion
	createState = Motion.createState,
	transition = Motion.transition,
	TransitionPreset = Motion.TransitionPreset,
	useMotion = useMotion,

	-- Otter and ReactOtter
	ease = goals.ease,
	spring = goals.spring,
	instant = goals.instant,
	useAnimatedBinding = useAnimatedBinding,
}
