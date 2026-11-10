local Vide = require("../../Packages/Vide")

export type OverlayContextValue = {
	requestOverlay: () -> (),
	instance: () -> GuiBase2d?,
	screen: () -> GuiBase2d?,
}

local function none(): GuiBase2d?
	return nil
end

return Vide.context({
	requestOverlay = function() end,
	instance = none,
	screen = none,
} :: OverlayContextValue)
