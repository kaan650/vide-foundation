local OverlayContext = require("./OverlayContext")

--- The overlay container as a source. Asking for it mounts the provider's overlay ScreenGui.
local function useOverlay(): () -> GuiBase2d?
	local context = OverlayContext()
	context.requestOverlay()
	return context.instance
end

return useOverlay
