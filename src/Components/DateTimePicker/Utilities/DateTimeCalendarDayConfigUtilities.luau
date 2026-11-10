
local DateTimeCalendarConstants = require("./DateTimeCalendarConstants")
local DateTimeCalendarViewUtilities = require("./DateTimeCalendarViewUtilities")
local DateTimePickerCalendarDayKeyPrefix = require("../../../Enums/DateTimePickerCalendarDayKeyPrefix")
local DateTimeUtilities = require("../DateTimeUtilities")
type CalendarDayKeyPrefix = DateTimePickerCalendarDayKeyPrefix.DateTimePickerCalendarDayKeyPrefix
type ViewDate = DateTimeCalendarViewUtilities.ViewDate

local DAYS_PER_WEEK = DateTimeCalendarConstants.DAYS_PER_WEEK
local NUM_ELEMENTS_IN_DATES_GRID = DateTimeCalendarConstants.NUM_ELEMENTS_IN_DATES_GRID
local NUM_NON_DAY_ELEMENTS = DateTimeCalendarConstants.NUM_NON_DAY_ELEMENTS
local NUM_WEEKDAY_HEADERS = DateTimeCalendarConstants.NUM_WEEKDAY_HEADERS

export type DayCellConfig = {
	applyEmphasis: boolean?,
	day: number,
	keyPrefix: CalendarDayKeyPrefix,
	LayoutOrder: number,
	month: number,
	year: number,
}

export type PaneCellConfig = {
	-- nil day means an empty spacer cell (leading/trailing padding).
	day: number?,
	key: string,
	LayoutOrder: number,
	month: number?,
	year: number?,
}

local function countLeadingPadDays(month: number, year: number): number
	local firstDayOfWeek = DateTimeUtilities.getFirstDayOfWeek(month, year)
	--* The fixed six-week grid shows a whole previous-month week when the month starts on Sunday.
	return if firstDayOfWeek == 0 then DAYS_PER_WEEK else firstDayOfWeek
end

local function countTrailingEmptyDays(leadingEmptyDays: number, daysInMonth: number): number
	return (DAYS_PER_WEEK - ((leadingEmptyDays + daysInMonth) % DAYS_PER_WEEK)) % DAYS_PER_WEEK
end

--- The day cells of CalendarGrid's fixed six-week grid: the end of the previous month, the month, then the next
--- month until 50 grid children (layout, 7 weekday headers, 42 days).
local function buildCalendarDayConfigs(viewDate: ViewDate): { DayCellConfig }
	local configs = {} :: { DayCellConfig }
	local index = NUM_WEEKDAY_HEADERS + 1

	local prevMonth, prevYear = DateTimeUtilities.getPrevMonthInfo(viewDate.month, viewDate.year)
	local prevMonthNumDays = DateTimeUtilities.getDaysInMonth(prevMonth, prevYear)
	local prevDaysToShow = countLeadingPadDays(viewDate.month, viewDate.year)

	for i = 1, prevDaysToShow do
		local day = prevMonthNumDays - prevDaysToShow + i
		table.insert(configs, {
			day = day,
			keyPrefix = DateTimePickerCalendarDayKeyPrefix.PrevMonth,
			LayoutOrder = index,
			month = prevMonth,
			year = prevYear,
		})
		index += 1
	end

	for day = 1, DateTimeUtilities.getDaysInMonth(viewDate.month, viewDate.year) do
		table.insert(configs, {
			applyEmphasis = true,
			day = day,
			keyPrefix = DateTimePickerCalendarDayKeyPrefix.CurrentMonth,
			LayoutOrder = index,
			month = viewDate.month,
			year = viewDate.year,
		})
		index += 1
	end

	local lastDayOfWeek = DateTimeUtilities.getLastDayOfWeek(viewDate.month, viewDate.year)
	local nextMonth, nextYear = DateTimeUtilities.getNextMonthInfo(viewDate.month, viewDate.year)
	local nextDaysToShow = DAYS_PER_WEEK - (lastDayOfWeek + 1)

	local elementsSoFar = NUM_NON_DAY_ELEMENTS + #configs
	if nextDaysToShow + elementsSoFar < NUM_ELEMENTS_IN_DATES_GRID then
		nextDaysToShow += NUM_ELEMENTS_IN_DATES_GRID - elementsSoFar - nextDaysToShow
	end

	for day = 1, nextDaysToShow do
		table.insert(configs, {
			day = day,
			keyPrefix = DateTimePickerCalendarDayKeyPrefix.NextMonth,
			LayoutOrder = index,
			month = nextMonth,
			year = nextYear,
		})
		index += 1
	end

	return configs
end

--- The cells of a TwoMonthCalendar pane: empty spacers up to the first weekday, the month, spacers to finish the week.
local function buildTwoMonthPaneCellConfigs(month: number, year: number): { PaneCellConfig }
	local configs = {} :: { PaneCellConfig }
	local LayoutOrder = NUM_WEEKDAY_HEADERS + 1

	local leadingEmptyDays = DateTimeUtilities.getFirstDayOfWeek(month, year)
	for i = 1, leadingEmptyDays do
		table.insert(configs, {
			key = `lead-{i}`,
			LayoutOrder = LayoutOrder,
		})
		LayoutOrder += 1
	end

	local daysInMonth = DateTimeUtilities.getDaysInMonth(month, year)
	for day = 1, daysInMonth do
		table.insert(configs, {
			day = day,
			key = `day-{day}`,
			LayoutOrder = LayoutOrder,
			month = month,
			year = year,
		})
		LayoutOrder += 1
	end

	for i = 1, countTrailingEmptyDays(leadingEmptyDays, daysInMonth) do
		table.insert(configs, {
			key = `trail-{i}`,
			LayoutOrder = LayoutOrder,
		})
		LayoutOrder += 1
	end

	return configs
end

return {
	buildCalendarDayConfigs = buildCalendarDayConfigs,
	buildTwoMonthPaneCellConfigs = buildTwoMonthPaneCellConfigs,
}
