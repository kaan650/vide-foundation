local HeaderBarContext = require("../HeaderBarContext")
local HeaderBarSlot = require("../../../Enums/HeaderBarSlot")
local View = require("../../View")
local constants = require("../constants")
local useHeaderBarContext = require("../useHeaderBarContext")

export type HeaderBarLeadingProps = {
	-- Builds the slot's content, which must be created inside it.
	children: (() -> any)?,
}

--- The bar's start slot, for a back button or leading actions.
local function HeaderBarLeading(props: HeaderBarLeadingProps): GuiObject
	local headerBarContext = useHeaderBarContext()
	local children = props.children

	return View({
		tag = "row align-y-center shrink gap-small size-full",
		LayoutOrder = constants.LEADING_LAYOUT_ORDER,
		testId = `{headerBarContext.testId}--leading`,
		children = if children
			then HeaderBarContext({ testId = headerBarContext.testId, slot = HeaderBarSlot.Leading }, children)
			else nil,
	})
end

return HeaderBarLeading
