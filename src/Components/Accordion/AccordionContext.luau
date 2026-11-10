local Vide = require("../../Packages/Vide")

local InputSize = require("../../Enums/InputSize")
local Types = require("../Types")

type InputSize = InputSize.InputSize
type ItemId = Types.ItemId

-- Called when an item is activated, with its id and whether it is expanded; returns the item's activation handler.
export type onAccordionItemActivated = (id: ItemId, isExpanded: boolean?) -> (() -> ())?

export type AccordionConfiguration = {
	onAccordionItemActivated: onAccordionItemActivated?,
	itemSize: () -> InputSize,
	testId: string?,
}

return Vide.context({
	onAccordionItemActivated = nil,
	itemSize = function()
		return InputSize.Medium
	end,
	testId = "",
} :: AccordionConfiguration)
