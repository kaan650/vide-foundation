local Vide = require("../../Packages/Vide")

local Logger = require("../../Utility/Logger")
local Types = require("../Types")
type PopoverAnchor = Types.PopoverAnchor

export type PopoverContextValue = {
	anchor: () -> PopoverAnchor?,
	setAnchor: (anchor: PopoverAnchor?) -> (),
	isOpen: () -> boolean,
	testId: string,
}

local function noAnchor(): PopoverAnchor?
	return nil
end

local function closed(): boolean
	return false
end

return Vide.context({
	anchor = noAnchor,
	setAnchor = function(_anchor: PopoverAnchor?)
		Logger:warning("No PopoverProvider found for Popover")
	end,
	isOpen = closed,
	testId = "",
} :: PopoverContextValue)
