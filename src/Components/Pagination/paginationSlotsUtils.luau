local PaginationDirection = require("../../Enums/PaginationDirection")
type PaginationDirection = PaginationDirection.PaginationDirection

export type PageSlot = number | "ellipsis"

export type PaginationSelectableSlotOrderParams = {
	hasFirstLastButtons: boolean,
	isFirstDisabled: boolean,
	isBackDisabled: boolean,
	isForwardDisabled: boolean,
	isLastDisabled: boolean,
	pageSlots: { PageSlot }?,
	currentPage: number,
}

-- Page numbers shown before truncating with ellipses; the first and last page stay.
local MAX_VISIBLE_SLOTS = 7
local SIBLING_COUNT = 1
local ELLIPSIS: PageSlot = "ellipsis"

local NAV_SLOT_IDS = {
	[PaginationDirection.First] = "first",
	[PaginationDirection.Backward] = "back",
	[PaginationDirection.Forward] = "forward",
	[PaginationDirection.Last] = "last",
} :: { [PaginationDirection]: string }

--- The page row from left to right: page numbers, and "ellipsis" for each gap.
local function getVisiblePageSlots(currentPage: number, totalPages: number): { PageSlot }
	local slots: { PageSlot } = {}
	if totalPages <= MAX_VISIBLE_SLOTS then
		for page = 1, totalPages do
			table.insert(slots, page)
		end
		return slots
	end

	local boundaryThreshold = SIBLING_COUNT + 3

	if currentPage <= boundaryThreshold then
		for page = 1, MAX_VISIBLE_SLOTS - 2 do
			table.insert(slots, page)
		end
		table.insert(slots, ELLIPSIS)
		table.insert(slots, totalPages)
	elseif currentPage >= totalPages - boundaryThreshold + 1 then
		table.insert(slots, 1)
		table.insert(slots, ELLIPSIS)
		for page = totalPages - (MAX_VISIBLE_SLOTS - 3), totalPages do
			table.insert(slots, page)
		end
	else
		table.insert(slots, 1)
		table.insert(slots, ELLIPSIS)
		for page = currentPage - SIBLING_COUNT, currentPage + SIBLING_COUNT do
			table.insert(slots, page)
		end
		table.insert(slots, ELLIPSIS)
		table.insert(slots, totalPages)
	end

	return slots
end

local function getPageSlotId(page: number): string
	return `page-{page}`
end

--- Gamepad selection order of the nav buttons and page slots, left to right. Skips the current page and ellipses.
local function getPaginationSelectableSlotOrder(params: PaginationSelectableSlotOrderParams): { string }
	local order: { string } = {}

	if params.hasFirstLastButtons and not params.isFirstDisabled then
		table.insert(order, NAV_SLOT_IDS[PaginationDirection.First])
	end

	if not params.isBackDisabled then
		table.insert(order, NAV_SLOT_IDS[PaginationDirection.Backward])
	end

	if params.pageSlots then
		for _, slot in params.pageSlots do
			if slot ~= "ellipsis" and slot ~= params.currentPage then
				table.insert(order, getPageSlotId(slot :: number))
			end
		end
	end

	if not params.isForwardDisabled then
		table.insert(order, NAV_SLOT_IDS[PaginationDirection.Forward])
	end

	if params.hasFirstLastButtons and not params.isLastDisabled then
		table.insert(order, NAV_SLOT_IDS[PaginationDirection.Last])
	end

	return order
end

return {
	NAV_SLOT_IDS = NAV_SLOT_IDS,
	getPageSlotId = getPageSlotId,
	getPaginationSelectableSlotOrder = getPaginationSelectableSlotOrder,
	getVisiblePageSlots = getVisiblePageSlots,
}
