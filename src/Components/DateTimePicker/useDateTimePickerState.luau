local Vide = require("../../Packages/Vide")

local DateTimeCalendarViewUtilities = require("./Utilities/DateTimeCalendarViewUtilities")
local DateTimeEqualityUtilities = require("./Utilities/DateTimeEqualityUtilities")
local DateTimeParsingUtilities = require("./Utilities/DateTimeParsingUtilities")
local DateTimePickerPropsModule = require("./DateTimePickerProps")
local DateTimePickerVariantEnum = require("../../Enums/DateTimePickerVariant")
local DateTimeRangeSelectionUtilities = require("./Utilities/DateTimeRangeSelectionUtilities")
local DateTimeUtilities = require("./DateTimeUtilities")
local Services = require("../../Utility/Wrappers/Services")
local Value = require("../../Utility/Value")

type DateTimePickerProps = DateTimePickerPropsModule.DateTimePickerProps
type DateTimePickerVariant = DateTimePickerVariantEnum.DateTimePickerVariant
type DateRange = DateTimeUtilities.DateRange

local GuiService = Services.GuiService

export type DateTimePickerState = {
	-- Open / close
	closeDateTimePicker: () -> (),
	isOpen: () -> boolean,
	onFocusGained: () -> (),
	onFocusLost: (inputObject: InputObject?) -> (),
	showDateTimePicker: () -> (),
	-- Draft (in progress) selection
	selectedDates: () -> { DateTime }?,
	-- Input text, kept in sync with the calendar
	inputText: () -> string,
	updateInputText: (txt: string) -> (),
	-- Picking
	viewAnchorDate: () -> DateTime?,
	onDayActivated: (dateTime: DateTime) -> (),
	onPresetSelected: (range: DateRange) -> (),
	onSelectedDatesChanged: (dates: { DateTime }) -> (),
	-- Apply / Reset / Cancel
	onApply: () -> (),
	onCancel: () -> (),
	onReset: () -> (),
	-- Button enablement
	isApplyButtonDisabled: () -> boolean,
	isResetButtonDisabled: () -> boolean,
}

type SetDraftOptions = {
	-- Moves the calendars to this date's month.
	anchor: DateTime?,
	-- Also commits the dates as the last applied ones (typed input commits at once).
	asApplied: boolean?,
}

type AnchorBox = { date: DateTime }

--- State of DateTimePicker: the popover's open state, the draft selection against the last applied one (Cancel and
--- Reset restore it), the input text kept in sync with the draft, the month the calendars show, and when Apply and
--- Reset are enabled. Call it while the component is being created.
local function useDateTimePickerState(props: DateTimePickerProps): DateTimePickerState
	local function variant(): DateTimePickerVariant
		return Value.read(props.variant) or DateTimePickerVariantEnum.Single
	end
	local function isRange(): boolean
		local current = variant()
		return current == DateTimePickerVariantEnum.Dual or current == DateTimePickerVariantEnum.DualWithPresets
	end
	local function isPresets(): boolean
		return variant() == DateTimePickerVariantEnum.DualWithPresets
	end
	local function isTime(): boolean
		return variant() == DateTimePickerVariantEnum.SingleWithTime
	end
	local function referenceDate(): DateTime?
		return Value.read(props.referenceDate)
	end
	local function selectableDateRange(): DateRange?
		return Value.read(props.selectableDateRange)
	end

	local isOpen = Vide.source(false)

	local normalizedDefaultDates: { DateTime }? = if props.defaultDates == nil
		then nil
		else DateTimeRangeSelectionUtilities.normalizeDates({
			acceptsDateRange = Vide.untrack(isRange),
			dates = props.defaultDates,
		})

	local inputText = Vide.source(if normalizedDefaultDates
		then DateTimeParsingUtilities.formatInputText({
			dates = normalizedDefaultDates,
			variant = Vide.untrack(variant),
		})
		else "")
	local getInputText: () -> string = inputText

	local selectedDates = Vide.source(normalizedDefaultDates)
	local getSelectedDates: () -> { DateTime }? = selectedDates :: any
	local lastAppliedDates = Vide.source(normalizedDefaultDates)
	local getLastAppliedDates: () -> { DateTime }? = lastAppliedDates :: any

	--* Boxed: DateTime compares by value, and an equal anchor must still move a calendar the user navigated away,
	--* as React's new-object state does.
	local viewAnchor = Vide.source(nil :: AnchorBox?)
	local getViewAnchor: () -> AnchorBox? = viewAnchor :: any
	local function viewAnchorDate(): DateTime?
		local box = getViewAnchor()
		return if box then box.date else nil
	end

	local function closeDateTimePicker()
		isOpen(false)
	end

	local function showDateTimePicker()
		isOpen(true)
	end

	local function onFocusGained()
		if GuiService.ViewportDisplaySize ~= Enum.DisplaySize.Small then
			showDateTimePicker()
		end
	end

	local function setDraft(dates: { DateTime }?, options: SetDraftOptions?)
		selectedDates(dates)
		if options and options.asApplied then
			lastAppliedDates(dates)
		end
		if options and options.anchor then
			viewAnchor({ date = options.anchor })
		end
	end

	local function resolvedViewAnchor(dates: { DateTime }?): DateTime
		local anchor = DateTimeCalendarViewUtilities.resolveAnchorDate(dates, Vide.untrack(referenceDate))
		return DateTime.fromUnixTimestamp(anchor.UnixTimestamp)
	end

	--* Text this picker set itself; its echo through onChanged is skipped, or Apply would loop through the parser.
	local pendingProgrammaticInputText: string? = nil

	local function updateInputText(txt: string)
		inputText(txt)

		if pendingProgrammaticInputText ~= nil then
			local pendingText = pendingProgrammaticInputText
			pendingProgrammaticInputText = nil
			if txt == pendingText then
				return
			end
		end

		--* An empty table, not nil: nil is unbound and makes SingleMonthCalendar report its empty selection again.
		local function clearDraftToReference()
			setDraft({}, {
				anchor = resolvedViewAnchor(nil),
				asApplied = true,
			})
		end

		local range = Vide.untrack(selectableDateRange)

		if txt:match("^%s*$") then
			clearDraftToReference()
			props.onChanged(nil)
			return
		end

		if Vide.untrack(isRange) then
			local startDate, endDate = DateTimeParsingUtilities.parseDualInputEndpoints(txt)
			props.onChanged(startDate, endDate)

			local parsed = DateTimeParsingUtilities.parseInputToDraftDates(txt, range)
			if parsed then
				setDraft(parsed, {
					anchor = parsed[1],
					asApplied = true,
				})
			else
				clearDraftToReference()
			end
		else
			local dateTime =
				DateTimeParsingUtilities.parseDateTimeFromText(DateTimeParsingUtilities.trimInputText(txt))
			if dateTime and (range == nil or DateTimeUtilities.isDateWithinRange(dateTime, range)) then
				setDraft({ dateTime }, {
					anchor = dateTime,
					asApplied = true,
				})
				props.onChanged(dateTime)
			else
				clearDraftToReference()
				props.onChanged(dateTime)
			end
		end
	end

	--* Reorders an inverted typed range when the text still matches the calendar draft.
	local function onFocusLost(_inputObject: InputObject?)
		if not Vide.untrack(isRange) then
			return
		end

		local txt = Vide.untrack(getInputText)
		local parsed = DateTimeParsingUtilities.parseInputToDraftDates(txt, Vide.untrack(selectableDateRange))
		if not parsed then
			return
		end

		local formattedText = DateTimeParsingUtilities.formatInputText({
			dates = parsed,
			variant = Vide.untrack(variant),
		})
		if formattedText == txt then
			return
		end

		local draft = Vide.untrack(getSelectedDates)
		if
			not draft
			or not draft[1]
			or not draft[2]
			or not DateTimeEqualityUtilities.isSameDay(draft[1], parsed[1])
			or not DateTimeEqualityUtilities.isSameDay(draft[2], parsed[2])
		then
			return
		end

		pendingProgrammaticInputText = formattedText
		inputText(formattedText)
		props.onChanged(parsed[1], parsed[2])
	end

	--* Day clicks change the draft only: re-anchoring would jump the two-month panes on every pick in the second one.
	local function onDayActivated(dateTime: DateTime)
		local nextDates = DateTimeRangeSelectionUtilities.selectRangeEndpoint(Vide.untrack(getSelectedDates), dateTime)
		setDraft(nextDates)
	end

	local function onPresetSelected(range: DateRange)
		local selectable = Vide.untrack(selectableDateRange)
		if selectable and not DateTimeEqualityUtilities.isRangeWithinSelectableRange(range, selectable) then
			return
		end

		setDraft({ range.startDate, range.endDate }, { anchor = range.startDate })
	end

	local function onSelectedDatesChanged(dates: { DateTime })
		local previousDates = Vide.untrack(getSelectedDates)
		local previousStart = if previousDates then previousDates[1] :: DateTime? else nil
		local previousEnd = if previousDates then previousDates[2] :: DateTime? else nil
		local nextStart = dates[1] :: DateTime?
		local nextEnd = dates[2] :: DateTime?

		if
			previousDates
			and nextStart
			and previousStart
			and previousStart.UnixTimestamp == nextStart.UnixTimestamp
			and (not previousEnd) == not nextEnd
			and (not previousEnd or not nextEnd or previousEnd.UnixTimestamp == nextEnd.UnixTimestamp)
		then
			return
		end

		--* No anchor: SingleMonthCalendar already moves its view on a day pick.
		setDraft(dates)
	end

	local function restoreLastApplied()
		local applied = Vide.untrack(getLastAppliedDates)
		setDraft(applied, {
			anchor = resolvedViewAnchor(applied),
		})
	end

	local function onCancel()
		restoreLastApplied()
		closeDateTimePicker()
	end

	local function onReset()
		restoreLastApplied()
	end

	local function commitDates(dates: { DateTime })
		local startDate = dates[1]
		if not startDate then
			return
		end

		setDraft(dates, { anchor = startDate })
		local formattedText: string
		if Vide.untrack(isRange) then
			local endDate = dates[2]
			local formattedDate = DateTimeUtilities.formatLocalTime(startDate)
			local formattedDate2 = if endDate then DateTimeUtilities.formatLocalTime(endDate) else ""
			formattedText = formattedDate .. " - " .. formattedDate2
			pendingProgrammaticInputText = formattedText
			inputText(formattedText)
			props.onChanged(startDate, endDate)
		else
			formattedText = DateTimeUtilities.formatLocalTime(startDate, Vide.untrack(isTime))
			pendingProgrammaticInputText = formattedText
			inputText(formattedText)
			props.onChanged(startDate)
		end
	end

	local function onApply()
		local datesToCommit = Vide.untrack(getSelectedDates)
		if datesToCommit then
			if Vide.untrack(isPresets) and not (datesToCommit[1] and datesToCommit[2]) then
				closeDateTimePicker()
				return
			end
			lastAppliedDates(datesToCommit)
			commitDates(datesToCommit)
		end
		closeDateTimePicker()
	end

	local isApplyButtonDisabled = Vide.derive(function(): boolean
		local dates = getSelectedDates()
		if dates then
			local startDate = dates[1] :: DateTime?
			local endDate = dates[2] :: DateTime?
			if isPresets() or isRange() then
				return startDate == nil or endDate == nil or startDate.UnixTimestamp > endDate.UnixTimestamp
			elseif variant() == DateTimePickerVariantEnum.Single or isTime() then
				return startDate == nil
			end
			return false
		end
		return isPresets()
	end)

	local isResetButtonDisabled = Vide.derive(function(): boolean
		return if isPresets() or isTime()
			then DateTimeEqualityUtilities.areDatesEqual(getSelectedDates(), getLastAppliedDates())
			else true
	end)

	return {
		closeDateTimePicker = closeDateTimePicker,
		isOpen = function()
			return isOpen()
		end,
		onFocusGained = onFocusGained,
		onFocusLost = onFocusLost,
		showDateTimePicker = showDateTimePicker,
		selectedDates = getSelectedDates,
		inputText = getInputText,
		updateInputText = updateInputText,
		viewAnchorDate = viewAnchorDate,
		onDayActivated = onDayActivated,
		onPresetSelected = onPresetSelected,
		onSelectedDatesChanged = onSelectedDatesChanged,
		onApply = onApply,
		onCancel = onCancel,
		onReset = onReset,
		isApplyButtonDisabled = isApplyButtonDisabled,
		isResetButtonDisabled = isResetButtonDisabled,
	}
end

return useDateTimePickerState
