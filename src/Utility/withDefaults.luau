local function deepJoin(a: { [any]: any }, b: { [any]: any }): { [any]: any }
	local result = table.clone(a)
	for key, value in b do
		if type(value) == "table" and type(result[key]) == "table" then
			result[key] = deepJoin(result[key], value)
		else
			result[key] = value
		end
	end
	return result
end

--- Fills missing props from `defaults`. A table prop is merged into its table default, key by key. A source prop
--- gets the same treatment on every read (nil falls back, a table is merged), the way React applies defaults on
--- every render.
local function withDefaults<P, D>(props: P, defaults: D): P & D
	local result = table.clone(props :: any)
	for key, default in defaults :: any do
		local value = result[key]
		if value == nil then
			result[key] = default
		elseif type(value) == "table" and type(default) == "table" then
			result[key] = deepJoin(default, value)
		elseif type(value) == "function" and type(default) ~= "function" then
			local source = value
			result[key] = function()
				local resolved = (source :: any)()
				if resolved == nil then
					return default
				elseif type(resolved) == "table" and type(default) == "table" then
					return deepJoin(default, resolved)
				end
				return resolved
			end
		end
	end
	return result :: any
end

return withDefaults
