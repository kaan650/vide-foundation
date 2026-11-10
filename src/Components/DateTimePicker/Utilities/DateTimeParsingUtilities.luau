local DateTimeEqualityUtilities = require("./DateTimeEqualityUtilities")
local DateTimePickerVariantEnum = require("../../../Enums/DateTimePickerVariant")
local DateTimeUtilities = require("../DateTimeUtilities")

type DateRange = DateTimeUtilities.DateRange
type DateTimePickerVariant = DateTimePickerVariantEnum.DateTimePickerVariant

--- Hours and minutes from a 12-hour (H:MM AM/PM) or 24-hour (HH:MM) time, or nil when it is not valid.
local function parseTimeFromText(timeStr: string): (number?, number?)
	local trimmedTimeStr = timeStr:gsub("%s+", "")

	local is24HourFormat = string.match(trimmedTimeStr, "^%d%d:%d%d$")
	local is12HourFormat = string.match(trimmedTimeStr, "^%d%d?:%d%d[AP]M$")

	if not is24HourFormat and not is12HourFormat then
		return nil, nil
	end

	local hours: number?, minutes: number?

	if is12HourFormat then
		local hourStr, minuteStr = string.match(trimmedTimeStr, "^(%d%d?):(%d%d)[AP]M$")
		local rawHours = tonumber(hourStr)
		minutes = tonumber(minuteStr)

		if not rawHours or not minutes or rawHours < 1 or rawHours > 12 or minutes < 0 or minutes > 59 then
			return nil, nil
		end

		if string.sub(trimmedTimeStr, -2) == "PM" and rawHours ~= 12 then
			hours = rawHours + 12
		elseif string.sub(trimmedTimeStr, -2) == "AM" and rawHours == 12 then
			hours = 0
		else
			hours = rawHours
		end
	else
		local hourStr, minuteStr = string.match(trimmedTimeStr, "^(%d%d?):(%d%d)$")
		hours = tonumber(hourStr)
		minutes = tonumber(minuteStr)

		if not hours or not minutes or hours < 0 or hours > 23 or minutes < 0 or minutes > 59 then
			return nil, nil
		end
	end

	return hours, minutes
end

--! Workaround for an engine bug where DateTime values in local zones that observe daylight saving time are offset
--! by an hour: subtracts one hour when the timestamp falls in DST. os.date returns nil for pre-1970 timestamps.
--! https://devforum.roblox.com/t/datetime-localtime-inconsistency/3548279/2
local function adjustForDaylightSaving(dateTime: DateTime): DateTime
	local dateInfo = os.date("*t", dateTime.UnixTimestamp)
	if dateInfo and dateInfo.isdst then
		return DateTime.fromUnixTimestamp(dateTime.UnixTimestamp - 3600)
	end
	return dateTime
end

--- Parses a date/time string into a DateTime, with the DST workaround applied.
--- Dates: MM/DD/YYYY or YYYY/MM/DD, delimited by /, . or -.
--- Times: 12-hour (HH:MM AM/PM) or 24-hour (HH:MM), after a comma.
local function parseDateTimeFromText(dateTimeStr: string): DateTime?
	local dateStr, timeStr = dateTimeStr, "00:00"

	if string.find(dateTimeStr, ",") then
		local matchedDate, matchedTime = dateTimeStr:match("^([^,]+),%s*(.+)$")
		if not matchedDate or not matchedTime then
			return nil
		end
		dateStr, timeStr = matchedDate, matchedTime
	end

	local trimmedDateStr = dateStr:gsub("%s+", "")
	local hours, minutes = parseTimeFromText(timeStr)
	if hours == nil or minutes == nil then
		return nil
	end

	local firstDelimiterPos = trimmedDateStr:find("[/%.%-]")

	local success, dateTime = pcall(function(): DateTime
		if firstDelimiterPos == 3 then
			local month, day, year = trimmedDateStr:match("^(%d%d)[/%.%-](%d%d)[/%.%-](%d%d%d%d)$")
			return DateTime.fromLocalTime(tonumber(year) :: number, tonumber(month), tonumber(day), hours, minutes, 0)
		elseif firstDelimiterPos == 5 then
			local year, month, day = trimmedDateStr:match("^(%d%d%d%d)[/%.%-](%d%d)[/%.%-](%d%d)$")
			return DateTime.fromLocalTime(tonumber(year) :: number, tonumber(month), tonumber(day), hours, minutes, 0)
		else
			error("Invalid date format: " .. trimmedDateStr)
		end
	end)

	if success and dateTime then
		return adjustForDaylightSaving(dateTime)
	end

	return nil
end

local function trimInputText(text: string): string
	return (text:gsub("^%s*(.-)%s*$", "%1"))
end

--- Both ends of typed range input, split on " - ". A missing or invalid side is nil; nothing is swapped or checked
--- against the selectable range.
local function parseDualInputEndpoints(text: string): (DateTime?, DateTime?)
	local parts = text:split(" - ")
	local startDateTime = if parts[1] then parseDateTimeFromText(trimInputText(parts[1])) else nil
	local endDateTime = if parts[2] then parseDateTimeFromText(trimInputText(parts[2])) else nil
	return startDateTime, endDateTime
end

--- A complete range draft from typed input: exactly two valid ends, swapped into order, inside
--- `selectableDateRange`. Anything else is nil.
local function parseInputToDraftDates(text: string, selectableDateRange: DateRange?): { DateTime }?
	local parts = text:split(" - ")
	if #parts ~= 2 then
		return nil
	end

	local startDateTime, endDateTime = parseDualInputEndpoints(text)
	if not startDateTime or not endDateTime then
		return nil
	end

	if DateTimeUtilities.roundToStartOfDay(startDateTime) > DateTimeUtilities.roundToStartOfDay(endDateTime) then
		startDateTime, endDateTime = endDateTime, startDateTime
	end

	if selectableDateRange then
		if
			not DateTimeEqualityUtilities.isRangeWithinSelectableRange({
				startDate = startDateTime,
				endDate = endDateTime,
			}, selectableDateRange)
		then
			return nil
		end
	end

	return { startDateTime, endDateTime }
end

--- The input text for a selection. Range variants show "start - " while the end is still missing.
local function formatInputText(options: {
	dates: { DateTime },
	variant: DateTimePickerVariant,
}): string
	local startDate = options.dates[1]
	if not startDate then
		return ""
	end

	local isDual = options.variant == DateTimePickerVariantEnum.Dual
		or options.variant == DateTimePickerVariantEnum.DualWithPresets
	if isDual then
		local endDate = options.dates[2]
		return `{DateTimeUtilities.formatLocalTime(startDate)} - {if endDate
			then DateTimeUtilities.formatLocalTime(endDate)
			else ""}`
	end

	local includeTime = options.variant == DateTimePickerVariantEnum.SingleWithTime
	return DateTimeUtilities.formatLocalTime(startDate, includeTime)
end

return {
	adjustForDaylightSaving = adjustForDaylightSaving,
	formatInputText = formatInputText,
	parseDateTimeFromText = parseDateTimeFromText,
	parseDualInputEndpoints = parseDualInputEndpoints,
	parseInputToDraftDates = parseInputToDraftDates,
	trimInputText = trimInputText,
}
