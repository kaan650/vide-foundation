local Vide = require("../../../Packages/Vide")

local DateTimeCalendarViewUtilities = require("../Utilities/DateTimeCalendarViewUtilities")
local DateTimeLayoutUtilities = require("../Utilities/DateTimeLayoutUtilities")
local DateTimeUtilities = require("../DateTimeUtilities")
local Divider = require("../../Divider")
local TwoMonthCalendarHeader = require("./TwoMonthCalendarHeader")
local TwoMonthCalendarPane = require("./TwoMonthCalendarPane")
local View = require("../../View")
local useScaledValue = require("../../../Utility/useScaledValue")

type ViewDate = DateTimeCalendarViewUtilities.ViewDate

export type TwoMonthCalendarProps = {
	LayoutOrder: number?,
	onDayActivated: (dateTime: DateTime) -> (),
	referenceDate: () -> DateTime?,
	selectableDateRange: () -> DateTimeUtilities.DateRange?,
	selectedDates: () -> { DateTime }?,
	testId: string?,
	viewAnchorDate: () -> DateTime?,
}

--- Two consecutive months side by side for picking a range, with a hover preview of the range end.
local function TwoMonthCalendar(props: TwoMonthCalendarProps): GuiObject
	local paneWidth = useScaledValue(DateTimeLayoutUtilities.PANE_WIDTH)
	local function cellSize(): number
		return paneWidth() / 7
	end

	local currViewDate = Vide.source(Vide.untrack(function()
		return DateTimeCalendarViewUtilities.toViewDate(
			DateTimeCalendarViewUtilities.resolveAnchorDate(props.selectedDates(), props.referenceDate())
		)
	end))
	local getCurrViewDate: () -> ViewDate = currViewDate

	local hoveredDate = Vide.source(nil :: DateTime?)
	local getHoveredDate: () -> DateTime? = hoveredDate :: any

	Vide.effect(function()
		local anchor = props.viewAnchorDate()
		if not anchor then
			return
		end
		Vide.untrack(function()
			currViewDate(DateTimeCalendarViewUtilities.toViewDate(anchor))
		end)
	end)

	--* Falls back to referenceDate only while nothing is selected or anchored, so a range click does not snap the
	--* view back to a stale anchor.
	Vide.effect(function()
		if props.viewAnchorDate() then
			return
		end
		local dates = props.selectedDates()
		if dates and dates[1] then
			return
		end
		local referenceDate = props.referenceDate()
		if referenceDate then
			Vide.untrack(function()
				currViewDate(DateTimeCalendarViewUtilities.toViewDate(referenceDate))
			end)
		end
	end)

	Vide.effect(function()
		local dates = props.selectedDates()
		if not dates or not dates[1] or dates[2] then
			Vide.untrack(function()
				hoveredDate(nil)
			end)
		end
	end)

	local function navigateToPreviousMonth()
		local previous = Vide.untrack(getCurrViewDate)
		local month, year = DateTimeUtilities.getPrevMonthInfo(previous.month, previous.year)
		currViewDate({ month = month, year = year })
	end

	local function navigateToNextMonth()
		local previous = Vide.untrack(getCurrViewDate)
		local month, year = DateTimeUtilities.getNextMonthInfo(previous.month, previous.year)
		currViewDate({ month = month, year = year })
	end

	local function onHoverEnter(dateTime: DateTime)
		hoveredDate(dateTime)
	end

	local function onDayActivated(dateTime: DateTime)
		hoveredDate(nil)
		props.onDayActivated(dateTime)
	end

	local secondMonthInfo = Vide.derive(function(): ViewDate
		local viewDate = getCurrViewDate()
		local month, year = DateTimeUtilities.getNextMonthInfo(viewDate.month, viewDate.year)
		return { month = month, year = year }
	end)

	local function pane(layoutOrder: number, viewDate: () -> ViewDate, name: string): GuiObject
		local view = TwoMonthCalendarPane({
			cellSize = cellSize,
			hoveredDate = getHoveredDate,
			LayoutOrder = layoutOrder,
			month = function()
				return viewDate().month
			end,
			onDayActivated = onDayActivated,
			onHoverEnter = onHoverEnter,
			paneWidth = paneWidth,
			selectableDateRange = props.selectableDateRange,
			selectedDates = props.selectedDates,
			testId = props.testId,
			year = function()
				return viewDate().year
			end,
		})
		view.Name = name
		return view
	end

	local header = TwoMonthCalendarHeader({
		currViewDate = getCurrViewDate,
		onNextMonth = navigateToNextMonth,
		onPreviousMonth = navigateToPreviousMonth,
		secondMonth = function()
			return secondMonthInfo().month
		end,
		secondYear = function()
			return secondMonthInfo().year
		end,
		testId = props.testId,
	})
	header.Name = "Header"

	local headerDivider = Divider({
		LayoutOrder = 2,
	})
	headerDivider.Name = "HeaderDivider"

	local panes = View({
		LayoutOrder = 3,
		tag = "row align-y-top gap-large auto-xy padding-x-large padding-y-small",
		children = {
			pane(1, getCurrViewDate, "FirstPane"),
			pane(2, secondMonthInfo, "SecondPane"),
		},
	})
	panes.Name = "Panes"
	--* Clears the preview when the pointer leaves both panes, not when a day is rebuilt.
	Vide.cleanup(panes.MouseLeave:Connect(function()
		hoveredDate(nil)
	end))

	return View({
		LayoutOrder = props.LayoutOrder,
		tag = "col size-full-0 auto-y",
		testId = props.testId,
		children = { header, headerDivider, panes },
	})
end

return TwoMonthCalendar
