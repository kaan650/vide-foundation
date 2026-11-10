local Vide = require("../../../Packages/Vide")

local Breakpoint = require("../../../Enums/Breakpoint")
local GridDebugStyleSheet = require("./GridDebugStyleSheet")
local StyleSheetContext = require("../../../Providers/Style/StyleSheetContext")
local Text = require("../../Text")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local create = require("../../../Utility/create")
local getGridMetrics = require("../../../Utility/getGridMetrics")
local useBreakpoint = require("../../../Providers/Responsive/Hooks/useBreakpoint")
local useResponsive = require("../../../Providers/Responsive/useResponsive")
local useTokens = require("../../../Providers/Style/useTokens")
local withDefaults = require("../../../Utility/withDefaults")

type Breakpoint = Breakpoint.Breakpoint
type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

type GridDebugColProps = {
	width: Value<number>?,
	backgroundStyle: Value<ColorStyleValue>,
	LayoutOrder: number?,
}

local function DebugCol(props: GridDebugColProps): GuiObject
	return View({
		Size = function()
			return UDim2.new(0, Value.read(props.width) or 0, 1, 0)
		end,
		backgroundStyle = props.backgroundStyle,
		LayoutOrder = props.LayoutOrder,
	})
end

export type GridDebugProps = {
	align: Value<Enum.ItemLineAlignment?>?,
	debugTransparency: Value<number>?,
	-- Builds the content shown over the overlay. It runs inside the debug StyleSheet, so cells in it are colored.
	children: (() -> any)?,
}

local defaultProps = {
	debugTransparency = 0.7,
}

local alignTags: { [Enum.ItemLineAlignment]: string } = {
	[Enum.ItemLineAlignment.Start] = "position-top-left anchor-top-left",
	[Enum.ItemLineAlignment.Center] = "position-top-center anchor-top-center",
	[Enum.ItemLineAlignment.End] = "position-top-right anchor-top-right",
}

--- An overlay that draws a Grid's margins, columns and gutters at the current breakpoint, with a label of its
--- metrics. For development.
local function GridDebug(gridDebugProps: GridDebugProps): GuiObject
	local props = withDefaults(gridDebugProps, defaultProps)
	local tokens = useTokens()
	local responsive = useResponsive()
	local measureInstance = Vide.source(nil :: GuiObject?)
	local breakpoint, absoluteSize = useBreakpoint(measureInstance)
	local metrics = Vide.derive(function()
		return getGridMetrics(responsive().config, breakpoint(), absoluteSize().X)
	end)

	local function maxWidth(): number
		return responsive().config.breakpoint.widths[Breakpoint.XLarge]
	end
	local function maxSize(): Vector2
		return Vector2.new(maxWidth(), math.huge)
	end
	local function debugTransparency(): number
		return Value.read(props.debugTransparency)
	end
	local function systemStyle(name: string, transparency: () -> number): () -> ColorStyleValue
		return function()
			return { Color3 = (tokens().Color.System :: any)[name].Color3, Transparency = transparency() }
		end
	end

	local sheetChildren, debugSheet = GridDebugStyleSheet({ breakpoint = breakpoint })

	local measureWrapper = View({
		tag = "size-full-0",
		children = create("UISizeConstraint")({
			Name = "GridMeasureSizeConstraint",
			MaxSize = maxSize,
		}),
	})
	measureWrapper.Name = "GridDebugMeasureWrapper"
	measureInstance(measureWrapper)

	local measure = View({
		Size = UDim2.new(1, 0, 0, 4),
		backgroundStyle = function(): ColorStyleValue
			return { Color3 = Color3.fromRGB(255, 0, 0), Transparency = debugTransparency() }
		end,
	})
	measure.Name = "GridDebugMeasure"

	local sizeLabel = Text({
		tag = "position-top-center anchor-top-center auto-xy padding-xxsmall text-label-small text-truncate-end bg-over-media-300",
		Text = function()
			local config = responsive().config
			local current = metrics()
			return `breakpoint: {config.breakpoint.shortNames[breakpoint()]}, width: {absoluteSize().X}, columns: {current.full.colCount}, maxWidth: {maxWidth()}, margin: {current.margin}, gapWidth: {current.gutterWidth}`
		end,
	})
	sizeLabel.Name = "GridDebugSizeLabel"

	local gutters = Vide.indexes(function()
		local indexes: { [number]: true } = {}
		for i = 1, metrics().full.colCount - 1 do
			indexes[i] = true
		end
		return indexes
	end, function(_, i: number)
		local col = DebugCol({
			width = function()
				return metrics().gutterWidth
			end,
			backgroundStyle = systemStyle("Alert", function()
				return 0.5
			end),
			LayoutOrder = i,
		})
		col.Name = `DebugCol{i}`
		return col
	end)

	local function margin(name: string, layoutOrder: number): GuiObject
		local col = DebugCol({
			width = function()
				return metrics().margin
			end,
			backgroundStyle = systemStyle("Warning", debugTransparency),
			LayoutOrder = layoutOrder,
		})
		col.Name = name
		return col
	end

	local columns = View({
		tag = "row flex-x-evenly fill size-0-full",
		backgroundStyle = systemStyle("Emphasis", debugTransparency),
		LayoutOrder = 1,
		children = gutters,
	})
	columns.Name = "Columns"

	local overlay = View({
		tag = "row size-full-full",
		backgroundStyle = systemStyle("Emphasis", debugTransparency),
		children = { margin("LeftMargin", 0), columns, margin("RightMargin", 2) },
	})
	overlay.Name = "GridDebug"

	local content = StyleSheetContext.context(function(): StyleSheet?
		return debugSheet
	end, function()
		local view = View({
			tag = "size-full-full",
			children = {
				create("UIPadding")({
					Name = "GridDebugPadding",
					PaddingTop = function()
						return UDim.new(0, metrics().gapHeight * 2)
					end,
				}),
				if props.children then props.children() else nil,
			},
		})
		view.Name = "GridDebugContent"
		return view
	end)

	return View({
		tag = function()
			local align: Enum.ItemLineAlignment? = Value.read(props.align)
			--* Foundation interpolates a missing alignment, which adds a "nil" tag.
			return `size-full-full {if align then alignTags[align] else nil}`
		end,
		children = {
			sheetChildren,
			measureWrapper,
			measure,
			create("UISizeConstraint")({
				Name = "GridDebugSizeConstraint",
				MaxSize = maxSize,
			}),
			sizeLabel,
			overlay,
			content,
		},
	})
end

return GridDebug
