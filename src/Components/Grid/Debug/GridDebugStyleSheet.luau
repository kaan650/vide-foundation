local Vide = require("../../../Packages/Vide")

local Breakpoint = require("../../../Enums/Breakpoint")
local StyleRule = require("../../../StyleSheet/StyleRule")
local StyleSheetContext = require("../../../Providers/Style/StyleSheetContext")
local create = require("../../../Utility/create")
local useResponsive = require("../../../Providers/Responsive/useResponsive")

type Breakpoint = Breakpoint.Breakpoint

export type GridDebugStyleSheetProps = {
	breakpoint: () -> Breakpoint?,
}

type DebugRule = { Selector: string, color: Color3 }

--- A StyleSheet, derived from the provider's, that colors each `col-N` cell by its span, and the StyleLink for it.
--- Returns the sheet as well, for the content that should use it.
local function GridDebugStyleSheet(props: GridDebugStyleSheetProps): ({ Instance }, StyleSheet)
	local responsive = useResponsive()
	local styleSheet = StyleSheetContext.useStyleSheet()

	local rules = Vide.derive(function(): { [string]: DebugRule }
		local config = responsive().config
		local order = config.breakpoint.order
		local breakpoint = props.breakpoint() or order[#order]
		local shortName = config.breakpoint.shortNames[breakpoint]
		local breakpointColCount = config.grid.columns[breakpoint]
		local result: { [string]: DebugRule } = {}

		for i = 0, breakpointColCount do
			local selector = if shortName then `.{shortName}-col-{i}` else `.col-{i}`
			local ratio = i / math.max(1, breakpointColCount)
			result[`DebugColColor${i}`] = {
				Selector = selector,
				color = Color3.fromRGB(
					math.floor(255 * ratio),
					math.floor(255 * (1 - ratio)),
					math.floor(255 * ((i % 3) / 2))
				),
			}
		end
		return result
	end)

	local sheet = create("StyleSheet")({
		Name = "GridDebugStyleSheet",
		Vide.indexes(rules, function(rule: () -> DebugRule, name: string)
			local instance = StyleRule({
				Selector = function()
					return rule().Selector
				end,
				properties = function()
					return { BackgroundColor3 = rule().color }
				end,
			})
			instance.Name = name
			Vide.cleanup(instance)
			return instance
		end),
	})

	Vide.effect(function()
		local parent = styleSheet()
		sheet:SetDerives(if parent then { parent } else {})
	end)

	return {
		sheet,
		create("StyleLink")({
			Name = "GridDebugStyleLink",
			StyleSheet = sheet,
		}),
	}, sheet
end

return GridDebugStyleSheet
