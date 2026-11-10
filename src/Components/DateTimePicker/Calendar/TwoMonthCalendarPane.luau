local Vide = require("../../../Packages/Vide")

local DateTimeCalendarConstants = require("../Utilities/DateTimeCalendarConstants")
local DateTimeCalendarDayConfigUtilities = require("../Utilities/DateTimeCalendarDayConfigUtilities")
local DateTimeUtilities = require("../DateTimeUtilities")
local RangeCalendarDayCell = require("./RangeCalendarDayCell")
local Text = require("../../Text")
local View = require("../../View")
local create = require("../../../Utility/create")

local DAYS_PER_WEEK = DateTimeCalendarConstants.DAYS_PER_WEEK
local buildTwoMonthPaneCellConfigs = DateTimeCalendarDayConfigUtilities.buildTwoMonthPaneCellConfigs

export type TwoMonthCalendarPaneProps = {
	cellSize: () -> number,
	hoveredDate: () -> DateTime?,
	LayoutOrder: number,
	month: () -> number,
	onDayActivated: (dateTime: DateTime) -> (),
	onHoverEnter: ((dateTime: DateTime) -> ())?,
	paneWidth: () -> number,
	selectableDateRange: () -> DateTimeUtilities.DateRange?,
	selectedDates: () -> { DateTime }?,
	testId: string?,
	year: () -> number,
}

--- `build(key)` while `key` stays the same, built again when it changes.
local function keyed(key: () -> string, build: (key: string) -> any): () -> any
	local builders = setmetatable({}, {
		__index = function(_, current: string)
			return function()
				return build(current)
			end
		end,
	})
	return Vide.switch(key)(builders :: any)
end

--- One month of a TwoMonthCalendar: weekday headers and the month's days, padded to whole weeks with empty cells.
local function TwoMonthCalendarPane(props: TwoMonthCalendarPaneProps): GuiObject
	local function cellSizeUDim2(): UDim2
		local cellSize = props.cellSize()
		return UDim2.fromOffset(cellSize, cellSize)
	end

	local layout = create("UIGridLayout")({
		Name = "layout",
		CellPadding = UDim2.fromOffset(0, 0),
		CellSize = cellSizeUDim2,
		FillDirection = Enum.FillDirection.Horizontal,
		FillDirectionMaxCells = DAYS_PER_WEEK,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})

	local weekdayHeaders = {}
	for index, weekday in DateTimeUtilities.weekdays do
		local header = Text({
			LayoutOrder = index,
			Text = weekday,
			tag = "text-body-small text-align-x-center text-align-y-center",
		})
		header.Name = `weekday-{weekday}`
		table.insert(weekdayHeaders, header)
	end

	--* Rebuilt per month: Foundation's day test ids name the month.
	local cells = keyed(function()
		return `{props.year()}-{props.month()}`
	end, function()
		local month, year = Vide.untrack(props.month), Vide.untrack(props.year)
		local list = {}
		for _, cellConfig in buildTwoMonthPaneCellConfigs(month, year) do
			local cell
			if cellConfig.day == nil then
				cell = View({
					LayoutOrder = cellConfig.LayoutOrder,
					Size = cellSizeUDim2,
				})
			else
				cell = RangeCalendarDayCell({
					cellSize = props.cellSize,
					day = cellConfig.day,
					hoveredDate = props.hoveredDate,
					LayoutOrder = cellConfig.LayoutOrder,
					month = cellConfig.month :: number,
					onDayActivated = props.onDayActivated,
					onHoverEnter = props.onHoverEnter,
					selectableDateRange = props.selectableDateRange,
					selectedDates = props.selectedDates,
					testId = props.testId,
					year = cellConfig.year :: number,
				})
			end
			cell.Name = cellConfig.key
			table.insert(list, cell)
		end
		return list
	end)

	return View({
		LayoutOrder = props.LayoutOrder,
		Size = function()
			return UDim2.fromOffset(props.paneWidth(), 0)
		end,
		tag = "auto-y",
		testId = `{props.testId}--pane-{props.LayoutOrder}`,
		children = { layout, weekdayHeaders, cells },
	})
end

return TwoMonthCalendarPane
