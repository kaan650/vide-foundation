local ENTITIES = {
	["&"] = "&amp;",
	["<"] = "&lt;",
	[">"] = "&gt;",
	['"'] = "&quot;",
	["'"] = "&apos;",
}

--- `text` with the characters rich text treats as markup replaced by their entities.
local function escapeRichText(text: string): string
	return (text:gsub("[&<>\"']", ENTITIES))
end

return escapeRichText
