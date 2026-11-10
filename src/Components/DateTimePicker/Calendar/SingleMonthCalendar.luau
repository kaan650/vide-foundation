local Vide = require("../../../Packages/Vide")

local CalendarGrid = require("./CalendarGrid")
local CalendarHeader = require("./CalendarHeader")
local DateTimeCalendarConstants = require("../Utilities/DateTimeCalendarConstants")
local DateTimeCalendarViewUtilities = require("../Utilities/DateTimeCalendarViewUtilities")
local DateTimeLayoutUtilities = require("../Utilities/DateTimeLayoutUtilities")
local DateTimeUtilities = require("../DateTimeUtilities")
local TimeList = require("../Time/TimeList")
local Types = require("../../Types")
local View = require("../../View")
local rebuildOn = require("../../../Utility/rebuildOn")
local useScaledValue = require("../../../Utility/useScaledValue")
local useSingleMonthCalendarState = require("./useSingleMonthCalendarState")
local useTokens = require("../../../Providers/Style/useTokens")

type DateRange = DateTimeUtilities.DateRange
type SingleMonthCalendarState = useSingleMonthCalendarState.SingleMonthCalendarState
type SingleWithTimeLayout = DateTimeLayoutUtilities.SingleWithTimeLayout
type ColorStyleValue = Types.ColorStyleValue

export type SingleMonthCalendarProps = {
	-- Range selection (start and end) instead of a single date.
	isDateRange: () -> boolean,
	LayoutOrder: number?,
	onSelectedDateChanged: (dateTimes: { DateTime }) -> (),
	-- Month shown when nothing is selected.
	referenceDate: () -> DateTime?,
	selectableDateRange: () -> DateRange?,
	selectedDates: () -> { DateTime }?,
	-- Shows the time list beside the calendar.
	showTimeList: () -> boolean,
	testId: string?,
	-- Month the calendar should show.
	viewAnchorDate: () -> DateTime?,
}

type CalendarPaneProps = {
	gridSize: (() -> UDim2)?,
	LayoutOrder: number?,
	rootTestId: string?,
	scaledCalendarWidth: () -> number,
	selectableDateRange: () -> DateRange?,
	showTimeList: boolean,
	Size: () -> UDim2,
	state: SingleMonthCalendarState,
	testId: string,
}

local function CalendarPane(props: CalendarPaneProps): GuiObject
	local state = props.state

	local header = CalendarHeader({
		LayoutOrder = 1,
		onNextMonth = state.navigateToNextMonth,
		onPreviousMonth = state.navigateToPreviousMonth,
		onViewDateChanged = state.onViewDateChanged,
		selectableDateRange = props.selectableDateRange,
		testId = props.testId,
		viewDate = state.currViewDate,
	})
	header.Name = "CalendarHeader"

	local grid = CalendarGrid({
		currViewDate = state.currViewDate,
		handleDateActivated = state.handleDateActivated,
		highlightDates = state.highlightDates,
		isDateRange = state.isDateRange,
		localSelectedDateTimes = state.localSelectedDateTimes,
		LayoutOrder = 2,
		onHoverEnter = state.onHoverEnter,
		onHoverLeave = state.onHoverLeave,
		scaledCalendarWidth = props.scaledCalendarWidth,
		selectableDateRange = props.selectableDateRange,
		Size = props.gridSize,
		testId = props.testId,
	})
	grid.Name = "WeekAndDates"

	return View({
		LayoutOrder = props.LayoutOrder,
		Size = props.Size,
		tag = if props.showTimeList then "col gap-small padding-large" else "col auto-y",
		testId = props.rootTestId,
		children = { header, grid },
	})
end

--- A month calendar picking a date or a range, optionally beside a list of times. Returns a source of its root,
--- which changes with `showTimeList`.
local function SingleMonthCalendar(props: SingleMonthCalendarProps): () -> GuiObject
	local testId = props.testId or "--foundation-calendar"
	local tokens = useTokens()
	local scaledCalendarWidth = useScaledValue(DateTimeLayoutUtilities.CALENDAR_WIDTH)
	local scaledTimeListWidth = useScaledValue(DateTimeLayoutUtilities.TIME_LIST_WIDTH)

	local state = useSingleMonthCalendarState({
		isDateRange = props.isDateRange,
		onSelectedDateChanged = props.onSelectedDateChanged,
		referenceDate = props.referenceDate,
		selectableDateRange = props.selectableDateRange,
		selectedDates = props.selectedDates,
		showTimeList = props.showTimeList,
		viewAnchorDate = props.viewAnchorDate,
	})

	local function withTimeList(): GuiObject
		local layout = Vide.derive(function(): SingleWithTimeLayout
			return DateTimeLayoutUtilities.computeSingleWithTimeLayout(
				scaledCalendarWidth(),
				scaledTimeListWidth(),
				tokens(),
				DateTimeCalendarConstants.NUM_CALENDAR_GRID_ROWS
			)
		end)

		local calendarPane = CalendarPane({
			gridSize = function()
				return UDim2.fromOffset(scaledCalendarWidth(), layout().gridHeight)
			end,
			LayoutOrder = 1,
			scaledCalendarWidth = scaledCalendarWidth,
			selectableDateRange = props.selectableDateRange,
			showTimeList = true,
			Size = function()
				return UDim2.fromOffset(layout().calendarColumnWidth, layout().bodyHeight)
			end,
			state = state,
			testId = testId,
		})
		calendarPane.Name = "CalendarPane"

		local divider = View({
			backgroundStyle = function(): ColorStyleValue
				return tokens().Color.Stroke.Default :: any
			end,
			LayoutOrder = 2,
			Size = function()
				return UDim2.fromOffset(tokens().Stroke.Standard, layout().bodyHeight)
			end,
		})
		divider.Name = "Divider"

		local timeList = TimeList({
			dateTime = function()
				return state.selectedDateTimes()[1]
			end,
			dayAnchor = function()
				return DateTimeCalendarViewUtilities.resolveAnchorDate(
					state.selectedDateTimes(),
					props.viewAnchorDate() or props.referenceDate()
				)
			end,
			height = function()
				return layout().timeListHeight
			end,
			LayoutOrder = 1,
			onItemChanged = state.onTimeListItemChanged,
			testId = `{testId}--time-list`,
			width = function()
				return UDim.new(0, scaledTimeListWidth())
			end,
		})
		timeList.Name = "TimeList"

		local timeListColumn = View({
			LayoutOrder = 3,
			Size = function()
				return UDim2.fromOffset(layout().timeListColumnWidth, layout().bodyHeight)
			end,
			tag = "col padding-large",
			children = timeList,
		})
		timeListColumn.Name = "TimeListColumn"

		return View({
			LayoutOrder = props.LayoutOrder,
			tag = "row align-y-top auto-xy",
			testId = testId,
			children = { calendarPane, divider, timeListColumn },
		})
	end

	return rebuildOn(props.showTimeList, function(showTimeList: boolean): GuiObject
		if showTimeList then
			return withTimeList()
		end
		return CalendarPane({
			LayoutOrder = props.LayoutOrder,
			rootTestId = testId,
			scaledCalendarWidth = scaledCalendarWidth,
			selectableDateRange = props.selectableDateRange,
			showTimeList = false,
			Size = function()
				return UDim2.fromOffset(scaledCalendarWidth(), 0)
			end,
			state = state,
			testId = testId,
		})
	end) :: () -> GuiObject
end

return SingleMonthCalendar
