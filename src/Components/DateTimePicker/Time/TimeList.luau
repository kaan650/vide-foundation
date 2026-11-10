local Vide = require("../../../Packages/Vide")

local DateTimeCalendarViewUtilities = require("../Utilities/DateTimeCalendarViewUtilities")
local DateTimeLayoutUtilities = require("../Utilities/DateTimeLayoutUtilities")
local DateTimeUtilities = require("../DateTimeUtilities")
local ScrollView = require("../../ScrollView")
local StateLayerMode = require("../../../Enums/StateLayerMode")
local Text = require("../../Text")
local Types = require("../../Types")
local useTokens = require("../../../Providers/Style/useTokens")

type ColorStyleValue = Types.ColorStyleValue

export type TimeListProps = {
	-- The selected date and time; its slot is highlighted.
	dateTime: () -> DateTime?,
	-- Day the slots are built for while `dateTime` is nil (a cleared draft shows the calendar's day).
	dayAnchor: () -> DateTime?,
	-- Called with the unix timestamp of the activated slot.
	onItemChanged: (id: number) -> (),
	-- Height of the scrolling area, matched to the calendar grid.
	height: () -> number,
	LayoutOrder: number?,
	width: (() -> UDim)?,
	testId: string?,
}

type Slot = { id: number, text: string }
type Row = { index: number, slot: Slot }
type Slots = { slots: { Slot }, selectedId: number }

--- The half-hour slots of a day in a scrolling column, the selected one highlighted.
local function TimeList(props: TimeListProps): GuiObject
	local tokens = useTokens()
	local testId = props.testId or "--foundation-time-list"
	local scrollingFrame: ScrollingFrame? = nil
	--* Skips the next scroll-to-selected when the user picks a slot in this list.
	local skipNextScroll = false
	local isFirstLayout = true
	local lastTimeKey: string? = nil

	local function rowHeight(): number
		return tokens().Size.Size_900
	end

	local daySlots = Vide.derive(function(): Slots
		local slotDay = props.dateTime() or props.dayAnchor() or DateTime.now()
		local slots, selectedId = DateTimeCalendarViewUtilities.getTimeSlotsForDay(slotDay)
		return { slots = slots, selectedId = selectedId }
	end)
	--* No draft selection, no highlighted slot, even when dayAnchor supplies the day.
	local selectedId = Vide.derive(function(): number?
		local matched = daySlots().selectedId
		return if props.dateTime() then matched else nil
	end)

	local function getTimeKey(id: number?): string?
		if id == nil then
			return nil
		end
		local localTime = DateTimeUtilities.toLocalTime(DateTime.fromUnixTimestamp(id))
		return string.format("%02d:%02d", localTime.Hour, localTime.Minute)
	end

	local rows = Vide.derive(function(): { [string]: Row }
		local map = {}
		for index, slot in daySlots().slots do
			map[`slot-{slot.id}`] = { index = index, slot = slot }
		end
		return map
	end)

	local children = Vide.indexes(rows, function(row: () -> Row, key: string)
		local initial = Vide.untrack(row)
		local function isSelected(): boolean
			return row().slot.id == selectedId()
		end
		local text = Text({
			LayoutOrder = initial.index,
			Size = function()
				return UDim2.new(1, 0, 0, rowHeight())
			end,
			Text = function()
				return row().slot.text
			end,
			textStyle = (function(): ColorStyleValue?
				return if isSelected() then tokens().Inverse.Content.Emphasis :: any else nil
			end) :: any,
			backgroundStyle = (function(): ColorStyleValue?
				return if isSelected() then tokens().Color.System.Contrast :: any else nil
			end) :: any,
			stateLayer = {
				mode = function()
					return if isSelected() then StateLayerMode.Inverse else StateLayerMode.Default
				end,
			},
			onActivated = function()
				skipNextScroll = true
				props.onItemChanged(Vide.untrack(row).slot.id)
			end,
			tag = "size-full-0 auto-y padding-x-medium text-body-medium text-align-x-left text-align-y-center radius-medium",
			testId = `{testId}--slot-{initial.index}`,
		})
		text.Name = key
		return text
	end)

	local scrollView = ScrollView({
		LayoutOrder = props.LayoutOrder,
		Size = function()
			local width = if props.width then props.width() else UDim.new(0, DateTimeLayoutUtilities.TIME_LIST_WIDTH)
			return UDim2.new(width.Scale, width.Offset, 0, props.height())
		end,
		layout = {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		scroll = {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollingDirection = Enum.ScrollingDirection.Y,
		},
		scrollingFrameRef = function(frame: ScrollingFrame)
			scrollingFrame = frame
		end,
		testId = testId,
		children = children,
	})

	--* Centers the selected slot on open and when the time of day changes from outside (Reset). Not when the user
	--* picks a slot here, when only the day changes, or when a day click first sets a time after mount.
	Vide.effect(function()
		local id = selectedId()
		local slots = daySlots().slots
		local height = props.height()
		local currentRowHeight = rowHeight()

		Vide.untrack(function()
			local timeKey = getTimeKey(id)

			if skipNextScroll then
				skipNextScroll = false
				lastTimeKey = timeKey
				isFirstLayout = false
				return
			end

			local frame = scrollingFrame
			if not frame then
				return
			end

			local wasFirstLayout = isFirstLayout
			isFirstLayout = false

			if timeKey == nil then
				lastTimeKey = nil
				return
			end

			if timeKey == lastTimeKey then
				return
			end

			if not wasFirstLayout and lastTimeKey == nil then
				lastTimeKey = timeKey
				return
			end

			lastTimeKey = timeKey

			local slotIndex = DateTimeCalendarViewUtilities.getTimeSlotIndex(slots, id)
			if not slotIndex then
				return
			end
			local centeredY = (slotIndex - 1) * currentRowHeight - height / 2 + currentRowHeight / 2
			frame.CanvasPosition = Vector2.new(0, math.max(0, centeredY))
		end)
	end)

	return scrollView
end

return TimeList
