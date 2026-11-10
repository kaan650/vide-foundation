local Types = require("../Types")
type PartialColorHSV = Types.PartialColorHSV

export type UpdatingRef = { current: boolean }

-- A partial HSV takes 100 for a missing S or V; isPartialHSV tells callers to treat it as "no color".
local function toColor3(value: Color3 | PartialColorHSV): Color3
	if typeof(value) == "Color3" then
		return value
	end

	local hsv = value :: PartialColorHSV
	return Color3.fromHSV(hsv.H / 360, (hsv.S or 100) / 100, (hsv.V or 100) / 100)
end

local function isPartialHSV(value: Color3 | PartialColorHSV): boolean
	if typeof(value) == "Color3" then
		return false
	end
	local hsv = value :: PartialColorHSV
	return hsv.S == nil or hsv.V == nil
end

local function calculateSVFromPosition(
	dragPosition: Vector2,
	pickerPosition: Vector2,
	pickerSize: Vector2
): (number, number)
	local localX = math.clamp(dragPosition.X - pickerPosition.X, 0, pickerSize.X)
	local localY = math.clamp(dragPosition.Y - pickerPosition.Y, 0, pickerSize.Y)

	local newS = localX / pickerSize.X
	local newV = 1 - (localY / pickerSize.Y)

	return newS, newV
end

local function createHSVUpdateHandler(
	setCurrentHue: (number) -> any,
	setCurrentSaturation: (number) -> any,
	setCurrentValue: (number) -> any,
	onColorChanged: (Color3) -> (),
	isUpdatingFromHSV: UpdatingRef
): (newH: number, newS: number, newV: number) -> ()
	return function(newH: number, newS: number, newV: number)
		isUpdatingFromHSV.current = true
		setCurrentHue(newH)
		setCurrentSaturation(newS)
		setCurrentValue(newV)

		local newColor = Color3.fromHSV(newH, newS, newV)
		onColorChanged(newColor)

		isUpdatingFromHSV.current = false
	end
end

local function createColorInputChangeHandler(
	onColorChanged: (Color3) -> (),
	isUpdatingFromHSV: UpdatingRef,
	setCurrentHue: (number) -> any,
	setCurrentSaturation: (number) -> any,
	setCurrentValue: (number) -> any
): (newColor: Color3) -> ()
	return function(newColor: Color3)
		onColorChanged(newColor)

		if not isUpdatingFromHSV.current then
			local newH, newS, newV = newColor:ToHSV()
			setCurrentHue(newH)
			setCurrentSaturation(newS)
			setCurrentValue(newV)
		end
	end
end

return {
	calculateSVFromPosition = calculateSVFromPosition,
	createHSVUpdateHandler = createHSVUpdateHandler,
	createColorInputChangeHandler = createColorInputChangeHandler,
	isPartialHSV = isPartialHSV,
	toColor3 = toColor3,
}
