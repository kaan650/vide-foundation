local Vide = require("../../Packages/Vide")

local InputPlacement = require("../../Enums/InputPlacement")
local InputSize = require("../../Enums/InputSize")
local Types = require("../Types")

type InputPlacement = InputPlacement.InputPlacement
type InputSize = InputSize.InputSize
type ItemId = Types.ItemId

-- Called when an item is activated, with its id and whether it is expanded; returns the item's activation handler.
export type onAccordionItemActivated = (id: ItemId, isExpanded: boolean?) -> (() -> ())?

export type AccordionConfiguration = {
	onAccordionItemActivated: onAccordionItemActivated?,
	itemSize: () -> InputSize,
	isContained: () -> boolean,
	chevronPosition: () -> InputPlacement,
	testId: string?,
}

return Vide.context({
	onAccordionItemActivated = nil,
	itemSize = function()
		return InputSize.Medium
	end,
	isContained = function()
		return false
	end,
	chevronPosition = function()
		return InputPlacement.End
	end,
	testId = "",
} :: AccordionConfiguration)
