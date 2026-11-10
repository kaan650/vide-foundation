local Types = require("../Types")
local Value = require("../../Utility/Value")
local create = require("../../Utility/create")

type Value<T> = Types.Value<T>

type GradientProps = {
	fillDirection: Value<Enum.FillDirection>,
	top: Value<boolean>,
}

local function transparency(top: boolean): NumberSequence
	local first = if top then 0 else 1
	local second = if top then 1 else 0
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, first),
		NumberSequenceKeypoint.new(0.5, first),
		NumberSequenceKeypoint.new(0.50001, second),
		NumberSequenceKeypoint.new(1, second),
	})
end

--- A UIGradient that hides one half of its parent along `fillDirection`: the far half when `top`, else the near half.
local function Gradient(props: GradientProps): UIGradient
	return create("UIGradient")({
		Rotation = function()
			return if Value.read(props.fillDirection) == Enum.FillDirection.Vertical then 90 else 0
		end,
		Transparency = function()
			return transparency(Value.read(props.top) == true)
		end,
	})
end

return Gradient
