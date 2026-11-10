local DateTimeUtilities = require("../DateTimeUtilities")

--- `dates` as a list; single-date pickers keep only the first.
local function normalizeDates(options: {
	acceptsDateRange: boolean,
	dates: DateTime | { DateTime },
}): { DateTime }
	local normalized = if typeof(options.dates) == "table" then options.dates else { options.dates }
	local endDate = normalized[2] :: DateTime?
	if options.acceptsDateRange or endDate == nil then
		return normalized
	end
	return { normalized[1] }
end

--- The selection after clicking `dateTime`: a new start when empty or complete, else the range to it, in order.
local function selectRangeEndpoint(prev: { DateTime }?, dateTime: DateTime): { DateTime }
	if not prev or not prev[1] or prev[2] then
		return { dateTime }
	end

	local startDate = prev[1]
	if DateTimeUtilities.roundToStartOfDay(dateTime) < DateTimeUtilities.roundToStartOfDay(startDate) then
		return { dateTime, startDate }
	end
	return { startDate, dateTime }
end

return {
	normalizeDates = normalizeDates,
	selectRangeEndpoint = selectRangeEndpoint,
}
