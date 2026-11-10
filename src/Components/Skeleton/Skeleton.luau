local Vide = require("../../Packages/Vide")

local CornerRadius = require("../CornerRadius")
local Radius = require("../../Enums/Radius")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local create = require("../../Utility/create")
local lerp = require("../../Utility/lerp")
local useClock = require("../../Utility/useClock")
local usePreferences = require("../../Providers/Preferences/usePreferences")
local usePulseBinding = require("../../Utility/usePulseBinding")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type Radius = Radius.Radius
type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

local TRANSPARENCY_DELTA = 0.1
local GRADIENT_OFFSET = 3
local ANIMATION_SPEED = 2

export type SkeletonProps = {
	radius: Value<Radius>?,
	Size: Value<UDim2>?,
} & Types.CommonProps

local defaultProps = {
	radius = Radius.None,
	Size = UDim2.fromScale(1, 1),
	testId = "--foundation-skeleton",
}

--- A placeholder shape with a moving shimmer, or a slow pulse when the user prefers reduced motion.
local function Skeleton(skeletonProps: SkeletonProps): GuiObject
	local props = withDefaults(skeletonProps, defaultProps)
	local clock = useClock()
	local pulse = usePulseBinding(ANIMATION_SPEED)
	local tokens = useTokens()
	local preferences = usePreferences()

	local function radius(): Radius
		return Value.read(props.radius)
	end
	local function reducedMotion(): boolean
		return preferences().reducedMotion
	end
	local function shimmer(): ColorStyleValue
		return tokens().Color.Common.Shimmer :: any
	end

	local function backgroundStyle(): ColorStyleValue
		if reducedMotion() then
			local transparency = shimmer().Transparency :: number
			return {
				Color3 = shimmer().Color3,
				Transparency = lerp(transparency, transparency - TRANSPARENCY_DELTA, pulse()),
			}
		end
		--* Full opacity lets the gradient's transparency show exactly.
		return tokens().Color.Extended.White.White_100 :: any
	end

	return View(withCommonProps(props, {
		backgroundStyle = backgroundStyle,
		Size = props.Size,
		children = {
			Vide.show(function()
				return radius() ~= Radius.None
			end, function()
				local corner = CornerRadius({
					value = function()
						return UDim.new(0, (tokens().Radius :: any)[radius()])
					end,
					testId = `{props.testId}--corner-radius`,
				})
				corner.Name = "CornerRadius"
				return corner
			end),
			Vide.show(function()
				return not reducedMotion()
			end, function()
				return create("UIGradient")({
					Name = "Gradient",
					Color = function()
						local edge = shimmer().Color3 :: Color3
						return ColorSequence.new({
							ColorSequenceKeypoint.new(0, edge),
							ColorSequenceKeypoint.new(0.5, tokens().Color.Extended.White.White_30.Color3 :: Color3),
							ColorSequenceKeypoint.new(1, edge),
						})
					end,
					Transparency = function()
						local edge = shimmer().Transparency :: number
						return NumberSequence.new({
							NumberSequenceKeypoint.new(0, edge),
							NumberSequenceKeypoint.new(
								0.5,
								tokens().Color.Extended.White.White_30.Transparency :: number
							),
							NumberSequenceKeypoint.new(1, edge),
						})
					end,
					Offset = function()
						return Vector2.new(clock() * ANIMATION_SPEED % GRADIENT_OFFSET - GRADIENT_OFFSET / 2, 0)
					end,
					Rotation = 15,
				})
			end),
		},
	}) :: any)
end

return Skeleton
