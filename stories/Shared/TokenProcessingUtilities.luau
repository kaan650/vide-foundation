-- The token browser half of Foundation's TokenProcessingUtilities, which the package leaves out because only the
-- Tokens story uses it.
local TokenProcessingUtilities =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Providers/Style/Tokens/TokenProcessingUtilities")

export type TokenItem = {
	key: string,
	value: any,
	category: string,
	fullPath: string,
}

--- Whether `value` is a ColorStyle table (Color3 and Transparency).
local function isColorStyle(value: any): boolean
	return type(value) == "table"
		and value.Color3 ~= nil
		and typeof(value.Color3) == "Color3"
		and value.Transparency ~= nil
		and typeof(value.Transparency) == "number"
end

local function getRoundedNumber(value: number): number
	return math.round(value * 1000) / 1000
end

local function getRGBAValues(color: Color3, transparency: number?): (number, number, number, number?)
	local r, g, b = math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255)
	if transparency then
		return r, g, b, getRoundedNumber(1 - transparency)
	end
	return r, g, b, nil
end

--- A token value as display text: `rgb(...)`, `rgba(...)`, a rounded number or `tostring`.
local function formatTokenValue(value: any): string
	if typeof(value) == "Color3" then
		local r, g, b = getRGBAValues(value)
		return `rgb({r}, {g}, {b})`
	elseif typeof(value) == "number" then
		return tostring(getRoundedNumber(value))
	elseif isColorStyle(value) then
		local r, g, b, alpha = getRGBAValues(value.Color3, value.Transparency)
		return `rgba({r}, {g}, {b}, {alpha})`
	else
		return tostring(value)
	end
end

--- Every leaf token under `tokens`, flattened into a list. `flattenColors` keeps ColorStyle tables as one token.
local function collectTokens(tokens: any, category: string, prefix: string?, flattenColors: boolean?): { TokenItem }
	local result = {}

	for key, value in tokens do
		local fullPath = if prefix then `{prefix}.{key}` else key

		if type(value) == "table" and not getmetatable(value) and not (flattenColors and isColorStyle(value)) then
			for _, token in collectTokens(value, category, fullPath, flattenColors) do
				table.insert(result, token)
			end
		else
			table.insert(result, {
				key = key,
				value = value,
				category = category,
				fullPath = fullPath,
			})
		end
	end

	return result
end

--- Like `collectTokens`, grouped by the first level below the category.
local function collectTokensWithSubcategories(
	tokens: any,
	category: string,
	prefix: string?,
	flattenColors: boolean?
): { [string]: { TokenItem } }
	local result: { [string]: { TokenItem } } = {}

	local function add(subcategory: string, token: TokenItem)
		if not result[subcategory] then
			result[subcategory] = {}
		end
		table.insert(result[subcategory], token)
	end

	for key, value in tokens do
		local fullPath = if prefix then `{prefix}.{key}` else key

		if type(value) == "table" then
			if flattenColors and isColorStyle(value) then
				add(if prefix then prefix:split(".")[1] else "Default", {
					key = key,
					value = value,
					category = category,
					fullPath = fullPath,
				})
			elseif not prefix then
				local subcategoryTokens = collectTokens(value, category, key, flattenColors)
				if #subcategoryTokens > 0 then
					result[key] = subcategoryTokens
				end
			else
				for _, token in collectTokens(value, category, fullPath, flattenColors) do
					add(prefix:split(".")[1], token)
				end
			end
		else
			add(if prefix then prefix:split(".")[1] else "Default", {
				key = key,
				value = value,
				category = category,
				fullPath = fullPath,
			})
		end
	end

	return result
end

--- Whether a token category nests its tokens one level deeper (Color.Surface.Surface_0).
local function hasSubcategories(categoryTokens: any): boolean
	for _, value in categoryTokens do
		if type(value) == "table" then
			for _, nestedValue in value do
				if
					type(nestedValue) == "table"
					or typeof(nestedValue) == "Color3"
					or typeof(nestedValue) == "number"
				then
					return true
				end
			end
		end
	end
	return false
end

local numberTokenPattern = "(%u%a+)_(%d+)%.?(%u?%w*)"
local numberValuePattern = "| (%-?[%d.]+) |$"

--- Sort comparator with natural number order (Orange_100 before Orange_1000). With `allNumeric`, compares the
--- `| value |` suffix the caller appended.
local function sortTokens(a: string, b: string, allNumeric: boolean?): boolean
	if a:find(numberTokenPattern) and b:find(numberTokenPattern) then
		local aPrefix, aNumber, aRemainder = a:match(numberTokenPattern)
		local bPrefix, bNumber, bRemainder = b:match(numberTokenPattern)
		if aPrefix == bPrefix then
			if aNumber == bNumber then
				return (aRemainder :: string) < (bRemainder :: string)
			end
			return (tonumber(aNumber) :: number) < (tonumber(bNumber) :: number)
		end
		return a < b
	end

	if allNumeric then
		local aNumber = a:match(numberValuePattern)
		local bNumber = b:match(numberValuePattern)
		return (tonumber(aNumber) :: number) < (tonumber(bNumber) :: number)
	end

	return a < b
end

local orderedTokenCategories = {
	"Color",
	"Stroke",
	"Size",
	"Radius",
	"Padding",
	"Margin",
	"Gap",
	"Typography",
	"FontSize",
	"FontWeight",
	"LineHeight",
	"Ease",
	"Time",
	"Inverse",
	"DarkMode",
	"LightMode",
	"Config",
}

return {
	isColorStyle = isColorStyle,
	formatTokenValue = formatTokenValue,
	collectTokens = collectTokens,
	collectTokensWithSubcategories = collectTokensWithSubcategories,
	hasSubcategories = hasSubcategories,
	sortTokens = sortTokens,
	orderedTokenCategories = orderedTokenCategories,
	getTokenValue = TokenProcessingUtilities.getTokenValue,
}
