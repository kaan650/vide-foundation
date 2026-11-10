-- Token path lookup and the validation behind StyleProvider tokenOverrides.
local Logger = require("../../../Utility/Logger")

-- Get a nested value from a token table using a dot-separated path
-- Example: getTokenValue(tokens, "Color.Surface.Surface_0") -> Color3 value
local function getTokenValue(tokens: any, path: string): any
	local current = tokens
	for _, segment in string.split(path, ".") do
		if current == nil or type(current) ~= "table" then
			return nil
		end
		current = current[segment]
	end
	return current
end

-- Set a nested value in a token table using a dot-separated path
-- Does nothing if the path doesn't exist (won't create intermediate tables)
local function setTokenValue(tokens: any, path: string, value: any)
	local segments = string.split(path, ".")
	local current = tokens
	for i = 1, #segments - 1 do
		local segment = segments[i]
		if current[segment] == nil then
			return
		end
		current = current[segment]
	end

	local lastSegment = segments[#segments]
	if current and lastSegment then
		current[lastSegment] = value
	end
end

local function tokenOverrideValuesCompatible(a: any, b: any): boolean
	if a == nil or b == nil then
		return false
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return typeof(a) == typeof(b)
	end
	for k, av in a do
		if not tokenOverrideValuesCompatible(av, b[k]) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

-- String source = token path (lookup on tokens); anything else = literal.
local function resolveTokenOverrideSource(tokens: any, source: any): any?
	if type(source) == "string" then
		local value = getTokenValue(tokens, source)
		if value == nil then
			Logger:warning(`Token override skipped: unknown source token path "{source}"`)
			return nil
		end
		return value
	end
	return source
end

-- Unknown targets are rejected; resolved value must match target shape/type.
local function resolveTokenOverride(tokens: any, targetPath: string, source: any): any?
	local resolved = resolveTokenOverrideSource(tokens, source)
	if resolved == nil then
		return nil
	end
	local targetCurrent = getTokenValue(tokens, targetPath)
	if targetCurrent == nil then
		Logger:warning(`Token override skipped: unknown target token path "{targetPath}"`)
		return nil
	end
	if not tokenOverrideValuesCompatible(targetCurrent, resolved) then
		Logger:warning(`Token override skipped: type or shape mismatch for "{targetPath}"`)
		return nil
	end
	return resolved
end

return {
	getTokenValue = getTokenValue,
	setTokenValue = setTokenValue,
	resolveTokenOverride = resolveTokenOverride,
}
