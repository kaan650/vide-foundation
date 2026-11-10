local ResponsiveContext = require("./ResponsiveContext")

local function useResponsive(): () -> ResponsiveContext.ResponsiveContext
	return ResponsiveContext.context()
end

return useResponsive
