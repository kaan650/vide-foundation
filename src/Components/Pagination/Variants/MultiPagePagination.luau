local Vide = require("../../../Packages/Vide")

local ChipSize = require("../../../Enums/ChipSize")
local ChipVariant = require("../../../Enums/ChipVariant")
local Ellipsis = require("../Nav/Ellipsis")
local PageNumberSlot = require("../Nav/PageNumberSlot")
local PaginationSize = require("../../../Enums/PaginationSize")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local named = require("../../../Utility/named")
local paginationSlotsUtils = require("../paginationSlotsUtils")
local paginationUtils = require("../paginationUtils")
local useChipVariants = require("../../Chip/useChipVariants")
local usePaginationAnimatedHighlight = require("../usePaginationAnimatedHighlight")
local usePaginationNav = require("../usePaginationNav")
local useTokens = require("../../../Providers/Style/useTokens")

type ChipSize = ChipSize.ChipSize
type PageSlot = paginationSlotsUtils.PageSlot
type PaginationNavInputProps = usePaginationNav.PaginationNavInputProps
type PaginationSize = PaginationSize.PaginationSize

type MultiPagePaginationProps = PaginationNavInputProps & {
	hasFirstLastButtons: Types.Value<boolean?>?,
}

type SlotEntry = {
	index: number,
	page: number?,
}

--- Every page number, or the first, last and those around the current one with ellipses between. A highlight slides
--- to the current page.
local function MultiPagePagination(props: MultiPagePaginationProps): GuiObject
	local tokens = useTokens()

	local function slotSize(): PaginationSize
		return Value.read(props.size)
	end
	local function page(): number
		return Value.read(props.page)
	end
	local function count(): number
		return Value.read(props.count) :: number
	end
	local function hasFirstLastButtons(): boolean
		return Value.read(props.hasFirstLastButtons) == true
	end
	local function isFirstDisabled(): boolean
		return page() <= 1
	end
	local function isForwardDisabled(): boolean
		return page() >= count()
	end

	local pageSlots = Vide.derive(function()
		return paginationSlotsUtils.getVisiblePageSlots(page(), count())
	end)

	local nav = usePaginationNav(props, {
		hasFirstLastButtons = hasFirstLastButtons,
		currentPage = page,
		pageSlots = pageSlots,
		disabledState = {
			isBackDisabled = isFirstDisabled,
			isFirstDisabled = isFirstDisabled,
			isForwardDisabled = isForwardDisabled,
			isLastDisabled = isForwardDisabled,
		},
	})

	local pagesContainer = Vide.source(nil :: GuiObject?)
	local getPagesContainer: () -> GuiObject? = pagesContainer :: any

	local highlight = usePaginationAnimatedHighlight(function()
		return paginationSlotsUtils.getPageSlotId(page())
	end, getPagesContainer, nav.selection.slotInstances, function()
		slotSize()
		pageSlots()
	end)

	local checkedVariantProps = Vide.derive(function()
		local chipSize: ChipSize = if slotSize() == PaginationSize.Small then ChipSize.Small else ChipSize.Medium
		return useChipVariants(tokens(), chipSize, ChipVariant.Utility, true, false, false)
	end)

	--* Keyed like Foundation's children, so a page keeps its slot while the row reflows.
	local slotEntries = Vide.derive(function(): { [string]: SlotEntry }
		local entries: { [string]: SlotEntry } = {}
		for index, slot in pageSlots() do
			if slot == "ellipsis" then
				entries[if index == 2 then "ellipsis-leading" else "ellipsis-trailing"] = { index = index }
			else
				entries[`Page-{slot}`] = { index = index, page = slot :: number }
			end
		end
		return entries
	end)

	local pageSlotChildren = Vide.indexes(slotEntries, function(entry: () -> SlotEntry, key: string): any
		local initial = Vide.untrack(entry)
		local function layoutOrder(): number
			return entry().index
		end

		local pageNumber = initial.page
		if pageNumber == nil then
			return named(
				key,
				Ellipsis({
					slotSize = slotSize,
					LayoutOrder = layoutOrder,
					testId = `{props.testId}--ellipsis-{initial.index}`,
				})
			)
		end

		local slotId = paginationSlotsUtils.getPageSlotId(pageNumber)
		local bindings = nav.selection.getSlotBindings(slotId)
		return named(
			key,
			PageNumberSlot({
				slotSize = slotSize,
				isChecked = function()
					return page() == pageNumber
				end,
				LayoutOrder = layoutOrder,
				onPageActivated = props.onActivated,
				page = pageNumber,
				testId = `{props.testId}--page-{pageNumber}`,
				ref = function(instance)
					nav.selection.registerSlot(slotId, instance)
				end,
				Selectable = bindings.Selectable,
				NextSelectionLeft = bindings.NextSelectionLeft,
				NextSelectionRight = bindings.NextSelectionRight,
				NextSelectionUp = bindings.NextSelectionUp,
				NextSelectionDown = bindings.NextSelectionDown,
			})
		)
	end)

	local pagesRow = View({
		tag = "row gap-xsmall auto-xy",
		LayoutOrder = 1,
		ZIndex = 2,
		onAbsoluteSizeChanged = function()
			highlight.syncSameItemHighlight()
		end,
		children = pageSlotChildren,
	})
	pagesRow.Name = "PagesRow"

	local activePageHighlight = Vide.show(function()
		return not paginationUtils.needsWidePageSlot(page())
	end, function()
		return named(
			"ActivePageHighlight",
			View({
				backgroundStyle = function()
					return checkedVariantProps().chip.backgroundStyle
				end,
				tag = "radius-circle clip",
				Size = function()
					return UDim2.fromOffset(highlight.highlightWidth(), highlight.activeItemHeight())
				end,
				Position = function()
					return UDim2.fromOffset(highlight.highlightPosition(), 0)
				end,
				Visible = highlight.isVisible,
				ZIndex = 1,
				selection = {
					Selectable = false,
				},
				testId = `{props.testId}--active-page-highlight`,
			})
		)
	end)

	local pages = View({
		LayoutOrder = 2,
		tag = "auto-xy",
		testId = `{props.testId}--pages`,
		children = { activePageHighlight, pagesRow },
	})
	pages.Name = "PageContent"
	pagesContainer(pages)

	return nav.createLayout(pages, function()
		return true
	end)
end

return MultiPagePagination
