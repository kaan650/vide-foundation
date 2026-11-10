-- One StyleSheet per appearance (theme, color mode, device, scale, overrides), shared by every provider in this copy
-- of VideFoundation. Rules are created only for tags in use, so the sheet never holds the tens of thousands of
-- generated rules.
local ColorMode = require("../Enums/ColorMode")
local Device = require("../Enums/Device")
local ThemeName = require("../Enums/ThemeName")
local Tokens = require("../Providers/Style/Tokens")
local Types = require("./Rules/Types")
local getGeneratedRules = require("../Utility/getGeneratedRules")
local getOverrideAttributes = require("./getOverrideAttributes")

type ColorMode = ColorMode.ColorMode
type Device = Device.Device
type ThemeName = ThemeName.ThemeName
type TokenOverrides = Tokens.TokenOverrides
type StyleRuleNoTag = Types.StyleRuleNoTag
type OverrideAttributes = getOverrideAttributes.OverrideAttributes

--* Story tools such as UI Labs load fresh copies of the package for every story; sharing the folder keeps them from
--* leaving one empty folder per load. Each copy still tracks and destroys only its own sheets.
local registryFolder = script.Parent.Parent:FindFirstChild("FoundationStyleSheets")
if not registryFolder then
	registryFolder = Instance.new("Folder")
	registryFolder.Name = "FoundationStyleSheets"
	registryFolder.Archivable = false
	registryFolder.Parent = script.Parent.Parent
end

type FoundationStyleSheet = {
	themeName: ThemeName,
	colorMode: ColorMode,
	device: Device,
	scale: number,
	tokenOverrides: TokenOverrides?,
	overrideAttributes: OverrideAttributes,
	instance: StyleSheet,
	tags: { [string]: boolean },
	rules: { [string]: StyleRuleNoTag },
	attributes: { [string]: boolean },
	refCount: number,
}

local styleSheetRegistry: { [StyleSheet]: FoundationStyleSheet } = {}

local CLEANUP_DELAY_SECONDS = 5
local pendingCleanup: { [StyleSheet]: boolean } = {}
local isFlushScheduled = false

local function createStyleSheet(
	colorMode: ColorMode,
	device: Device,
	scale: number,
	tokenOverrides: TokenOverrides?,
	themeName: ThemeName
): FoundationStyleSheet
	local styleSheet = Instance.new("StyleSheet")
	styleSheet.Name = if tokenOverrides ~= nil
		then `{themeName}-{colorMode}-{device}-{scale}-{tostring(tokenOverrides)}`
		else `{themeName}-{colorMode}-{device}-{scale}`
	styleSheet.Archivable = false
	styleSheet.Parent = registryFolder
	return {
		themeName = themeName,
		colorMode = colorMode,
		device = device,
		scale = scale,
		tokenOverrides = tokenOverrides,
		overrideAttributes = getOverrideAttributes(themeName, colorMode, device, tokenOverrides),
		instance = styleSheet,
		tags = {},
		rules = getGeneratedRules(themeName, colorMode, device),
		attributes = {},
		refCount = 0,
	}
end

local function createStyleRule(rule: StyleRuleNoTag, tag: string): StyleRule
	local tagSelector = "." .. tag
	local modifier = if rule.modifier ~= nil then ":" .. rule.modifier else ""
	local pseudo = if rule.pseudo ~= nil then " ::" .. rule.pseudo else ""
	local selector = tagSelector .. modifier .. pseudo

	if rule.pseudoName ~= nil then
		selector = selector .. " #" .. rule.pseudoName
	end
	--! A named pseudo-instance (`::UIShadow #layer1`) is its own phantom instance. Without a name, the rule also
	--! targets a real child of that class, but stacked named layers must not, or they would merge onto one child.
	if rule.pseudo ~= nil and rule.pseudoName == nil then
		selector = selector .. ", " .. tagSelector .. modifier .. " > " .. rule.pseudo
	end

	local styleRule = Instance.new("StyleRule")
	styleRule.Name = selector
	styleRule.Priority = rule.priority or 1
	styleRule.Selector = selector
	styleRule:SetProperties(rule.properties)
	return styleRule
end

local function applyAttributes(sheet: FoundationStyleSheet, attributes: { Types.StyleAttribute<unknown> }?)
	if not attributes then
		return
	end

	for _, attribute in attributes do
		if sheet.attributes[attribute.name] then
			continue
		end

		local overrideValue = sheet.overrideAttributes[attribute.name]
		local value = if overrideValue ~= nil then overrideValue else attribute.value
		sheet.attributes[attribute.name] = true
		sheet.instance:SetAttribute(attribute.name, value :: any)
	end
end

local function addRegisteredStyleSheetTags(sheet: FoundationStyleSheet, tags: { string })
	for _, tag in tags do
		if sheet.tags[tag] then
			continue
		end
		local rule = sheet.rules[tag]
		if not rule then
			continue
		end

		createStyleRule(rule, tag).Parent = sheet.instance
		applyAttributes(sheet, rule.attributes)
		if rule.children then
			for _, child in rule.children do
				createStyleRule(child, child.tag).Parent = sheet.instance
				applyAttributes(sheet, child.attributes)
			end
		end
		sheet.tags[tag] = true
	end
end

--- Looks up, or creates and registers, the sheet for an appearance without taking a reference.
--- `tokenOverrides` is compared by reference: pass the same table every time, or each call makes a new sheet.
local function resolveStyleSheet(
	colorMode: ColorMode,
	deviceInput: Device?,
	scaleInput: number?,
	tokenOverrides: TokenOverrides?,
	themeNameInput: ThemeName?
): StyleSheet
	local device: Device = deviceInput or Device.Desktop
	local scale = scaleInput or 1
	local themeName: ThemeName = themeNameInput or ThemeName.Default
	for instance, foundationStyleSheet in styleSheetRegistry do
		if
			foundationStyleSheet.themeName == themeName
			and foundationStyleSheet.colorMode == colorMode
			and foundationStyleSheet.device == device
			and foundationStyleSheet.scale == scale
			and foundationStyleSheet.tokenOverrides == tokenOverrides
		then
			pendingCleanup[instance] = nil
			return instance
		end
	end
	local foundationStyleSheet = createStyleSheet(colorMode, device, scale, tokenOverrides, themeName)
	styleSheetRegistry[foundationStyleSheet.instance] = foundationStyleSheet
	return foundationStyleSheet.instance
end

local function addStyleTags(sheet: StyleSheet, tags: { string })
	local foundationStyleSheet = styleSheetRegistry[sheet]
	if not foundationStyleSheet then
		error("StyleSheet not found in registry")
	end
	addRegisteredStyleSheetTags(foundationStyleSheet, tags)
end

local function destroyStyleSheet(instance: StyleSheet)
	local sheet = styleSheetRegistry[instance]
	if sheet == nil or sheet.refCount > 0 then
		return
	end
	styleSheetRegistry[instance] = nil
	instance:Destroy()
end

local function flushPendingCleanup()
	isFlushScheduled = false
	for instance in pendingCleanup do
		pendingCleanup[instance] = nil
		destroyStyleSheet(instance)
	end
end

local function scheduleCleanup(instance: StyleSheet)
	pendingCleanup[instance] = true
	if isFlushScheduled then
		return
	end
	isFlushScheduled = true
	task.delay(CLEANUP_DELAY_SECONDS, flushPendingCleanup)
end

local function acquireStyleSheet(sheet: StyleSheet)
	local foundationStyleSheet = styleSheetRegistry[sheet]
	if foundationStyleSheet == nil then
		return
	end
	foundationStyleSheet.refCount += 1
	pendingCleanup[sheet] = nil
end

local function releaseStyleSheet(sheet: StyleSheet)
	local foundationStyleSheet = styleSheetRegistry[sheet]
	if foundationStyleSheet == nil or foundationStyleSheet.refCount == 0 then
		return
	end
	foundationStyleSheet.refCount -= 1
	if foundationStyleSheet.refCount == 0 then
		scheduleCleanup(sheet)
	end
end

--- Resolves the sheet for an appearance and takes a reference. Free it with `releaseStyleSheet`.
local function getStyleSheet(
	colorMode: ColorMode,
	deviceInput: Device?,
	scaleInput: number?,
	tokenOverrides: TokenOverrides?,
	themeNameInput: ThemeName?
): StyleSheet
	local sheet = resolveStyleSheet(colorMode, deviceInput, scaleInput, tokenOverrides, themeNameInput)
	acquireStyleSheet(sheet)
	return sheet
end

return {
	resolveStyleSheet = resolveStyleSheet,
	getStyleSheet = getStyleSheet,
	addStyleTags = addStyleTags,
	acquireStyleSheet = acquireStyleSheet,
	releaseStyleSheet = releaseStyleSheet,
	flushPendingCleanup = flushPendingCleanup,
}
