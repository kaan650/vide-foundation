local Constants = require("../Constants")
local Types = require("../Components/Types")
type ColorStyleValue = Types.ColorStyleValue

--- `colorStyle` faded the way Foundation fades disabled content.
local function getDisabledStyle(colorStyle: ColorStyleValue, isDisabled: boolean?): ColorStyleValue
	if not isDisabled then
		return colorStyle
	end
	return {
		Color3 = colorStyle.Color3,
		Transparency = 1 - (1 - (colorStyle.Transparency or 0)) * Constants.DISABLED_TRANSPARENCY,
	}
end

return getDisabledStyle
