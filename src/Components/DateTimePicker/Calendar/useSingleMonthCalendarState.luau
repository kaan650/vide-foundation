local Vide = require("../../../Packages/Vide")

local DateTimeCalendarDayAppearanceUtilities = require("../Utilities/DateTimeCalendarDayAppearanceUtilities")
local DateTimeCalendarViewUtilities = require("../Utilities/DateTimeCalendarViewUtilities")
local DateTimeParsingUtilities = require("../Utilities/DateTimeParsingUtilities")
local DateTimeRangeSelectionUtilities = require("../Utilities/DateTimeRangeSelectionUtilities")
local DateTimeUtilities = require("../DateTimeUtilities")

type DateRange = DateTimeUtilities.DateRange
type DateTimeLocalTime = DateTimeUtilities.DateTimeLocalTime
type ViewDate = DateTimeCalendarViewUtilities.ViewDate

export type SingleMonthCalendarStateProps = {
	isDateRange: () -> boolean,
	onSelectedDateChanged: (dateTimes: { DateTime }) -> (),
	referenceDate: () -> DateTime?,
	selectableDateRange: () -> DateRange?,
	selectedDates: () -> { DateTime }?,
	showTimeList: () -> boolean,
	viewAnchorDate: () -> DateTime?,
}

export type SingleMonthCalendarState = {
	currViewDate: () -> ViewDate,
	handleDateActivated: (day: number, month: number, year: number) -> (),
	highlightDates: () -> { DateTime },
	isDateRange: () -> boolean,
	localSelectedDateTimes: () -> { DateTimeLocalTime },
	navigateToNextMonth: () -> (),
	navigateToPreviousMonth: () -> (),
	onHoverEnter: (dateTime: DateTime) -> (),
	onHoverLeave: () -> (),
	onTimeListItemChanged: (item: number) -> (),
	onViewDateChanged: (viewDate: ViewDate) -> (),
	selectedDateTimes: () -> { DateTime },
}

--- State of SingleMonthCalendar: the selection it shows (following `selectedDates`), the month on view, the range
--- hover preview, and day and time picks. Call it while the component is being created.
local function useSingleMonthCalendarState(props: SingleMonthCalendarStateProps): SingleMonthCalendarState
	local isDateRange = props.isDateRange

	--* Unbound (nil) starts empty for every variant: the view follows referenceDate / viewAnchorDate without
	--* highlighting a day, and in range mode a lone date means "picking the end".
	local resolvedSelectedDates = Vide.derive(function(): { DateTime }
		local dates = props.selectedDates()
		if dates then
			return DateTimeRangeSelectionUtilities.normalizeDates({
				acceptsDateRange = isDateRange(),
				dates = dates,
			})
		end
		return {}
	end)

	local selectedDateTimes = Vide.source(Vide.untrack(resolvedSelectedDates))
	local getSelectedDateTimes: () -> { DateTime } = selectedDateTimes

	Vide.effect(function()
		local resolved = resolvedSelectedDates()
		Vide.untrack(function()
			selectedDateTimes(resolved)
		end)
	end)

	local isAlive = true
	Vide.cleanup(function()
		isAlive = false
	end)

	Vide.effect(function()
		if props.selectedDates() then
			return
		end
		local resolved = resolvedSelectedDates()
		--! Deferred, as React runs effects after the render: the parent answers by writing selectedDates, which this
		--! effect reads, and a write inside the effect re-enters it and breaks Vide's update queue.
		task.defer(function()
			if isAlive and Vide.untrack(props.selectedDates) == nil then
				props.onSelectedDateChanged(resolved)
			end
		end)
	end)

	local localSelectedDateTimes = Vide.derive(function(): { DateTimeLocalTime }
		local localTimes: { DateTimeLocalTime } = {}
		for _, dateTime in selectedDateTimes() do
			table.insert(localTimes, DateTimeUtilities.toLocalTime(dateTime))
		end
		return localTimes
	end)

	local currViewDate = Vide.source(Vide.untrack(function()
		return DateTimeCalendarViewUtilities.toViewDate(
			DateTimeCalendarViewUtilities.resolveAnchorDate(props.selectedDates(), props.referenceDate())
		)
	end))
	local getCurrViewDate: () -> ViewDate = currViewDate

	Vide.effect(function()
		local anchor = props.viewAnchorDate()
		if not anchor then
			return
		end
		Vide.untrack(function()
			currViewDate(DateTimeCalendarViewUtilities.toViewDate(anchor))
		end)
	end)

	local function navigateToNextMonth()
		local viewDate = Vide.untrack(getCurrViewDate)
		local nextMonth, nextYear = DateTimeUtilities.getNextMonthInfo(viewDate.month, viewDate.year)
		currViewDate({ month = nextMonth, year = nextYear })
	end

	local function navigateToPreviousMonth()
		local viewDate = Vide.untrack(getCurrViewDate)
		local prevMonth, prevYear = DateTimeUtilities.getPrevMonthInfo(viewDate.month, viewDate.year)
		currViewDate({ month = prevMonth, year = prevYear })
	end

	local function onViewDateChanged(viewDate: ViewDate)
		currViewDate(viewDate)
	end

	local hoveredDate = Vide.source(nil :: DateTime?)
	local getHoveredDate: () -> DateTime? = hoveredDate :: any

	local highlightDates = Vide.derive(function(): { DateTime }
		if not isDateRange() then
			return selectedDateTimes()
		end
		return DateTimeCalendarDayAppearanceUtilities.resolveHighlightDates(selectedDateTimes(), getHoveredDate())
	end)

	local function onHoverEnter(dateTime: DateTime)
		if not Vide.untrack(isDateRange) then
			return
		end
		hoveredDate(dateTime)
	end

	local function onHoverLeave()
		hoveredDate(nil)
	end

	Vide.effect(function()
		if not isDateRange() then
			return
		end
		local selected = selectedDateTimes()
		if not selected[1] or selected[2] then
			Vide.untrack(function()
				hoveredDate(nil)
			end)
		end
	end)

	local function handleDateActivated(day: number, month: number, year: number)
		local previous = Vide.untrack(getSelectedDateTimes)
		local hour, minute = 0, 0
		local previousSelection = previous[1]
		if previousSelection then
			local selectedLocalTime = DateTimeUtilities.toLocalTime(previousSelection)
			hour = selectedLocalTime.Hour
			minute = selectedLocalTime.Minute
		end
		local dateTime = DateTime.fromLocalTime(year, month, day, hour, minute)
		if Vide.untrack(props.showTimeList) then
			dateTime = DateTimeCalendarViewUtilities.roundUpToNearestHalfHour(dateTime)
		end

		currViewDate({ month = month, year = year })
		hoveredDate(nil)
		local newSelectedDateTimes = if Vide.untrack(isDateRange)
			then DateTimeRangeSelectionUtilities.selectRangeEndpoint(previous, dateTime)
			else { dateTime }
		selectedDateTimes(newSelectedDateTimes)
		props.onSelectedDateChanged(newSelectedDateTimes)
	end

	local function onTimeListItemChanged(item: number)
		local dateTime = DateTimeParsingUtilities.adjustForDaylightSaving(DateTime.fromUnixTimestamp(item))
		selectedDateTimes({ dateTime })
		props.onSelectedDateChanged({ dateTime })
	end

	return {
		currViewDate = getCurrViewDate,
		handleDateActivated = handleDateActivated,
		highlightDates = highlightDates,
		isDateRange = isDateRange,
		localSelectedDateTimes = localSelectedDateTimes,
		navigateToNextMonth = navigateToNextMonth,
		navigateToPreviousMonth = navigateToPreviousMonth,
		onHoverEnter = onHoverEnter,
		onHoverLeave = onHoverLeave,
		onTimeListItemChanged = onTimeListItemChanged,
		onViewDateChanged = onViewDateChanged,
		selectedDateTimes = getSelectedDateTimes,
	}
end

return useSingleMonthCalendarState
