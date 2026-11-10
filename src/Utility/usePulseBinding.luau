local useClock = require("./useClock")

local DEFAULT_RANGE = NumberRange.new(0, 1)

--- A source that pulses between `pulseRange.Min` and `pulseRange.Max` (0 and 1 by default) once every `cycleTime`
--- seconds.
local function usePulseBinding(cycleTime: number?, pulseRange: NumberRange?): () -> number
	local clock = useClock()
	local period = cycleTime or 1
	local range = pulseRange or DEFAULT_RANGE
	return function()
		return math.map(math.sin(clock() * math.pi / period) ^ 2, 0, 1, range.Min, range.Max)
	end
end

return usePulseBinding
