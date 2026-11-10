-- Otter's easing curves (Otter 1.3.7 ease.lua), so ported animations follow Foundation's curves exactly. An
-- EasingStyle enum means its "In" curve; a table is a CSS cubic-bezier { x1, y1, x2, y2 }.
export type EasingStyle = Enum.EasingStyle | { number }

local function easeOutBounce(t: number): number
	local n1 = 7.5625
	local d1 = 2.75
	if t < 1 / d1 then
		return n1 * t * t
	elseif t < 2 / d1 then
		return n1 * (t - 1.5 / d1) * (t - 1.5 / d1) + 0.75
	elseif t < 2.5 / d1 then
		return n1 * (t - 2.25 / d1) * (t - 2.25 / d1) + 0.9375
	end
	return n1 * (t - 2.625 / d1) * (t - 2.625 / d1) + 0.984375
end

local curves: { [Enum.EasingStyle]: (number) -> number } = {
	[Enum.EasingStyle.Linear] = function(t)
		return t
	end,
	[Enum.EasingStyle.Quad] = function(t)
		return t * t
	end,
	[Enum.EasingStyle.Cubic] = function(t)
		return t * t * t
	end,
	[Enum.EasingStyle.Quart] = function(t)
		return t * t * t * t
	end,
	[Enum.EasingStyle.Quint] = function(t)
		return t * t * t * t * t
	end,
	[Enum.EasingStyle.Exponential] = function(t)
		return if t == 0 then 0 else math.pow(2, 10 * (t - 1))
	end,
	[Enum.EasingStyle.Sine] = function(t)
		return 1 - math.cos((t * math.pi) / 2)
	end,
	[Enum.EasingStyle.Back] = function(t)
		local c1 = 1.70158
		local c3 = c1 + 1
		return c3 * t * t * t - c1 * t * t
	end,
	[Enum.EasingStyle.Bounce] = function(t)
		return 1 - easeOutBounce(1 - t)
	end,
	[Enum.EasingStyle.Elastic] = function(t)
		if t == 0 or t == 1 then
			return t
		end
		return -math.pow(2, 10 * t - 10) * math.sin((t * 10 - 10.75) * ((2 * math.pi) / 3))
	end,
	[Enum.EasingStyle.Circular] = function(t)
		return -(math.sqrt(1 - t * t) - 1)
	end,
}

local function evaluateBezier(t: number, p1: number, p2: number): number
	local oneMinusT = 1 - t
	return 3 * oneMinusT * oneMinusT * t * p1 + 3 * oneMinusT * t * t * p2 + t * t * t
end

--* Otter finds the bezier parameter with 10 bisection steps and a 1e-4 tolerance; matching it keeps curves equal.
local function cubicBezier(t: number, x1: number, y1: number, x2: number, y2: number): number
	if t <= 0 then
		return 0
	elseif t >= 1 then
		return 1
	end
	local left, right = 0, 1
	for _ = 1, 10 do
		local mid = (left + right) / 2
		local x = evaluateBezier(mid, x1, x2)
		if math.abs(x - t) < 0.0001 then
			return evaluateBezier(mid, y1, y2)
		elseif x < t then
			left = mid
		else
			right = mid
		end
	end
	return evaluateBezier((left + right) / 2, y1, y2)
end

--- The eased progress for linear progress `t` (0 to 1).
local function ease(t: number, style: EasingStyle?): number
	if style == nil then
		return t
	elseif typeof(style) == "EnumItem" then
		local curve = curves[style :: Enum.EasingStyle]
		return if curve then curve(t) else t
	end
	local points = style :: { number }
	return cubicBezier(t, points[1], points[2], points[3], points[4])
end

return {
	ease = ease,
}
