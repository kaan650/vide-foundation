local Wrappers = require("../Wrappers")
local LocalizationService = Wrappers.Services.LocalizationService

local Constants = require("./Constants")
local GeneratedTranslations = require("../../Generated/Translations/GeneratedTranslations")

--* The table lives under the package root, as Foundation keeps it under its own root.
local localizationTableParent: Instance = script.Parent.Parent.Parent

local function createFoundationLocalizationTable(parent: Instance): LocalizationTable
	local existing = parent:FindFirstChild(Constants.LOCALIZATION_TABLE_NAME)
	if existing ~= nil and existing:IsA("LocalizationTable") then
		existing:SetEntries(GeneratedTranslations)
		return existing
	end

	local localizationTable = Instance.new("LocalizationTable")
	localizationTable.Name = Constants.LOCALIZATION_TABLE_NAME
	localizationTable.Archivable = false
	localizationTable.SourceLocaleId = "en-us"
	localizationTable:SetEntries(GeneratedTranslations)
	localizationTable.Parent = parent
	return localizationTable
end

local localizationTable = createFoundationLocalizationTable(localizationTableParent)
local translatorsCache: { [string]: Translator } = {}

local function getTranslatorForLocale(locale: string): Translator
	if localizationTable.Parent == nil then
		localizationTable = createFoundationLocalizationTable(localizationTableParent)
		translatorsCache = {}
	end

	local translator = translatorsCache[locale]
	if translator then
		return translator
	end
	translator = localizationTable:GetTranslator(locale)
	translatorsCache[locale] = translator
	return translator
end

local function getTranslator(): Translator
	return getTranslatorForLocale(LocalizationService.RobloxLocaleId)
end

local function formatByKeyWithFallback(key: string, args: { [string]: any }?, translator: Translator): string
	local success, result = pcall(function()
		return translator:FormatByKey(key, args)
	end)

	if success then
		return result
	elseif translator.LocaleId == "zh-cjv" then
		return ""
	end
	return getTranslatorForLocale("en-us"):FormatByKey(key, args)
end

local RobloxTranslator = {}

--- Foundation's string for `key` in the user's Roblox locale, falling back to English.
function RobloxTranslator:FormatByKey(key: string, args: { [string]: any }?): string
	return formatByKeyWithFallback(key, args, getTranslator())
end

--- Foundation's string for `key` in `locale`, falling back to English.
function RobloxTranslator:FormatByKeyForLocale(key: string, locale: string, args: { [string]: any }?): string
	return formatByKeyWithFallback(key, args, getTranslatorForLocale(locale))
end

return RobloxTranslator
