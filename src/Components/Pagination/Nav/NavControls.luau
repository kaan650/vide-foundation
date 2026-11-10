local Vide = require("../../../Packages/Vide")

local NavButton = require("./NavButton")
local PaginationDirection = require("../../../Enums/PaginationDirection")
local PaginationSize = require("../../../Enums/PaginationSize")
local Types = require("../../Types")
local View = require("../../View")
local named = require("../../../Utility/named")
local paginationSlotsUtils = require("../paginationSlotsUtils")
local usePaginationSelectionChain = require("../usePaginationSelectionChain")

type PaginationDirection = PaginationDirection.PaginationDirection
type PaginationSize = PaginationSize.PaginationSize
type PaginationSelectionChain = usePaginationSelectionChain.PaginationSelectionChain
type Value<T> = Types.Value<T>

export type NavControlsSide = "start" | "end"

type NavControlsProps = {
	side: NavControlsSide,
	size: () -> PaginationSize,
	LayoutOrder: Value<number>,
	isFirstDisabled: () -> boolean,
	isBackDisabled: () -> boolean,
	isForwardDisabled: () -> boolean,
	isLastDisabled: () -> boolean,
	onDirectionActivated: (direction: PaginationDirection) -> (),
	hasFirstLastButtons: () -> boolean,
	testId: string,
	selection: PaginationSelectionChain,
}

local SIDE_DIRECTIONS: { [NavControlsSide]: { PaginationDirection } } = {
	start = { PaginationDirection.First, PaginationDirection.Backward },
	["end"] = { PaginationDirection.Forward, PaginationDirection.Last },
}

local SIDE_TEST_ID: { [NavControlsSide]: string } = {
	start = "left-nav",
	["end"] = "right-nav",
}

local function isFirstOrLast(direction: PaginationDirection): boolean
	return direction == PaginationDirection.First or direction == PaginationDirection.Last
end

local function getIsDisabled(direction: PaginationDirection, props: NavControlsProps): () -> boolean
	if direction == PaginationDirection.First then
		return props.isFirstDisabled
	elseif direction == PaginationDirection.Backward then
		return props.isBackDisabled
	elseif direction == PaginationDirection.Forward then
		return props.isForwardDisabled
	end
	return props.isLastDisabled
end

--- The nav buttons on one side of the page content: first and back, or forward and last.
local function NavControls(props: NavControlsProps): GuiObject
	local directions = SIDE_DIRECTIONS[props.side]

	local function isShown(direction: PaginationDirection): boolean
		return not isFirstOrLast(direction) or props.hasFirstLastButtons()
	end

	local children = {}
	for index, direction in directions do
		local slotId = paginationSlotsUtils.NAV_SLOT_IDS[direction]

		local function button()
			local bindings = props.selection.getSlotBindings(slotId)
			return props.selection.bindSlot(
				slotId,
				named(
					direction,
					NavButton({
						baseTestId = props.testId,
						slotSize = props.size,
						direction = direction,
						isDisabled = getIsDisabled(direction, props),
						LayoutOrder = function()
							local layoutOrder = 0
							for i = 1, index do
								if isShown(directions[i]) then
									layoutOrder += 1
								end
							end
							return layoutOrder
						end,
						onDirectionActivated = props.onDirectionActivated,
						Selectable = bindings.Selectable,
						NextSelectionLeft = bindings.NextSelectionLeft,
						NextSelectionRight = bindings.NextSelectionRight,
						NextSelectionUp = bindings.NextSelectionUp,
						NextSelectionDown = bindings.NextSelectionDown,
					})
				)
			)
		end

		table.insert(children, if isFirstOrLast(direction) then Vide.show(props.hasFirstLastButtons, button) else button())
	end

	return View({
		LayoutOrder = props.LayoutOrder,
		tag = "row gap-xsmall auto-xy",
		testId = `{props.testId}--{SIDE_TEST_ID[props.side]}`,
		children = children,
	})
end

return NavControls
