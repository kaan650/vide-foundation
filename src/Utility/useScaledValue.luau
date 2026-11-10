local Logger = require("./Logger")
local useTokens = require("../Providers/Style/useTokens")

--- `value` scaled by the theme's UI scale, as a source. For values larger than the Size tokens.
local function useScaledValue(value: number): () -> number
	local tokens = useTokens()
	return function()
		local current = tokens()
		local scaledValue = value * current.Config.UI.Scale
		if scaledValue <= current.Size.Size_3000 then
			Logger:warning(
				"useScaledValue should be used for values larger than Size tokens. "
					.. "For smaller values, please align to a Size or derivative token."
			)
		end
		return scaledValue
	end
end

return useScaledValue
