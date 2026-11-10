local Vide = require("../../Packages/Vide")

local Tokens = require("./Tokens")
type Tokens = Tokens.Tokens

local function defaultTokens(): Tokens
	return Tokens.defaultTokens
end

return Vide.context(defaultTokens :: () -> Tokens)
