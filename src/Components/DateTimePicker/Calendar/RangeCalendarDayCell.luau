local Vide = require("../../../Packages/Vide")

local CalendarGridDayLabel = require("./CalendarGridDayLabel")
local DateTimeCalendarDayAppearanceUtilities = require("../Utilities/DateTimeCalendarDayAppearanceUtilities")
local DateTimeUtilities = require("../DateTimeUtilities")
local Types = require("../../Types")
local View = require("../../View")
local useTokens = require("../../../Providers/Style/useTokens")

type DateRange = DateTimeUtilities.DateRange
type DateTimeLocalTime = DateTimeUtilities.DateTimeLocalTime
type ColorStyleValue = Types.ColorStyleValue

export type RangeCalendarDayCellProps = {
	cellSize: () -> number,
	day: number,
	hoveredDate: () -> DateTime?,
	selectedDates: () -> { DateTime }?,
	LayoutOrder: number,
	month: number,
	onDayActivated: (dateTime: DateTime) -> (),
	onHoverEnter: ((dateTime: DateTime) -> ())?,
	selectableDateRange: () -> DateRange?,
	testId: string?,
	year: number,
}

type Appearance = {
	bandPosition: UDim2?,
	bandRadiusTag: string?,
	bandSize: UDim2?,
	isHighlighted: boolean,
	isSelectable: boolean,
	isSelected: boolean,
}

--- A day of a TwoMonthCalendar pane, with the range fill behind it.
local function RangeCalendarDayCell(props: RangeCalendarDayCellProps): GuiObject
	local tokens = useTokens()
	local dateTime = DateTime.fromLocalTime(props.year, props.month, props.day)

	local appearance = Vide.derive(function(): Appearance
		local selectedDates: { DateTime } = props.selectedDates() or {}
		local selectedLocalTimes: { DateTimeLocalTime } = {}
		for _, selectedDate in selectedDates do
			table.insert(selectedLocalTimes, DateTimeUtilities.toLocalTime(selectedDate))
		end

		local highlightDates =
			DateTimeCalendarDayAppearanceUtilities.resolveHighlightDates(selectedDates, props.hoveredDate())
		local isSelected = DateTimeCalendarDayAppearanceUtilities.isDaySelected(dateTime, selectedLocalTimes, true)
		local bandPosition, bandSize, bandRadiusTag =
			DateTimeCalendarDayAppearanceUtilities.getRangeBand(dateTime, highlightDates, true, isSelected)
		return {
			bandPosition = bandPosition,
			bandRadiusTag = bandRadiusTag,
			bandSize = bandSize,
			isHighlighted = DateTimeCalendarDayAppearanceUtilities.isDayHighlighted(dateTime, highlightDates, true),
			isSelectable = DateTimeCalendarDayAppearanceUtilities.isDaySelectable(dateTime, props.selectableDateRange()),
			isSelected = isSelected,
		}
	end)

	local function field<T>(read: (Appearance) -> T): () -> T
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

	--* The fill lives on this cell, so the label keeps a stable circular Text under the grid layout.
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

	local onHoverEnter = props.onHoverEnter
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
			return isSelectable() and not isSelected()
		end,
		highlight = false,
		isSelectable = isSelectable,
		isSelected = isSelected,
		LayoutOrder = 1,
		label = tostring(props.day),
		onActivated = function()
			props.onDayActivated(dateTime)
		end,
		onHoverEnter = if onHoverEnter
			then function()
				onHoverEnter(dateTime)
			end
			else nil,
		testId = `{props.testId}--day-{props.year}-{props.month}-{props.day}`,
	})
	day.Name = "Day"

	return View({
		LayoutOrder = props.LayoutOrder,
		Size = function()
			local cellSize = props.cellSize()
			return UDim2.fromOffset(cellSize, cellSize)
		end,
		children = { rangeFill, day },
	})
end

return RangeCalendarDayCell
