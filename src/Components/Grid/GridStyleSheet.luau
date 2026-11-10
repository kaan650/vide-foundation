local Vide = require("../../Packages/Vide")

local Breakpoint = require("../../Enums/Breakpoint")
local Dash = require("../../Utility/Dash")
local StyleRule = require("../../StyleSheet/StyleRule")
local StyleSheetContext = require("../../Providers/Style/StyleSheetContext")
local createGridStyleRules = require("./createGridStyleRules")
local create = require("../../Utility/create")
local getGridMetrics = require("../../Utility/getGridMetrics")
local useResponsive = require("../../Providers/Responsive/useResponsive")

type Breakpoint = Breakpoint.Breakpoint
type GridStyleRule = createGridStyleRules.GridStyleRule

type GridStyleSheetProps = {
	breakpoint: () -> Breakpoint?,
	containerWidth: () -> number,
}

--- A StyleSheet, derived from the provider's, whose attributes size the grid's cells for the current breakpoint and
--- width, and the StyleLink that applies it to the instance both are placed in.
local function GridStyleSheet(props: GridStyleSheetProps): { Instance }
	local responsive = useResponsive()
	local styleSheet = StyleSheetContext.useStyleSheet()

	local function config()
		return responsive().config
	end
	local function breakpoint(): Breakpoint
		local order = config().breakpoint.order
		return props.breakpoint() or order[#order]
	end

	local gridStyleRules = Vide.derive(function()
		return createGridStyleRules(config())
	end)
	local styleRules = Vide.derive(function(): { [string]: GridStyleRule }
		local rules = gridStyleRules()
		return Dash.join(rules.baseRules, rules.rulesByBreakpoint[breakpoint()])
	end)

	local sheet = create("StyleSheet")({
		Name = "GridStyleSheet",
		Vide.indexes(styleRules, function(rule: () -> GridStyleRule, name: string)
			local instance = StyleRule({
				Selector = function()
					return rule().Selector
				end,
				properties = function()
					return rule().properties
				end,
			})
			instance.Name = name
			Vide.cleanup(instance)
			return instance
		end),
	})

	Vide.effect(function()
		local responsiveConfig = config()
		local current = breakpoint()
		local containerWidth = math.max(1, props.containerWidth())
		local gridConfig = responsiveConfig.grid
		local order = responsiveConfig.breakpoint.order
		local maxColCount = gridConfig.columns[order[#order]]
		local breakpointColCount = gridConfig.columns[current]

		--* Column attributes are shared by every breakpoint, so only the current breakpoint's rules are active.
		for i = 0, maxColCount do
			local metrics = getGridMetrics(responsiveConfig, current, containerWidth, math.min(i, breakpointColCount))
			sheet:SetAttribute(`Col{i}`, metrics.cellSize)
			sheet:SetAttribute(`ColMin{i}`, Vector2.new(metrics.cellWidth, 0))
			sheet:SetAttribute(`ColMax{i}`, Vector2.new(metrics.cellWidth, math.huge))
		end
	end)

	Vide.effect(function()
		local parent = styleSheet()
		sheet:SetDerives(if parent then { parent } else {})
	end)

	return {
		sheet,
		create("StyleLink")({
			Name = "GridStyleLink",
			StyleSheet = sheet,
		}),
	}
end

return GridStyleSheet
