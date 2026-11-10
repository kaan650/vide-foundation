local HeaderBarContext = require("../HeaderBarContext")
local HeaderBarSlot = require("../../../Enums/HeaderBarSlot")
local View = require("../../View")
local constants = require("../constants")
local useHeaderBarContext = require("../useHeaderBarContext")

export type HeaderBarTrailingProps = {
	-- Builds the slot's content, which must be created inside it.
	children: (() -> any)?,
}

--- The bar's end slot, for trailing actions.
local function HeaderBarTrailing(props: HeaderBarTrailingProps): GuiObject
	local headerBarContext = useHeaderBarContext()
	local children = props.children

	return View({
		tag = "row align-x-right align-y-center shrink gap-small size-full",
		LayoutOrder = constants.TRAILING_LAYOUT_ORDER,
		testId = `{headerBarContext.testId}--trailing`,
		children = if children
			then HeaderBarContext({ testId = headerBarContext.testId, slot = HeaderBarSlot.Trailing }, children)
			else nil,
	})
end

return HeaderBarTrailing
