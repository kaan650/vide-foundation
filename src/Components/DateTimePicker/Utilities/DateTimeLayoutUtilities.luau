local DateTimeCalendarConstants = require("./DateTimeCalendarConstants")
local Tokens = require("../../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local CALENDAR_WIDTH = 272
local DAYS_PER_WEEK = DateTimeCalendarConstants.DAYS_PER_WEEK
local PANE_WIDTH = 280
local TIME_LIST_WIDTH = 132

export type SingleWithTimeLayout = {
	bodyHeight: number,
	calendarColumnWidth: number,
	contentWidth: number,
	gridHeight: number,
	timeListColumnWidth: number,
	timeListHeight: number,
}

--- Column and body sizes of the calendar beside the time list.
local function computeSingleWithTimeLayout(
	scaledCalendarWidth: number,
	scaledTimeListWidth: number,
	tokens: Tokens,
	numGridRows: number
): SingleWithTimeLayout
	local paddingLarge = tokens.Padding.Large
	local cellSize = scaledCalendarWidth / DAYS_PER_WEEK
	local gridHeight = numGridRows * cellSize
	local headerHeight = tokens.Size.Size_800 + 2 * tokens.Padding.Small
	local bodyHeight = 2 * paddingLarge + headerHeight + tokens.Gap.Small + gridHeight

	local calendarColumnWidth = scaledCalendarWidth + 2 * paddingLarge
	local timeListColumnWidth = scaledTimeListWidth + 2 * paddingLarge

	return {
		bodyHeight = bodyHeight,
		calendarColumnWidth = calendarColumnWidth,
		contentWidth = calendarColumnWidth + tokens.Stroke.Standard + timeListColumnWidth,
		gridHeight = gridHeight,
		timeListColumnWidth = timeListColumnWidth,
		timeListHeight = bodyHeight - 2 * paddingLarge,
	}
end

return {
	CALENDAR_WIDTH = CALENDAR_WIDTH,
	PANE_WIDTH = PANE_WIDTH,
	TIME_LIST_WIDTH = TIME_LIST_WIDTH,
	computeSingleWithTimeLayout = computeSingleWithTimeLayout,
}
