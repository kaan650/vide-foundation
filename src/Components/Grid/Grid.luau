local Vide = require("../../Packages/Vide")

local Breakpoint = require("../../Enums/Breakpoint")
local GridStyleSheet = require("./GridStyleSheet")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local create = require("../../Utility/create")
local getGridMetrics = require("../../Utility/getGridMetrics")
local useBreakpoint = require("../../Providers/Responsive/Hooks/useBreakpoint")
local useResponsive = require("../../Providers/Responsive/useResponsive")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type Value<T> = Types.Value<T>

local alignTags = {
	[Enum.ItemLineAlignment.Start] = "items-start",
	[Enum.ItemLineAlignment.Center] = "items-center",
	[Enum.ItemLineAlignment.End] = "items-end",
}

export type GridProps = {
	align: Value<Enum.ItemLineAlignment>?,
	SortOrder: Value<Enum.SortOrder>?,
	Wraps: Value<boolean>?,
	tag: Value<string>?,
	children: Types.Children?,
} & Types.CommonProps

local defaultProps = {
	tag = "size-full-0 auto-y",
	align = Enum.ItemLineAlignment.Start,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Wraps = true,
	testId = "--foundation-grid",
}

--- A responsive column grid. It measures its own width, picks a breakpoint from it and sizes `Grid.Cell` children
--- by their column spans.
local function Grid(gridProps: GridProps): GuiObject
	local props = withDefaults(gridProps, defaultProps)
	local responsive = useResponsive()
	local measureInstance = Vide.source(nil :: GuiObject?)
	local breakpoint, absoluteSize = useBreakpoint(measureInstance)
	local gridMetrics = Vide.derive(function()
		return getGridMetrics(responsive().config, breakpoint(), absoluteSize().X)
	end)

	local function maxWidth(): number
		return responsive().config.breakpoint.widths[Breakpoint.XLarge]
	end
	local function maxSize(): Vector2
		return Vector2.new(maxWidth(), math.huge)
	end
	local function wraps(): boolean
		return Value.read(props.Wraps) == true
	end

	local measure = View({
		tag = "size-full-0",
		children = create("UISizeConstraint")({
			Name = "GridMeasureSizeConstraint",
			MaxSize = maxSize,
		}),
	})
	measure.Name = "GridMeasure"
	measureInstance(measure)

	local grid = View({
		tag = "auto-y",
		Size = function()
			return UDim2.fromOffset(absoluteSize().X, 0)
		end,
		layout = function(): Types.ListLayout
			return {
				Padding = if not wraps() then UDim.new(0, gridMetrics().gutterWidth) else nil,
				SortOrder = Value.read(props.SortOrder),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = if wraps() then Enum.UIFlexAlignment.SpaceBetween else nil,
				Wraps = wraps(),
			}
		end,
		children = {
			create("UISizeConstraint")({
				Name = "GridSizeConstraint",
				MaxSize = maxSize,
			}),
			create("UIPadding")({
				Name = "GridMargin",
				PaddingLeft = function()
					return UDim.new(0, gridMetrics().margin)
				end,
				PaddingRight = function()
					return UDim.new(0, gridMetrics().margin)
				end,
			}),
			props.children,
		},
	})
	grid.Name = "Grid"

	local alignment = View({
		tag = function()
			return `col flex-x-fill size-full-0 auto-y {alignTags[Value.read(props.align)]}`
		end,
		children = {
			GridStyleSheet({
				breakpoint = breakpoint,
				containerWidth = function()
					return absoluteSize().X
				end,
			}),
			grid,
		},
	})
	alignment.Name = "GridAlignment"

	return View(withCommonProps(props, {
		tag = props.tag,
		children = { measure, alignment },
	}) :: any)
end

return Grid
