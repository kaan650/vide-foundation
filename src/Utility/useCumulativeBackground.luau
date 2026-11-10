local Types = require("../Components/Types")
local Value = require("./Value")

type ColorStyle = Types.ColorStyle
type ColorStyleValue = Types.ColorStyleValue

--- The opaque color `elementBackground` shows when drawn over `background`, as a source.
local function useCumulativeBackground(background: ColorStyle, elementBackground: ColorStyle): () -> ColorStyleValue
	return function()
		local base: ColorStyleValue = Value.read(background)
		local element: ColorStyleValue = Value.read(elementBackground)
		return {
			Color3 = (element.Color3 :: Color3):Lerp(base.Color3 :: Color3, element.Transparency :: number),
			Transparency = 0,
		}
	end
end

return useCumulativeBackground
