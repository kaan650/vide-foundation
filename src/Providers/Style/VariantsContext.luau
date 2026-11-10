-- Variant tables are built once per component name and token set, then shared by every instance of the component.
local caches: { [any]: { [string]: any } } = setmetatable({}, { __mode = "k" }) :: any

local function useVariants<Tokens, Result>(componentName: string, variantsFactory: (Tokens) -> Result, tokens: Tokens): Result
	local cache = caches[tokens]
	if not cache then
		cache = {}
		caches[tokens] = cache
	end
	local value = cache[componentName]
	if value == nil then
		value = variantsFactory(tokens)
		cache[componentName] = value
	end
	return value
end

return {
	useVariants = useVariants,
}
