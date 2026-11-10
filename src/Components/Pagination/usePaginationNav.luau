local Vide = require("../../Packages/Vide")

local NavPaginationLayout = require("./Nav/NavPaginationLayout")
local PaginationDirection = require("../../Enums/PaginationDirection")
local PaginationSize = require("../../Enums/PaginationSize")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local paginationSlotsUtils = require("./paginationSlotsUtils")
local usePaginationSelectionChain = require("./usePaginationSelectionChain")
local withCommonProps = require("../../Utility/withCommonProps")

type PageSlot = paginationSlotsUtils.PageSlot
type PaginationDirection = PaginationDirection.PaginationDirection
type PaginationSize = PaginationSize.PaginationSize
type PaginationSelectionChain = usePaginationSelectionChain.PaginationSelectionChain
type Value<T> = Types.Value<T>

export type PaginationNavInputProps = {
	page: Value<number>,
	count: Value<number?>?,
	onActivated: (page: number) -> (),
	size: Value<PaginationSize>,
	testId: string,
	ref: ((firstSlot: GuiObject?) -> ())?,
} & Types.CommonProps & Types.SelectionProps

export type PaginationNavDisabledState = {
	isBackDisabled: () -> boolean,
	isFirstDisabled: () -> boolean,
	isForwardDisabled: () -> boolean,
	isLastDisabled: () -> boolean,
}

export type UsePaginationNavConfig = {
	hasFirstLastButtons: () -> boolean,
	currentPage: () -> number,
	pageSlots: (() -> { PageSlot })?,
	disabledState: PaginationNavDisabledState,
}

export type PaginationNav = {
	selection: PaginationSelectionChain,
	-- The pagination row around `pageContent`.
	createLayout: (pageContent: Types.Children?, hasPageContent: () -> boolean) -> GuiObject,
}

--- The nav shell both pagination variants share: gamepad selection order, the direction buttons' callbacks, and the
--- layout. Call it while the component is being created.
local function usePaginationNav(props: PaginationNavInputProps, config: UsePaginationNavConfig): PaginationNav
	local disabledState = config.disabledState

	local function slotSize(): PaginationSize
		return Value.read(props.size)
	end

	--* First is redundant when back is disabled (already on page 1).
	local function isFirstDisabled(): boolean
		return disabledState.isFirstDisabled() or disabledState.isBackDisabled()
	end

	local slotOrder = Vide.derive(function()
		return paginationSlotsUtils.getPaginationSelectableSlotOrder({
			hasFirstLastButtons = config.hasFirstLastButtons(),
			isFirstDisabled = disabledState.isFirstDisabled(),
			isBackDisabled = disabledState.isBackDisabled(),
			isForwardDisabled = disabledState.isForwardDisabled(),
			isLastDisabled = disabledState.isLastDisabled(),
			pageSlots = if config.pageSlots then config.pageSlots() else nil,
			currentPage = config.currentPage(),
		})
	end)

	local selection = usePaginationSelectionChain(slotOrder, {
		NextSelectionUp = props.NextSelectionUp,
		NextSelectionDown = props.NextSelectionDown,
	})

	local ref = props.ref
	if ref then
		Vide.effect(function()
			local firstSlot = selection.firstSlot()
			Vide.untrack(function()
				ref(firstSlot)
			end)
		end)
	end

	local function onDirectionActivated(direction: PaginationDirection)
		local page: number = Value.read(props.page)
		if direction == PaginationDirection.First then
			props.onActivated(1)
		elseif direction == PaginationDirection.Last then
			local count: number? = Value.read(props.count)
			if count ~= nil then
				props.onActivated(count)
			end
		elseif direction == PaginationDirection.Backward then
			props.onActivated(page - 1)
		else
			props.onActivated(page + 1)
		end
	end

	local function createLayout(pageContent: Types.Children?, hasPageContent: () -> boolean): GuiObject
		return NavPaginationLayout(withCommonProps(props, {
			pageContent = pageContent,
			hasPageContent = hasPageContent,
			size = slotSize,
			isBackDisabled = disabledState.isBackDisabled,
			isFirstDisabled = isFirstDisabled,
			isForwardDisabled = disabledState.isForwardDisabled,
			isLastDisabled = disabledState.isLastDisabled,
			onDirectionActivated = onDirectionActivated,
			selection = selection,
			hasFirstLastButtons = config.hasFirstLastButtons,
			testId = props.testId,
		}))
	end

	return {
		selection = selection,
		createLayout = createLayout,
	}
end

return usePaginationNav
