local Vide = require("../../Packages/Vide")

local function zero(): number
	return 0
end

return Vide.context(zero :: () -> number)
