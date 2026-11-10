local DateTimeCalendarViewUtilities = require("./DateTimeCalendarViewUtilities")
local DateTimePickerDateRangePresetEnum = require("../../../Enums/DateTimePickerDateRangePreset")
local DateTimeUtilities = require("../DateTimeUtilities")

type DateRange = DateTimeUtilities.DateRange
type DateRangePreset = DateTimePickerDateRangePresetEnum.DateTimePickerDateRangePreset

local SECONDS_PER_DAY = 24 * 60 * 60

local function toStartOfDay(dateTime: DateTime): DateTime
	local localTime = DateTimeUtilities.toLocalTime(dateTime)
	return DateTime.fromLocalTime(localTime.Year, localTime.Month, localTime.Day)
end

--* Shifts from local noon, so a daylight-saving change cannot move the result to another day.
local function shiftDays(dateTime: DateTime, deltaDays: number): DateTime
	local localTime = DateTimeUtilities.toLocalTime(dateTime)
	local noon = DateTime.fromLocalTime(localTime.Year, localTime.Month, localTime.Day, 12, 0, 0)
	return toStartOfDay(DateTime.fromUnixTimestamp(noon.UnixTimestamp + deltaDays * SECONDS_PER_DAY))
end

--- The inclusive range of a preset chip, relative to `referenceDate` (default now). Weeks start on Sunday.
local function resolvePresetRange(preset: DateRangePreset, referenceDate: DateTime?): DateRange
	local now = referenceDate or DateTime.now()
	local localTime = DateTimeUtilities.toLocalTime(now)
	local today = toStartOfDay(now)

	if preset == DateTimePickerDateRangePresetEnum.Today then
		return { startDate = today, endDate = today }
	elseif preset == DateTimePickerDateRangePresetEnum.ThisWeek then
		local weekStart = shiftDays(today, -DateTimeCalendarViewUtilities.getDayOfWeek(now))
		return { startDate = weekStart, endDate = shiftDays(weekStart, 6) }
	elseif preset == DateTimePickerDateRangePresetEnum.LastWeek then
		local lastWeekStart = shiftDays(today, -DateTimeCalendarViewUtilities.getDayOfWeek(now) - 7)
		return { startDate = lastWeekStart, endDate = shiftDays(lastWeekStart, 6) }
	elseif preset == DateTimePickerDateRangePresetEnum.ThisMonth then
		return {
			startDate = DateTime.fromLocalTime(localTime.Year, localTime.Month, 1),
			endDate = DateTime.fromLocalTime(
				localTime.Year,
				localTime.Month,
				DateTimeUtilities.getDaysInMonth(localTime.Month, localTime.Year)
			),
		}
	elseif preset == DateTimePickerDateRangePresetEnum.ThisYear then
		return {
			startDate = DateTime.fromLocalTime(localTime.Year, 1, 1),
			endDate = DateTime.fromLocalTime(localTime.Year, 12, 31),
		}
	else
		return {
			startDate = DateTime.fromLocalTime(localTime.Year - 1, 1, 1),
			endDate = DateTime.fromLocalTime(localTime.Year - 1, 12, 31),
		}
	end
end

return {
	resolvePresetRange = resolvePresetRange,
}
