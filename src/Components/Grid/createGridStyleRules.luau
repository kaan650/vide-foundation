local Breakpoint = require("../../Enums/Breakpoint")
local BreakpointShortName = require("../../Enums/BreakpointShortName")
local ResponsiveContext = require("../../Providers/Responsive/ResponsiveContext")

type ResponsiveConfig = ResponsiveContext.ResponsiveConfig
type Breakpoint = Breakpoint.Breakpoint
type BreakpointShortName = BreakpointShortName.BreakpointShortName

export type GridStyleRule = {
	Selector: string,
	properties: { [string]: any },
}

export type GridStyleRules = {
	baseRules: { [string]: GridStyleRule },
	rulesByBreakpoint: { [Breakpoint]: { [string]: GridStyleRule } },
}

local function createGridStyleRule(i: number, shortName: BreakpointShortName?): GridStyleRule
	local selector = if shortName then `.{shortName}-col-{i}` else `.col-{i}`
	return {
		Selector = `{selector} ::UISizeConstraint`,
		properties = {
			MinSize = `$ColMin{i}`,
			MaxSize = `$ColMax{i}`,
		},
	}
end

--- The rules that size `col-N` and `<breakpoint>-col-N` tagged cells, keyed by the names Foundation gives them.
local function createGridStyleRules(responsiveConfig: ResponsiveConfig): GridStyleRules
	local breakpointConfig = responsiveConfig.breakpoint
	local gridConfig = responsiveConfig.grid
	local maxBreakpoint = breakpointConfig.order[#breakpointConfig.order]
	local maxColCount = gridConfig.columns[maxBreakpoint]
	local rulesByBreakpoint: { [Breakpoint]: { [string]: GridStyleRule } } = {}

	local baseRules: { [string]: GridStyleRule } = {}
	for i = 0, maxColCount do
		baseRules[`Col{i}`] = createGridStyleRule(i)
	end
	baseRules.ColVisible0 = {
		Selector = ".col-0",
		properties = { Visible = false },
	}

	for _, breakpoint in breakpointConfig.order do
		local shortName = breakpointConfig.shortNames[breakpoint]
		local rules: { [string]: GridStyleRule } = {}
		for i = 0, gridConfig.columns[breakpoint] do
			rules[`{breakpoint}Col{i}`] = createGridStyleRule(i, shortName)
		end
		rules[`{breakpoint}ColVisible0`] = {
			Selector = `.{shortName}-col-0`,
			properties = { Visible = false },
		}
		rulesByBreakpoint[breakpoint] = rules
	end

	return {
		baseRules = baseRules,
		rulesByBreakpoint = rulesByBreakpoint,
	}
end

return createGridStyleRules
