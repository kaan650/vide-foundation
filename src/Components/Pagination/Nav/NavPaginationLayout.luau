local NavControls = require("./NavControls")
local PaginationDirection = require("../../../Enums/PaginationDirection")
local PaginationSize = require("../../../Enums/PaginationSize")
local Types = require("../../Types")
local View = require("../../View")
local usePaginationSelectionChain = require("../usePaginationSelectionChain")
local withCommonProps = require("../../../Utility/withCommonProps")

type NavControlsSide = NavControls.NavControlsSide
type PaginationDirection = PaginationDirection.PaginationDirection
type PaginationSize = PaginationSize.PaginationSize
type PaginationSelectionChain = usePaginationSelectionChain.PaginationSelectionChain
type Value<T> = Types.Value<T>

export type NavPaginationLayoutSpecificProps = {
	size: () -> PaginationSize,
	testId: string,
	hasFirstLastButtons: () -> boolean,
	isFirstDisabled: () -> boolean,
	isBackDisabled: () -> boolean,
	isForwardDisabled: () -> boolean,
	isLastDisabled: () -> boolean,
	onDirectionActivated: (direction: PaginationDirection) -> (),
	-- Shown between the nav buttons, named `PageContent`.
	pageContent: Types.Children?,
	hasPageContent: () -> boolean,
	selection: PaginationSelectionChain,
}

export type NavPaginationLayoutProps = NavPaginationLayoutSpecificProps & Types.CommonProps

--- The pagination row: back buttons, the page content, forward buttons.
local function NavPaginationLayout(props: NavPaginationLayoutProps): GuiObject
	local function navControls(side: NavControlsSide, name: string, layoutOrder: Value<number>): GuiObject
		local controls = NavControls({
			side = side,
			size = props.size,
			LayoutOrder = layoutOrder,
			isFirstDisabled = props.isFirstDisabled,
			isBackDisabled = props.isBackDisabled,
			isForwardDisabled = props.isForwardDisabled,
			isLastDisabled = props.isLastDisabled,
			onDirectionActivated = props.onDirectionActivated,
			hasFirstLastButtons = props.hasFirstLastButtons,
			testId = props.testId,
			selection = props.selection,
		})
		controls.Name = name
		return controls
	end

	local children: { any } = { navControls("start", "LeftNav", 1) }
	if props.pageContent ~= nil then
		table.insert(children, props.pageContent)
	end
	table.insert(
		children,
		navControls("end", "RightNav", function()
			return if props.hasPageContent() then 3 else 2
		end)
	)

	return View(withCommonProps(props, {
		tag = "row align-y-center gap-small auto-xy",
		children = children,
	}) :: any)
end

return NavPaginationLayout
