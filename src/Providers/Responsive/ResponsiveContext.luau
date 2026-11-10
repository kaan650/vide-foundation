local Vide = require("../../Packages/Vide")

local BreakpointConfig = require("../../Utility/Responsive/BreakpointConfig")
local GridConfig = require("../../Utility/Responsive/GridConfig")

export type BreakpointConfig = typeof(BreakpointConfig)
export type GridConfig = typeof(GridConfig)

export type ResponsiveConfig = {
	breakpoint: BreakpointConfig,
	grid: GridConfig,
}

export type ResponsiveContext = {
	config: ResponsiveConfig,
}

local DEFAULT: ResponsiveContext = {
	config = {
		breakpoint = BreakpointConfig,
		grid = GridConfig,
	},
}

local function default(): ResponsiveContext
	return DEFAULT
end

return {
	context = Vide.context(default :: () -> ResponsiveContext),
	DEFAULT = DEFAULT,
}
