--- The value after dragging from `startingXPosition` to `dragXPosition`: one `step` per pixel, scaled by `sensitivity`.
local function calculateNumberInputValueFromPositions(
	startingValue: number,
	startingXPosition: number,
	dragXPosition: number,
	step: number,
	sensitivity: number?
): number
	local delta = math.floor((dragXPosition - startingXPosition) * (sensitivity or 1))
	return startingValue + (delta * step)
end

return calculateNumberInputValueFromPositions
