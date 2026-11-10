local LocalizationService = require("../../Utility/Wrappers").Services.LocalizationService
local Translator = require("../../Utility/Localization/Translator")

local DATE_COMPOSITE_TOKEN = "L"
local TIME_COMPOSITE_TOKEN = "LT"

export type DateRange = {
	startDate: DateTime,
	endDate: DateTime,
}

-- Roblox types ToLocalTime() as { any }; this is the typed boundary for calendar code.
export type DateTimeLocalTime = {
	Year: number,
	Month: number,
	Day: number,
	Hour: number,
	Minute: number,
	Second: number,
}

local monthMap = {
	[1] = Translator:FormatByKey("CommonUI.Controls.Label.January"),
	[2] = Translator:FormatByKey("CommonUI.Controls.Label.February"),
	[3] = Translator:FormatByKey("CommonUI.Controls.Label.March"),
	[4] = Translator:FormatByKey("CommonUI.Controls.Label.April"),
	[5] = Translator:FormatByKey("CommonUI.Controls.Label.May"),
	[6] = Translator:FormatByKey("CommonUI.Controls.Label.June"),
	[7] = Translator:FormatByKey("CommonUI.Controls.Label.July"),
	[8] = Translator:FormatByKey("CommonUI.Controls.Label.August"),
	[9] = Translator:FormatByKey("CommonUI.Controls.Label.September"),
	[10] = Translator:FormatByKey("CommonUI.Controls.Label.October"),
	[11] = Translator:FormatByKey("CommonUI.Controls.Label.November"),
	[12] = Translator:FormatByKey("CommonUI.Controls.Label.December"),
}

local weekdays = {
	[1] = Translator:FormatByKey("CommonUI.Controls.Label.SundayAbbreviated"),
	[2] = Translator:FormatByKey("CommonUI.Controls.Label.MondayAbbreviated"),
	[3] = Translator:FormatByKey("CommonUI.Controls.Label.TuesdayAbbreviated"),
	[4] = Translator:FormatByKey("CommonUI.Controls.Label.WednesdayAbbreviated"),
	[5] = Translator:FormatByKey("CommonUI.Controls.Label.ThursdayAbbreviated"),
	[6] = Translator:FormatByKey("CommonUI.Controls.Label.FridayAbbreviated"),
	[7] = Translator:FormatByKey("CommonUI.Controls.Label.SaturdayAbbreviated"),
}

local function getDaysInMonth(month: number, year: number): number
	local daysInMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
	if month == 2 then
		if (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0) then
			return 29
		end
	end
	return daysInMonth[month]
end

--- `dateTime:ToLocalTime()` with its fields typed.
local function toLocalTime(dateTime: DateTime): DateTimeLocalTime
	return dateTime:ToLocalTime() :: DateTimeLocalTime
end

--- Weekday of the first day of a month, 0 for Sunday through 6 for Saturday.
local function getFirstDayOfWeek(month: number, year: number): number
	local dateTime = DateTime.fromLocalTime(year, month, 1)

	if dateTime then
		local weekday = dateTime:FormatLocalTime("d", "en-us")
		return tonumber(weekday) or 0
	end

	return 0
end

--- Weekday of the last day of a month, 0 for Sunday through 6 for Saturday.
local function getLastDayOfWeek(month: number, year: number): number
	local dateTime = DateTime.fromLocalTime(year, month, getDaysInMonth(month, year))

	if dateTime then
		local weekday = dateTime:FormatLocalTime("d", "en-us")
		return tonumber(weekday) or 0
	end

	return 0
end

--- Unix timestamp of the local start of `dateTime`'s day.
local function roundToStartOfDay(dateTime: DateTime): number
	local localTime = toLocalTime(dateTime)
	return DateTime.fromLocalTime(localTime.Year, localTime.Month, localTime.Day).UnixTimestamp
end

local function roundDownToNearestMinute(dateTime: DateTime): DateTime
	local localTime = toLocalTime(dateTime)
	return DateTime.fromLocalTime(localTime.Year, localTime.Month, localTime.Day, localTime.Hour, localTime.Minute, 0)
end

--- Whether `date` falls inside the range, comparing whole days.
local function isDateWithinRange(date: DateTime, selectableDateRange: DateRange): boolean
	local startTimestamp = roundToStartOfDay(selectableDateRange.startDate)
	local endTimestamp = roundToStartOfDay(selectableDateRange.endDate)
	local checkTimestamp = roundToStartOfDay(date)

	return checkTimestamp >= startTimestamp and checkTimestamp <= endTimestamp
end

local function getPrevMonthInfo(month: number, year: number): (number, number)
	if month == 1 then
		return 12, year - 1
	end
	return month - 1, year
end

local function getNextMonthInfo(month: number, year: number): (number, number)
	if month == 12 then
		return 1, year + 1
	end
	return month + 1, year
end

local function formatLocalTime(dateTime: DateTime, includeTime: boolean?): string
	local localDateTime = dateTime:FormatLocalTime(DATE_COMPOSITE_TOKEN, LocalizationService.RobloxLocaleId)
	if includeTime then
		localDateTime = localDateTime
			.. ", "
			.. dateTime:FormatLocalTime(TIME_COMPOSITE_TOKEN, LocalizationService.RobloxLocaleId)
	end

	return localDateTime
end

return {
	formatLocalTime = formatLocalTime,
	getDaysInMonth = getDaysInMonth,
	getFirstDayOfWeek = getFirstDayOfWeek,
	getLastDayOfWeek = getLastDayOfWeek,
	getNextMonthInfo = getNextMonthInfo,
	getPrevMonthInfo = getPrevMonthInfo,
	isDateWithinRange = isDateWithinRange,
	monthMap = monthMap,
	roundDownToNearestMinute = roundDownToNearestMinute,
	roundToStartOfDay = roundToStartOfDay,
	toLocalTime = toLocalTime,
	weekdays = weekdays,
}
