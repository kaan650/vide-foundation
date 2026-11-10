local Vide = require("../../Packages/Vide")

local function noStyleSheet(): StyleSheet?
	return nil
end

local context = Vide.context(noStyleSheet :: () -> StyleSheet?)

--- The provider's StyleSheet as a source.
local function useStyleSheet(): () -> StyleSheet?
	return context()
end

return {
	context = context,
	useStyleSheet = useStyleSheet,
}
