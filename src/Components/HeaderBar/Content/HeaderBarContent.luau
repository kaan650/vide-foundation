local HeaderBarContext = require("../HeaderBarContext")
local HeaderBarSlot = require("../../../Enums/HeaderBarSlot")
local View = require("../../View")
local constants = require("../constants")
local useHeaderBarContext = require("../useHeaderBarContext")

export type HeaderBarContentProps = {
	-- Builds the slot's content, which must be created inside it.
	children: (() -> any)?,
}

--- The bar's middle slot, which grows to fill the space between Leading and Trailing.
local function HeaderBarContent(props: HeaderBarContentProps): GuiObject
	local headerBarContext = useHeaderBarContext()
	local children = props.children

	return View({
		tag = "align-y-center grow size-0-full auto-x",
		LayoutOrder = constants.CONTENT_LAYOUT_ORDER,
		testId = `{headerBarContext.testId}--content`,
		children = if children
			then HeaderBarContext({ testId = headerBarContext.testId, slot = HeaderBarSlot.Content }, children)
			else nil,
	})
end

return HeaderBarContent
