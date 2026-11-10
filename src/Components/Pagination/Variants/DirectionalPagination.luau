local Vide = require("../../../Packages/Vide")

local Chip = require("../../Chip")
local ChipSize = require("../../../Enums/ChipSize")
local ChipVariant = require("../../../Enums/ChipVariant")
local PaginationSize = require("../../../Enums/PaginationSize")
local PaginationVariant = require("../../../Enums/PaginationVariant")
local Text = require("../../Text")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local named = require("../../../Utility/named")
local paginationUtils = require("../paginationUtils")
local usePaginationNav = require("../usePaginationNav")

type PaginationNavInputProps = usePaginationNav.PaginationNavInputProps
type PaginationSize = PaginationSize.PaginationSize
type PaginationVariant = PaginationVariant.PaginationVariant
type Value<T> = Types.Value<T>

type DirectionalPaginationProps = PaginationNavInputProps & {
	variant: Value<PaginationVariant>,
	hasNextPage: Value<boolean?>?,
	hasPreviousPage: Value<boolean?>?,
	hasFirstLastButtons: Value<boolean?>?,
}

type PageLabelKind = "wide" | "circular"

--- Back and forward buttons, with the current page between them for the SinglePage variant. Without `count`, whether
--- the buttons are enabled comes from `hasPreviousPage` and `hasNextPage`.
local function DirectionalPagination(props: DirectionalPaginationProps): GuiObject
	local function slotSize(): PaginationSize
		return Value.read(props.size)
	end
	local function page(): number
		return Value.read(props.page)
	end
	local function count(): number?
		return Value.read(props.count)
	end
	local function hasFirstLastButtons(): boolean
		return count() ~= nil and Value.read(props.hasFirstLastButtons) == true
	end
	local function showPageLabel(): boolean
		return Value.read(props.variant) == PaginationVariant.SinglePage
	end
	local function isBackDisabled(): boolean
		local hasPreviousPage: boolean? = Value.read(props.hasPreviousPage)
		return if hasPreviousPage ~= nil then hasPreviousPage ~= true else page() <= 1
	end
	local function isForwardDisabled(): boolean
		local total = count()
		local hasNextPage: boolean? = Value.read(props.hasNextPage)
		return if total ~= nil then page() >= total elseif hasNextPage ~= nil then hasNextPage ~= true else true
	end

	local nav = usePaginationNav(props, {
		hasFirstLastButtons = hasFirstLastButtons,
		currentPage = page,
		disabledState = {
			isBackDisabled = isBackDisabled,
			isFirstDisabled = isBackDisabled,
			isForwardDisabled = isForwardDisabled,
			isLastDisabled = isForwardDisabled,
		},
	})

	local function pageLabelText(): string
		return tostring(page())
	end
	local testId = `{props.testId}--page-label`

	local pageContent = Vide.switch(function(): PageLabelKind?
		if not showPageLabel() then
			return nil
		end
		return if paginationUtils.needsWidePageSlot(page()) then "wide" else "circular"
	end)({
		wide = function()
			return Chip({
				LayoutOrder = 2,
				isChecked = false,
				isDisabled = true,
				onActivated = function() end,
				size = function()
					return if slotSize() == PaginationSize.Small then ChipSize.Small else ChipSize.Medium
				end,
				testId = testId,
				text = pageLabelText,
				variant = ChipVariant.Utility,
			}) :: any
		end,
		circular = function()
			return View({
				LayoutOrder = 2,
				tag = function()
					return paginationUtils.getCircularSlotTag(slotSize())
				end,
				testId = testId,
				children = named(
					"Text",
					Text({
						Text = pageLabelText,
						tag = function()
							return paginationUtils.getPageLabelTag(slotSize())
						end,
						LayoutOrder = 1,
					})
				),
			})
		end,
	})

	return nav.createLayout(named("PageContent", pageContent), showPageLabel)
end

return DirectionalPagination
