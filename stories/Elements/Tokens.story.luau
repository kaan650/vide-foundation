local foundation = require("../foundation")
local TokenProcessingUtilities = require("../Shared/TokenProcessingUtilities")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide

type TokenItem = TokenProcessingUtilities.TokenItem
type ColorStyleValue = VideFoundation.ColorStyleValue

local orderedTokenCategories = TokenProcessingUtilities.orderedTokenCategories
local formatTokenValue = TokenProcessingUtilities.formatTokenValue
local isColorStyle = TokenProcessingUtilities.isColorStyle
local collectTokens = TokenProcessingUtilities.collectTokens
local collectTokensWithSubcategories = TokenProcessingUtilities.collectTokensWithSubcategories
local getTokenValue = TokenProcessingUtilities.getTokenValue
local hasSubcategories = TokenProcessingUtilities.hasSubcategories
local sortTokens = TokenProcessingUtilities.sortTokens

local function matchesSearch(token: TokenItem, searchText: string, category: string): boolean
	local fullSearchPath = string.lower(`{category}.{token.fullPath}`)
	return searchText == "" or string.find(fullSearchPath, string.lower(searchText), 1, true) ~= nil
end

local function filterAndSortTokens(tokens: { TokenItem }, searchText: string, category: string): { TokenItem }
	local result = {}
	for _, token in tokens do
		if matchesSearch(token, searchText, category) then
			table.insert(result, token)
		end
	end

	local allNumeric = true
	for _, token in result do
		if typeof(token.value) ~= "number" then
			allNumeric = false
			break
		end
	end

	table.sort(result, function(a: TokenItem, b: TokenItem)
		return sortTokens(
			a.fullPath .. if allNumeric then `| {a.value} |` else "",
			b.fullPath .. if allNumeric then `| {b.value} |` else "",
			allNumeric
		)
	end)

	return result
end

local function isColorValue(value: any): boolean
	return typeof(value) == "Color3" or isColorStyle(value)
end

local function TokenItem(props: {
	category: string,
	fullPath: string,
	value: () -> any,
	LayoutOrder: () -> number,
	isOdd: () -> boolean,
	alternateRowBackgrounds: () -> boolean,
})
	local value = props.value

	return VF.View({
		tag = function()
			return "row gap-small size-full-0 auto-y"
				.. (if props.isOdd() and props.alternateRowBackgrounds() then " bg-surface-100" else "")
		end,
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				tag = "auto-y text-body-medium text-align-x-left",
				Size = UDim2.fromScale(0.5, 0),
				Text = `{props.category}.{props.fullPath}`,
				LayoutOrder = 1,
			}),
			Vide.show(function()
				return isColorValue(value())
			end, function()
				return VF.View({
					tag = "size-500-500 radius-small",
					backgroundStyle = function(): ColorStyleValue
						local current = value()
						if typeof(current) == "Color3" then
							return { Color3 = current, Transparency = 0 }
						end
						return if isColorStyle(current) then current else { Transparency = 1 }
					end,
					LayoutOrder = 2,
				})
			end),
			VF.Text({
				tag = "size-0-0 auto-xy text-caption-large text-align-x-left",
				Text = function()
					return formatTokenValue(value())
				end,
				LayoutOrder = 3,
			}),
		},
	})
end

--* Rows are keyed by token path, like React's `key`, so a theme switch or a search updates the rows in place.
local function TokenRows(props: {
	tokens: () -> any,
	items: () -> { TokenItem },
	searchText: () -> string,
	category: string,
	firstLayoutOrder: number,
	alternateRowBackgrounds: () -> boolean,
})
	local paths = Vide.derive(function()
		local list = {}
		for index, token in filterAndSortTokens(props.items(), props.searchText(), props.category) do
			list[index] = token.fullPath
		end
		return list
	end)

	local rows = Vide.values(paths, function(fullPath: string, index: () -> number)
		return TokenItem({
			category = props.category,
			fullPath = fullPath,
			value = function()
				return getTokenValue(props.tokens(), `{props.category}.{fullPath}`)
			end,
			LayoutOrder = function()
				return props.firstLayoutOrder + index() - 1
			end,
			isOdd = function()
				return index() % 2 == 1
			end,
			alternateRowBackgrounds = props.alternateRowBackgrounds,
		})
	end)

	return rows, function(): boolean
		return #paths() > 0
	end
end

type SectionProps = {
	tokens: () -> any,
	collected: () -> { [string]: any },
	searchText: () -> string,
	category: string,
	alternateRowBackgrounds: () -> boolean,
}

local function TokenSubsection(props: SectionProps & { subcategory: string, LayoutOrder: number })
	local rows, hasRows = TokenRows({
		tokens = props.tokens,
		items = function()
			local categoryTokens = props.collected()[props.category]
			return categoryTokens and categoryTokens[props.subcategory] or {}
		end,
		searchText = props.searchText,
		category = props.category,
		firstLayoutOrder = 1,
		alternateRowBackgrounds = props.alternateRowBackgrounds,
	})

	return VF.View({
		tag = "col gap-small size-full-0 auto-y",
		Visible = hasRows,
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.subcategory,
				tag = "size-full-0 auto-y padding-top-medium text-title-medium text-align-x-left",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "col gap-small size-full-0 auto-y",
				LayoutOrder = 2,
				children = rows,
			}),
		},
	})
end

local function TokenSection(props: SectionProps & { subcategories: { string }?, LayoutOrder: number })
	local children
	local isVisible: () -> boolean
	local subcategories = props.subcategories
	if subcategories then
		isVisible = function()
			local searchText = props.searchText()
			local categoryTokens = props.collected()[props.category] or {}
			for _, subcategory in subcategories do
				for _, token in categoryTokens[subcategory] or {} do
					if matchesSearch(token, searchText, props.category) then
						return true
					end
				end
			end
			return false
		end

		children = {}
		for index, subcategory in subcategories do
			children[index] = TokenSubsection({
				tokens = props.tokens,
				collected = props.collected,
				searchText = props.searchText,
				category = props.category,
				alternateRowBackgrounds = props.alternateRowBackgrounds,
				subcategory = subcategory,
				LayoutOrder = 2 + index,
			})
		end
	else
		children, isVisible = TokenRows({
			tokens = props.tokens,
			items = function()
				return props.collected()[props.category] or {}
			end,
			searchText = props.searchText,
			category = props.category,
			firstLayoutOrder = 3,
			alternateRowBackgrounds = props.alternateRowBackgrounds,
		})
	end

	return VF.View({
		tag = "col gap-medium size-full-0 auto-y",
		Visible = isVisible,
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.category,
				tag = "size-full-0 auto-y text-heading-small text-align-x-left",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "col gap-small size-full-0 auto-y",
				LayoutOrder = 2,
				children = children,
			}),
		},
	})
end

local function collectAllTokens(tokens: any, flattenColors: boolean): { [string]: any }
	local collected = {}
	for _, category in orderedTokenCategories do
		local categoryTokens = tokens[category]
		if categoryTokens then
			collected[category] = if hasSubcategories(categoryTokens)
				then collectTokensWithSubcategories(categoryTokens, category, nil, flattenColors)
				else collectTokens(categoryTokens, category, nil, flattenColors)
		end
	end
	return collected
end

-- The sorted subcategory names of a collected category, or nil when its tokens are a flat list.
local function getSubcategories(categoryTokens: { [any]: any }): { string }?
	local subcategories = {}
	for key, value in categoryTokens do
		if type(value) == "table" and type(key) == "string" then
			table.insert(subcategories, key)
		end
	end
	if #subcategories == 0 then
		return nil
	end
	table.sort(subcategories, function(a: string, b: string)
		return sortTokens(a, b)
	end)
	return subcategories
end

local function TokensStory(controls: { [string]: any })
	local tokens = VF.Hooks.useTokens()
	local collected = Vide.derive(function()
		return collectAllTokens(tokens(), controls.flattenColors())
	end)

	-- The categories and subcategories shown; the rows inside follow `collected` on their own.
	local structure = Vide.derive(function()
		local parts = {}
		for _, category in orderedTokenCategories do
			local categoryTokens = collected()[category]
			if categoryTokens then
				local subcategories = getSubcategories(categoryTokens)
				table.insert(parts, `{category}:{if subcategories then table.concat(subcategories, ",") else ""}`)
			end
		end
		return table.concat(parts, ";")
	end)

	return foundation.scroll(foundation.rebuildOn(structure, function()
		local sections = {}
		for _, category in orderedTokenCategories do
			local categoryTokens = Vide.untrack(collected)[category]
			if categoryTokens then
				table.insert(
					sections,
					TokenSection({
						tokens = tokens,
						collected = collected,
						searchText = controls.searchText,
						category = category,
						alternateRowBackgrounds = controls.alternateRowBackgrounds,
						subcategories = getSubcategories(categoryTokens),
						LayoutOrder = #sections + 1,
					})
				)
			end
		end

		return VF.View({
			tag = "col gap-xlarge size-full-0 auto-y",
			children = sections,
		})
	end))
end

return foundation.single({
	controls = {
		searchText = "",
		flattenColors = true,
		alternateRowBackgrounds = false,
	},
	story = TokensStory,
})
