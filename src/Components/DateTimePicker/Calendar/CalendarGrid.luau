local Vide = require("../../../Packages/Vide")

local CalendarGridDayLabel = require("./CalendarGridDayLabel")
local DateTimeCalendarConstants = require("../Utilities/DateTimeCalendarConstants")
local DateTimeCalendarDayAppearanceUtilities = require("../Utilities/DateTimeCalendarDayAppearanceUtilities")
local DateTimeCalendarDayConfigUtilities = require("../Utilities/DateTimeCalendarDayConfigUtilities")
local DateTimeCalendarViewUtilities = require("../Utilities/DateTimeCalendarViewUtilities")
local DateTimeUtilities = require("../DateTimeUtilities")
local Text = require("../../Text")
local Types = require("../../Types")
local View = require("../../View")
local create = require("../../../Utility/create")
local useTokens = require("../../../Providers/Style/useTokens")

type ViewDate = DateTimeCalendarViewUtilities.ViewDate
type DayCellConfig = DateTimeCalendarDayConfigUtilities.DayCellConfig
type DayCellAppearance = DateTimeCalendarDayAppearanceUtilities.DayCellAppearance
type DateRange = DateTimeUtilities.DateRange
type DateTimeLocalTime = DateTimeUtilities.DateTimeLocalTime
type ColorStyleValue = Types.ColorStyleValue

local buildCalendarDayConfigs = DateTimeCalendarDayConfigUtilities.buildCalendarDayConfigs
local DAYS_PER_WEEK = DateTimeCalendarConstants.DAYS_PER_WEEK
local getDayCellAppearance = DateTimeCalendarDayAppearanceUtilities.getDayCellAppearance

export type CalendarGridProps = {
	currViewDate: () -> ViewDate,
	handleDateActivated: (day: number, month: number, year: number) -> (),
	highlightDates: () -> { DateTime },
	isDateRange: () -> boolean,
	localSelectedDateTimes: () -> { DateTimeLocalTime },
	LayoutOrder: number?,
	onHoverEnter: ((dateTime: DateTime) -> ())?,
	onHoverLeave: (() -> ())?,
	scaledCalendarWidth: () -> number,
	selectableDateRange: () -> DateRange?,
	Size: (() -> UDim2)?,
	testId: string,
}

type DayCellProps = {
	config: DayCellConfig,
	appearance: () -> DayCellAppearance,
	handleDateActivated: (day: number, month: number, year: number) -> (),
	onHoverEnter: ((dateTime: DateTime) -> ())?,
	testId: string,
}

local function CalendarGridDayCell(props: DayCellProps): GuiObject
	local tokens = useTokens()
	local config = props.config
	local appearance = Vide.derive(props.appearance)

	local function field<T>(read: (DayCellAppearance) -> T): () -> T
		return Vide.derive(function()
			return read(appearance())
		end)
	end
	local isSelected = field(function(value)
		return value.isSelected
	end)
	local isSelectable = field(function(value)
		return value.isSelectable
	end)
	local isHighlighted = field(function(value)
		return value.isHighlighted
	end)
	local bandRadiusTag = field(function(value)
		return value.bandRadiusTag
	end)
	local bandPosition = field(function(value)
		return value.bandPosition
	end)
	local bandSize = field(function(value)
		return value.bandSize
	end)

	local onHoverEnter = props.onHoverEnter
	--* Range preview fill is a sibling of the label, so the label keeps its circle.
	local rangeFill = Vide.show(function()
		return isHighlighted() and not isSelected()
	end, function()
		local fill = View({
			backgroundStyle = function(): ColorStyleValue
				return tokens().Color.ActionStandard.Background :: any
			end,
			tag = function()
				return `size-full {bandRadiusTag() or ""}`
			end,
			ZIndex = 0,
		})
		fill.Name = "RangeFill"
		return fill
	end)

	local day = CalendarGridDayLabel({
		bandPosition = function()
			return if isSelected() then bandPosition() else nil
		end,
		bandRadiusTag = function()
			return if isSelected() then bandRadiusTag() else nil
		end,
		bandSize = function()
			return if isSelected() then bandSize() else nil
		end,
		emphasizeText = function()
			return if config.applyEmphasis then isSelectable() and not isSelected() else nil
		end,
		highlight = false,
		isSelectable = isSelectable,
		isSelected = isSelected,
		LayoutOrder = 1,
		onActivated = function()
			props.handleDateActivated(config.day, config.month, config.year)
		end,
		onHoverEnter = if onHoverEnter
			then function()
				onHoverEnter(DateTime.fromLocalTime(config.year, config.month, config.day))
			end
			else nil,
		testId = props.testId,
		label = tostring(config.day),
	})
	day.Name = "Day"

	return View({
		LayoutOrder = config.LayoutOrder,
		tag = "size-full",
		children = { rangeFill, day },
	})
end

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

--- The weekday headers and the six weeks of the shown month, padded with days of the months around it.
local function CalendarGrid(props: CalendarGridProps): GuiObject
	local tokens = useTokens()

	local layout = create("UIGridLayout")({
		Name = "layout",
		CellPadding = function()
			local cellPadding = tokens().Padding.None
			return UDim2.fromOffset(cellPadding, cellPadding)
		end,
		CellSize = function()
			local cellSize = props.scaledCalendarWidth() / DAYS_PER_WEEK
			return UDim2.fromOffset(cellSize, cellSize)
		end,
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
			tag = "text-body-small text-align-x-center text-align-y-center",
			Text = weekday,
		})
		header.Name = weekday
		table.insert(weekdayHeaders, header)
	end

	--* Day cells are keyed by month like Foundation's `{prefix}-{day}` keys, whose test ids name the day.
	local days = keyed(function()
		local viewDate = props.currViewDate()
		return `{viewDate.year}-{viewDate.month}`
	end, function()
		local configs = buildCalendarDayConfigs(Vide.untrack(props.currViewDate))
		local cells = {}
		for _, config in configs do
			local key = `{config.keyPrefix}-{config.day}`
			local dateTime = DateTime.fromLocalTime(config.year, config.month, config.day)
			local cell = CalendarGridDayCell({
				config = config,
				appearance = function()
					return getDayCellAppearance(
						dateTime,
						props.localSelectedDateTimes(),
						props.highlightDates(),
						props.isDateRange(),
						props.selectableDateRange()
					)
				end,
				handleDateActivated = props.handleDateActivated,
				onHoverEnter = props.onHoverEnter,
				testId = `{props.testId}--{config.keyPrefix}-calendar-day-{config.day}`,
			})
			cell.Name = key
			table.insert(cells, cell)
		end
		return cells
	end)

	local root = View({
		LayoutOrder = props.LayoutOrder,
		Size = props.Size,
		tag = "size-full-0 auto-y",
		testId = `{props.testId}--weekAndDates`,
		children = { layout, weekdayHeaders, days },
	})

	--* Clears the range preview when the pointer leaves the grid, not when a day is rebuilt.
	local onHoverLeave = props.onHoverLeave
	if onHoverLeave then
		Vide.cleanup(root.MouseLeave:Connect(function()
			onHoverLeave()
		end))
	end

	return root
end

return CalendarGrid
