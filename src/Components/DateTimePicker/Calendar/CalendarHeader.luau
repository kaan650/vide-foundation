local Vide = require("../../../Packages/Vide")

local BuilderIcons = require("../../../Packages/BuilderIcons")
local ButtonVariant = require("../../../Enums/ButtonVariant")
local DateTimeCalendarViewUtilities = require("../Utilities/DateTimeCalendarViewUtilities")
local DateTimeUtilities = require("../DateTimeUtilities")
local Dropdown = require("../../Dropdown")
local IconButton = require("../../IconButton")
local InputSize = require("../../../Enums/InputSize")
local InputVariant = require("../../../Enums/InputVariant")
local Types = require("../../Types")
local View = require("../../View")
local named = require("../../../Utility/named")
local useScaledValue = require("../../../Utility/useScaledValue")
local useScrollToSelectedRef = require("./useScrollToSelectedRef")
local useTextSize = require("../../../Utility/useTextSize")
local useTokens = require("../../../Providers/Style/useTokens")

type DateRange = DateTimeUtilities.DateRange
type ViewDate = DateTimeCalendarViewUtilities.ViewDate
type DropdownItem = Dropdown.DropdownItem

local IconName = BuilderIcons.Icon

export type CalendarHeaderProps = {
	LayoutOrder: number?,
	onNextMonth: () -> (),
	onPreviousMonth: () -> (),
	-- Called when the month or year dropdown changes the shown month (navigation only, not selection).
	onViewDateChanged: (ViewDate) -> (),
	selectableDateRange: () -> DateRange?,
	testId: string?,
	viewDate: () -> ViewDate,
}

local YEAR_WINDOW = 50
--* The utility dropdown's padding, gap and chevron around its text (~40px measured), so the dropdowns hug their text.
local DROPDOWN_NON_TEXT_WIDTH = 44
--* Caps the open menus so the long year list scrolls; unbounded, its items overflow the surface and clicks miss.
local MENU_MAX_HEIGHT = 200

--- Previous and next month buttons around month and year dropdowns.
local function CalendarHeader(props: CalendarHeaderProps): GuiObject
	local tokens = useTokens()
	local viewDate = props.viewDate

	local function bodySmall(): Types.FontStyle
		return tokens().Typography.BodySmall :: any
	end
	local monthTextSize = useTextSize(function()
		return DateTimeUtilities.monthMap[viewDate().month]
	end, bodySmall)
	local yearTextSize = useTextSize(function()
		return tostring(viewDate().year)
	end, bodySmall)
	local dropdownNonTextWidth = useScaledValue(DROPDOWN_NON_TEXT_WIDTH)
	local menuMaxHeight = useScaledValue(MENU_MAX_HEIGHT)

	local monthItems: { DropdownItem } = {}
	for month, text in DateTimeUtilities.monthMap do
		table.insert(monthItems, {
			id = month,
			text = text,
		})
	end

	local yearItems = Vide.derive(function(): { DropdownItem }
		local range = props.selectableDateRange()
		local startYear, endYear
		if range then
			startYear = DateTimeUtilities.toLocalTime(range.startDate).Year
			endYear = DateTimeUtilities.toLocalTime(range.endDate).Year
		else
			local year = viewDate().year
			startYear = year - YEAR_WINDOW
			endYear = year + YEAR_WINDOW
		end

		local items = {}
		for year = startYear, endYear do
			table.insert(items, {
				id = year,
				text = tostring(year),
			})
		end
		return items
	end)

	local function onMonthChanged(id: number | string)
		local month = tonumber(id)
		if month then
			props.onViewDateChanged({ month = month, year = Vide.untrack(viewDate).year })
		end
	end

	local function onYearChanged(id: number | string)
		local year = tonumber(id)
		if year then
			props.onViewDateChanged({ month = Vide.untrack(viewDate).month, year = year })
		end
	end

	local function month(): number
		return viewDate().month
	end
	local function year(): number
		return viewDate().year
	end

	local function dropdownWidth(textSize: () -> Vector2?, fallback: number): () -> UDim
		return function()
			local size = textSize()
			return UDim.new(0, if size then math.ceil(size.X) + dropdownNonTextWidth() else fallback)
		end
	end

	return View({
		LayoutOrder = props.LayoutOrder,
		tag = "row align-y-center gap-small size-full-0 auto-y padding-y-small",
		children = {
			named(
				"PreviousMonthButton",
				IconButton({
					icon = IconName.ChevronSmallLeft,
					LayoutOrder = 1,
					onActivated = props.onPreviousMonth,
					size = InputSize.Small,
					testId = `{props.testId}--previous-month-button`,
					variant = ButtonVariant.Utility,
				})
			),
			named(
				"MonthYearDropdowns",
				View({
					LayoutOrder = 2,
					tag = "row align-x-center align-y-center grow gap-small auto-y",
					children = {
						Dropdown.Root({
							items = monthItems,
							label = "",
							LayoutOrder = 1,
							maxHeight = menuMaxHeight,
							onItemChanged = onMonthChanged,
							scrollingFrameRef = useScrollToSelectedRef(function()
								return monthItems
							end, month),
							size = InputSize.XSmall,
							testId = `{props.testId}--month-dropdown`,
							value = month,
							variant = InputVariant.Utility,
							width = dropdownWidth(monthTextSize, 110),
						}),
						Dropdown.Root({
							items = yearItems,
							label = "",
							LayoutOrder = 2,
							maxHeight = menuMaxHeight,
							onItemChanged = onYearChanged,
							scrollingFrameRef = useScrollToSelectedRef(yearItems, year),
							size = InputSize.XSmall,
							testId = `{props.testId}--year-dropdown`,
							value = year,
							variant = InputVariant.Utility,
							width = dropdownWidth(yearTextSize, 70),
						}),
					},
				})
			),
			named(
				"NextMonthButton",
				IconButton({
					icon = IconName.ChevronSmallRight,
					LayoutOrder = 3,
					onActivated = props.onNextMonth,
					size = InputSize.Small,
					testId = `{props.testId}--next-month-button`,
					variant = ButtonVariant.Utility,
				})
			),
		},
	})
end

return CalendarHeader
