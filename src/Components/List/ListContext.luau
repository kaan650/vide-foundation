local Vide = require("../../Packages/Vide")

local InputSize = require("../../Enums/InputSize")

type InputSize = InputSize.InputSize

export type ListContextValue = {
	hasDivider: () -> boolean,
	isContained: () -> boolean,
	isInset: () -> boolean,
	hasMargin: () -> boolean,
	-- The highest LayoutOrder among the list's children; the item with it has no divider.
	lastLayoutOrder: () -> number,
	size: () -> InputSize?,
	testId: string,
}

local function no(): boolean
	return false
end

return Vide.context({
	hasDivider = no,
	isContained = no,
	isInset = no,
	hasMargin = no,
	lastLayoutOrder = function()
		return 0
	end,
	size = function(): InputSize?
		return InputSize.Medium
	end,
	testId = "",
} :: ListContextValue)
