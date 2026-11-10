local DateTimeUtilities = require("../DateTimeUtilities")

type DateRange = DateTimeUtilities.DateRange

local function isRangeWithinSelectableRange(range: DateRange, selectableDateRange: DateRange): boolean
	return DateTimeUtilities.isDateWithinRange(range.startDate, selectableDateRange)
		and DateTimeUtilities.isDateWithinRange(range.endDate, selectableDateRange)
end

local function isSameDay(a: DateTime, b: DateTime): boolean
	return DateTimeUtilities.roundToStartOfDay(a) == DateTimeUtilities.roundToStartOfDay(b)
end

--- Whether a complete draft covers the same days as `range`.
local function areDatesSameDayAsRange(dates: { DateTime }?, range: DateRange): boolean
	if not dates or not dates[1] or not dates[2] then
		return false
	end
	return isSameDay(dates[1], range.startDate) and isSameDay(dates[2], range.endDate)
end

local function areDatesEqual(left: { DateTime }?, right: { DateTime }?): boolean
	if left == nil and right == nil then
		return true
	end
	if left == nil or right == nil then
		return false
	end

	local leftStart = left[1] :: DateTime?
	local rightStart = right[1] :: DateTime?
	if (leftStart == nil) ~= (rightStart == nil) then
		return false
	end
	if leftStart and rightStart and leftStart.UnixTimestamp ~= rightStart.UnixTimestamp then
		return false
	end

	local leftEnd = left[2] :: DateTime?
	local rightEnd = right[2] :: DateTime?
	if (leftEnd == nil) ~= (rightEnd == nil) then
		return false
	end
	if leftEnd and rightEnd and leftEnd.UnixTimestamp ~= rightEnd.UnixTimestamp then
		return false
	end

	return true
end

return {
	areDatesEqual = areDatesEqual,
	areDatesSameDayAsRange = areDatesSameDayAsRange,
	isRangeWithinSelectableRange = isRangeWithinSelectableRange,
	isSameDay = isSameDay,
}
