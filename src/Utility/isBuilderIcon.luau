local cache: { [string]: boolean } = {}

--- Builder Icons names are lowercase words, digits and dashes; anything else is a FoundationImages key or an asset.
local function isBuilderIcon(icon: string?): boolean
	if icon == nil or icon == "" then
		return false
	end
	local cached = cache[icon]
	if cached == nil then
		cached = icon:find("[^%l%d%-]") == nil
		cache[icon] = cached
	end
	return cached
end

return isBuilderIcon
