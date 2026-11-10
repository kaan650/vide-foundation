local Tokens = require("./Tokens")
local TokensContext = require("./TokensContext")
type Tokens = Tokens.Tokens

--- The provider's tokens as a source; read it inside a reactive scope so theme changes reach the component.
--- Call it while the component is being created, under a StyleProvider.
local function useTokens(): () -> Tokens
	return TokensContext()
end

return useTokens
