local Breakpoint = require("../../../Enums/Breakpoint")
local useBreakpoint = require("./useBreakpoint")
local useScreen = require("../../Overlay/useScreen")

--- The breakpoint for the width of the overlay ScreenGui, as a source.
local function useViewportBreakpoint(): () -> Breakpoint.Breakpoint
	local breakpoint = useBreakpoint(useScreen())
	return breakpoint
end

return useViewportBreakpoint
