local Vide = require("../../Packages/Vide")

local Types = require("../../Components/Types")
local useTokens = require("./useTokens")
type ColorStyleValue = Types.ColorStyleValue

local context = Vide.context(nil :: (() -> ColorStyleValue)?)

--- The background set by the nearest ancestor, or Surface_0 when none is set.
local function useBackgroundStyle(): () -> ColorStyleValue
	local value = context()
	if value then
		return value :: () -> ColorStyleValue
	end
	local tokens = useTokens()
	return function(): ColorStyleValue
		return tokens().Color.Surface.Surface_0 :: any
	end
end

return {
	context = context,
	useBackgroundStyle = useBackgroundStyle,
}
