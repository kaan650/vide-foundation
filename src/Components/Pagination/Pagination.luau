local DirectionalPagination = require("./Variants/DirectionalPagination")
local MultiPagePagination = require("./Variants/MultiPagePagination")
local PaginationSize = require("../../Enums/PaginationSize")
local PaginationVariant = require("../../Enums/PaginationVariant")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local rebuildOn = require("../../Utility/rebuildOn")
local withDefaults = require("../../Utility/withDefaults")

type PaginationSize = PaginationSize.PaginationSize
type PaginationVariant = PaginationVariant.PaginationVariant
type Value<T> = Types.Value<T>

export type PaginationProps = {
	-- MultiPage shows page numbers; SinglePage and NoPage show only the direction buttons, SinglePage with the
	-- current page between them.
	variant: Value<PaginationVariant>?,
	page: Value<number>,
	onActivated: (page: number) -> (),
	-- Number of pages. Required for MultiPage; optional for the other variants, which then rely on
	-- `hasNextPage` and `hasPreviousPage`.
	count: Value<number?>?,
	hasNextPage: Value<boolean?>?,
	hasPreviousPage: Value<boolean?>?,
	-- Adds first and last page buttons. The SinglePage and NoPage variants need `count` for them.
	hasFirstLastButtons: Value<boolean?>?,
	size: Value<PaginationSize>?,
	-- Receives the first selectable button or page, for gamepad focus.
	ref: ((firstSlot: GuiObject?) -> ())?,
} & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	variant = PaginationVariant.MultiPage :: PaginationVariant,
	size = PaginationSize.Medium :: PaginationSize,
	testId = "--foundation-pagination",
}

--- Buttons for moving between pages. A source `variant` returns a source of the instance, since MultiPage and the
--- directional variants are different components.
local function Pagination(paginationProps: PaginationProps): GuiObject | () -> GuiObject
	local props = withDefaults(paginationProps, defaultProps)
	local variant = props.variant

	local isMultiPage: Value<boolean> = if type(variant) == "function"
		then function()
			return Value.read(variant) == PaginationVariant.MultiPage
		end
		else variant == PaginationVariant.MultiPage

	return rebuildOn(isMultiPage, function(multiPage: boolean): GuiObject
		if multiPage then
			return MultiPagePagination(props :: any)
		end
		return DirectionalPagination(props :: any)
	end)
end

return Pagination
