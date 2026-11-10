local Vide = require("../../Packages/Vide")

local Motion = require("./Motion")
local createMotor = require("./createMotor")
local goals = require("./goals")

type MotionState = Motion.MotionState
type TransitionConfig = Motion.TransitionConfig
type Motor = createMotor.Motor

export type AnimationOptions = {
	-- Called with each property name as it finishes, then with `true` once all have.
	onAnimationComplete: ((string | boolean) -> ())?,
}

type Codec = {
	encode: (value: any) -> { number },
	decode: (parts: { number }) -> any,
}

--* Motion eases each component of a value separately (UDim2 as four numbers, Color3 as RGB), so a lerp with one
--* eased progress gives the same result.
local codecs: { [string]: Codec } = {
	number = {
		encode = function(value: number)
			return { value }
		end,
		decode = function(parts)
			return parts[1]
		end,
	},
	UDim = {
		encode = function(value: UDim)
			return { value.Scale, value.Offset }
		end,
		decode = function(parts)
			return UDim.new(parts[1], parts[2])
		end,
	},
	UDim2 = {
		encode = function(value: UDim2)
			return { value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset }
		end,
		decode = function(parts)
			return UDim2.new(parts[1], parts[2], parts[3], parts[4])
		end,
	},
	Vector2 = {
		encode = function(value: Vector2)
			return { value.X, value.Y }
		end,
		decode = function(parts)
			return Vector2.new(parts[1], parts[2])
		end,
	},
	Color3 = {
		encode = function(value: Color3)
			return { value.R, value.G, value.B }
		end,
		decode = function(parts)
			return Color3.new(parts[1], parts[2], parts[3])
		end,
	},
	Color4 = {
		encode = function(value: { Color3: Color3, Transparency: number })
			return { value.Color3.R, value.Color3.G, value.Color3.B, value.Transparency }
		end,
		decode = function(parts)
			return { Color3 = Color3.new(parts[1], parts[2], parts[3]), Transparency = parts[4] }
		end,
	},
}

local function codecFor(value: any): Codec?
	if typeof(value) == "table" and value.Color3 and value.Transparency then
		return codecs.Color4
	end
	return codecs[typeof(value)]
end

type AnimatedValue = {
	source: () -> any,
	animate: (target: any, timing: TransitionConfig, onComplete: () -> ()) -> (),
}

local function useAnimatedValue(initial: any): AnimatedValue?
	local codec = codecFor(initial)
	if not codec then
		warn("Unsupported type for animated value:", typeof(initial))
		return nil
	end

	local value = Vide.source(initial)
	local parts = codec.encode(initial)
	local completeCallback: (() -> ())? = nil
	local remaining = 0
	local motors: { Motor } = {}

	for i, start in parts do
		motors[i] = createMotor(start, function(position)
			parts[i] = position
			value(codec.decode(parts))
		end, function()
			remaining -= 1
			if remaining == 0 and completeCallback then
				completeCallback()
			end
		end)
	end

	Vide.cleanup(function()
		for _, motor in motors do
			motor.destroy()
		end
	end)

	return {
		source = value,
		animate = function(target: any, timing: TransitionConfig, onComplete: () -> ())
			if codecFor(target) ~= codec then
				warn("Animated value target has a different type:", typeof(target))
				return
			end
			completeCallback = onComplete
			remaining = #motors
			local options = {
				duration = timing.duration or Motion.defaultTransition.duration,
				easingStyle = timing.easingStyle,
			}
			for i, part in codec.encode(target) do
				motors[i].setGoal(goals.ease(part, options))
			end
		end,
	}
end

--- Roblox Motion's useMotion: a Vide source per animated property of `initialState`, and `animate(newState)` that
--- moves them with each property's transition. Call it while the component is being created.
local function useMotion(initialState: MotionState): ({ [string]: () -> any }, (newState: MotionState, options: AnimationOptions?) -> ())
	local sources: { [string]: () -> any } = {}
	local animators: { [string]: AnimatedValue } = {}
	local delayed: { [string]: thread } = {}

	for name, initial in initialState do
		if name == "transition" then
			continue
		end
		local animated = useAnimatedValue(initial)
		if animated then
			sources[name] = animated.source
			animators[name] = animated
		end
	end

	Vide.cleanup(function()
		for _, thread in delayed do
			task.cancel(thread)
		end
	end)

	local function animate(newState: MotionState, options: AnimationOptions?)
		if not newState then
			return
		end

		local total = 0
		for name in animators do
			if newState[name] ~= nil then
				total += 1
			end
		end
		local completed = 0
		local onAnimationComplete = if options then options.onAnimationComplete else nil

		for name, animator in animators do
			local target = newState[name]
			if target == nil then
				continue
			end

			local pending = delayed[name]
			if pending then
				task.cancel(pending)
				delayed[name] = nil
			end

			local transitions = newState.transition
			local timing: TransitionConfig = if transitions
				then transitions[name] or transitions.default
				else Motion.defaultTransition

			local function onComplete()
				completed += 1
				if onAnimationComplete then
					onAnimationComplete(name)
					if completed == total then
						onAnimationComplete(true)
					end
				end
				if timing.onComplete then
					timing.onComplete()
				end
			end

			local delay = timing.delay or 0
			if delay > 0 then
				delayed[name] = task.delay(delay, function()
					delayed[name] = nil
					animator.animate(target, timing, onComplete)
				end)
			else
				animator.animate(target, timing, onComplete)
			end
		end
	end

	return sources, animate
end

return useMotion
