local OverlayContext = require("./OverlayContext")

--- The overlay's ScreenGui as a source. Asking for it mounts the provider's overlay ScreenGui.
local function useScreen(): () -> GuiBase2d?
	local context = OverlayContext()
	context.requestOverlay()
	return context.screen
end

return useScreen
