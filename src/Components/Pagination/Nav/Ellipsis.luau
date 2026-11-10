local PaginationSize = require("../../../Enums/PaginationSize")
local Text = require("../../Text")
local Types = require("../../Types")
local View = require("../../View")
local named = require("../../../Utility/named")
local paginationUtils = require("../paginationUtils")

type PaginationSize = PaginationSize.PaginationSize
type Value<T> = Types.Value<T>

type EllipsisProps = {
	slotSize: () -> PaginationSize,
	LayoutOrder: Value<number>,
	testId: string,
}

--- The "..." slot standing for skipped pages.
local function Ellipsis(props: EllipsisProps): GuiObject
	return View({
		LayoutOrder = props.LayoutOrder,
		tag = function()
			return paginationUtils.getCircularSlotTag(props.slotSize())
		end,
		testId = props.testId,
		children = named(
			"Text",
			Text({
				Text = "...",
				tag = function()
					return paginationUtils.getPageLabelTag(props.slotSize())
				end,
				LayoutOrder = 1,
			})
		),
	})
end

return Ellipsis
