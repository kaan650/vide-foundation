local DateTimePickerRangeBandRoleEnum = require("../../../Enums/DateTimePickerRangeBandRole")
local DateTimeUtilities = require("../DateTimeUtilities")
local LocalizationService = require("../../../Utility/Wrappers").Services.LocalizationService

type DateRange = DateTimeUtilities.DateRange
type RangeBandRole = DateTimePickerRangeBandRoleEnum.DateTimePickerRangeBandRole

type TimeSlot = {
	id: number,
	text: string,
}

export type ViewDate = {
	month: number,
	year: number,
}

local TIME_COMPOSITE_TOKEN = "LT"
local HALF_HOUR_SECONDS = 30 * 60
local LAST_HALF_HOUR_SLOT_SECONDS = 47 * HALF_HOUR_SECONDS

--- The month and year to show for `dateTime`.
local function toViewDate(dateTime: DateTime): ViewDate
	local localTime = DateTimeUtilities.toLocalTime(dateTime)
	return { month = localTime.Month, year = localTime.Year }
end

--- `dateTime` rounded up to the next half hour of the same day, at most 23:30.
local function roundUpToNearestHalfHour(dateTime: DateTime): DateTime
	local localTime = DateTimeUtilities.toLocalTime(dateTime)
	if localTime.Second == 0 and (localTime.Minute == 0 or localTime.Minute == 30) then
		return DateTimeUtilities.roundDownToNearestMinute(dateTime)
	end

	local startOfDay = DateTimeUtilities.roundToStartOfDay(dateTime)
	local secondsSinceMidnight = dateTime.UnixTimestamp - startOfDay
	local roundedSeconds = math.ceil(secondsSinceMidnight / HALF_HOUR_SECONDS) * HALF_HOUR_SECONDS
	roundedSeconds = math.min(roundedSeconds, LAST_HALF_HOUR_SLOT_SECONDS)

	return DateTime.fromUnixTimestamp(startOfDay + roundedSeconds)
end

--- The date whose month the calendar shows: the first selected date, else `referenceDate`, else today.
local function resolveAnchorDate(defaultDates: { DateTime }?, referenceDate: DateTime?): DateTime
	if defaultDates and defaultDates[1] then
		return defaultDates[1]
	end
	if referenceDate then
		return referenceDate
	end
	return DateTime.now()
end

--- The 48 half-hour slots of `dateTime`'s day (unix timestamp id and localized label), and the id of the slot
--- `dateTime` rounds up to. The selected id is rebuilt from the rounded wall clock with fromLocalTime, as the slot ids
--- are: a DST-adjusted draft can have another timestamp while showing the same local time.
local function getTimeSlotsForDay(dateTime: DateTime): ({ TimeSlot }, number)
	local roundedDateTime = roundUpToNearestHalfHour(dateTime)
	local localDateTime = DateTimeUtilities.toLocalTime(roundedDateTime)
	local selectedId = DateTime.fromLocalTime(
		localDateTime.Year,
		localDateTime.Month,
		localDateTime.Day,
		localDateTime.Hour,
		localDateTime.Minute,
		0
	).UnixTimestamp

	local slots: { TimeSlot } = {}

	for i = 0, 47 do
		local hours = math.floor(i / 2)
		local minutes = (i % 2) * 30

		local slotDateTime =
			DateTime.fromLocalTime(localDateTime.Year, localDateTime.Month, localDateTime.Day, hours, minutes, 0)

		table.insert(slots, {
			id = slotDateTime.UnixTimestamp,
			text = slotDateTime:FormatLocalTime(TIME_COMPOSITE_TOKEN, LocalizationService.RobloxLocaleId),
		})
	end

	return slots, selectedId
end

local function getTimeSlotIndex(slots: { TimeSlot }, selectedId: number?): number?
	if selectedId == nil then
		return nil
	end
	for index, slot in slots do
		if slot.id == selectedId then
			return index
		end
	end
	return nil
end

--- 0 for Sunday through 6 for Saturday.
local function getDayOfWeek(dateTime: DateTime): number
	local weekday = dateTime:FormatLocalTime("d", "en-us")
	return tonumber(weekday) or 0
end

--- Start-of-day timestamps of the range ends, lowest first.
local function getRangeDayBounds(range: DateRange): (number, number)
	local startDay = DateTimeUtilities.roundToStartOfDay(range.startDate)
	local endDay = DateTimeUtilities.roundToStartOfDay(range.endDate)
	return math.min(startDay, endDay), math.max(startDay, endDay)
end

--- The radius tag for a day in a range band, rounded at row edges and at the range ends.
local function getRangeBandRadiusTag(dateTime: DateTime, range: DateRange, bandRole: RangeBandRole): string
	local lo, hi = getRangeDayBounds(range)
	local day = DateTimeUtilities.roundToStartOfDay(dateTime)
	local prevInRange = day > lo
	local nextInRange = day < hi
	local dayOfWeek = getDayOfWeek(dateTime)

	local roundLeft = if bandRole == DateTimePickerRangeBandRoleEnum.Start
		then false
		else dayOfWeek == 0 or not prevInRange
	local roundRight = if bandRole == DateTimePickerRangeBandRoleEnum.End
		then false
		else dayOfWeek == 6 or not nextInRange

	if roundLeft and roundRight then
		return "radius-circle"
	elseif roundLeft then
		return "radius-left-circle"
	elseif roundRight then
		return "radius-right-circle"
	end
	return ""
end

return {
	getDayOfWeek = getDayOfWeek,
	getRangeBandRadiusTag = getRangeBandRadiusTag,
	getRangeDayBounds = getRangeDayBounds,
	getTimeSlotIndex = getTimeSlotIndex,
	getTimeSlotsForDay = getTimeSlotsForDay,
	resolveAnchorDate = resolveAnchorDate,
	roundUpToNearestHalfHour = roundUpToNearestHalfHour,
	toViewDate = toViewDate,
}
