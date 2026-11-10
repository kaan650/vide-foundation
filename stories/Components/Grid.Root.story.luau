local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local Types = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Types")
local getGridSizeTag = require("@game/ReplicatedStorage/Packages/VideFoundation/Utility/getGridSizeTag")

type ColorStyleValue = VideFoundation.ColorStyleValue
type ResponsiveValue<T> = Types.ResponsiveValue<T>

local Grid = VF.Grid.Root
local GridCell = VF.Grid.Cell
local GridDebug = VF.Grid.Debug

local WHITE = Color3.fromRGB(255, 255, 255)

--* Choose controls hold names, mapped to the ItemLineAlignment items Foundation's control lists.
local ALIGN_OPTIONS = { "Center", "Start", "End" }

local function Child(props: {
	name: string,
	tag: string,
	Size: UDim2?,
	LayoutOrder: number,
	debug: boolean,
})
	local tokens = VF.Hooks.useTokens()
	local function emphasis(): Color3
		return tokens().Color.ActionEmphasis.Background.Color3
	end

	return VF.View({
		tag = `auto-y clip {props.tag}`,
		Size = props.Size,
		backgroundStyle = function(): ColorStyleValue
			return { Transparency = 0.7, Color3 = emphasis() }
		end,
		BorderSizePixel = if not props.debug then 1 else nil,
		BorderColor3 = if not props.debug then emphasis else nil,
		LayoutOrder = props.LayoutOrder,
		children = VF.Text({
			tag = "position-center-center anchor-center-center size-full-2000 text-label-small text-wrap",
			Text = `{props.name} {props.tag:gsub("%-col%-", ":")}`,
		}),
	})
end

local function ChildCell(props: {
	name: string,
	size: ResponsiveValue<number>,
	LayoutOrder: number,
	debug: boolean,
})
	return GridCell({
		tag = "auto-y clip",
		size = props.size,
		backgroundStyle = { Transparency = 0.15 },
		BorderSizePixel = if not props.debug then 1 else nil,
		BorderColor3 = if not props.debug then WHITE else nil,
		LayoutOrder = props.LayoutOrder,
		children = VF.Text({
			tag = "position-center-center anchor-center-center size-full-2000 text-label-small text-wrap",
			Text = `{props.name} {getGridSizeTag(props.size):gsub("%-col%-", ":")}`,
		}),
	})
end

type Controls = { [string]: any }

local function align(controls: Controls): () -> Enum.ItemLineAlignment
	return function()
		return (Enum.ItemLineAlignment :: any)[controls.align()]
	end
end

local function grid(controls: Controls, children: any, layoutOrder: number?)
	return Grid({
		align = align(controls),
		Wraps = controls.wraps,
		LayoutOrder = layoutOrder,
		children = children,
	})
end

--* Grid.Debug styles the cells built inside it, so turning debug on or off builds the grid again.
local function withDebug(controls: Controls, build: (debug: boolean) -> any)
	return foundation.rebuildOn(controls.debug, function(debug: boolean)
		if debug then
			return GridDebug({
				align = align(controls),
				children = function()
					return build(debug)
				end,
			})
		end
		return build(debug)
	end)
end

type ChildSpec = { name: string, tag: string, LayoutOrder: number }

local function children(specs: { ChildSpec }, debug: boolean): { any }
	local list = {}
	for index, spec in specs do
		list[index] = Child({
			name = spec.name,
			tag = spec.tag,
			LayoutOrder = spec.LayoutOrder,
			debug = debug,
		})
	end
	return list
end

local PLAYGROUND_CHILDREN: { ChildSpec } = {
	{ name = "C1", tag = "xs-col-1 sm-col-4 md-col-6 lg-col-8 xl-col-8", LayoutOrder = 1 },
	{ name = "C2", tag = "xs-col-1 sm-col-4 md-col-6 lg-col-4 xl-col-4", LayoutOrder = 2 },
	{ name = "C3", tag = "xs-col-1 sm-col-5 md-col-7 lg-col-10 xl-col-10", LayoutOrder = 3 },
	{ name = "C4", tag = "xs-col-3 sm-col-1 md-col-5 lg-col-2 xl-col-2", LayoutOrder = 4 },
	{ name = "C5", tag = "xs-col-1 sm-col-4 md-col-1 lg-col-3 xl-col-3", LayoutOrder = 5 },
	{ name = "C6", tag = "xs-col-1 sm-col-3 md-col-11 lg-col-9 xl-col-9", LayoutOrder = 6 },
}

local CELL_CHILDREN: { { name: string, size: ResponsiveValue<number> } } = {
	{ name = "C1", size = { xs = 1, sm = 4, md = 8, lg = 8, xl = 8 } },
	{ name = "C2", size = { xs = 1, sm = 2, md = 4, lg = 4, xl = 4, xxl = 4 } },
	{ name = "C3", size = { xs = 1, sm = 5, md = 7, lg = 10, xl = 10 } },
	{ name = "C4", size = { xs = 3, sm = 1, md = 5, lg = 2, xl = 2 } },
	{ name = "C5", size = { xs = 1, sm = 4, md = 1, lg = 3, xl = 3 } },
	{ name = "C6", size = { xs = 1, sm = 3, md = 11, lg = 9, xl = 9 } },
}

local FLUID_CHILDREN: { ChildSpec } = {
	{ name = "C1", tag = "xs-col-3 sm-col-6 md-col-12 lg-col-12 xl-col-12", LayoutOrder = 1 },
	{ name = "C3", tag = "xs-col-1 sm-col-3 md-col-6 lg-col-6 xl-col-6", LayoutOrder = 3 },
	{ name = "C3", tag = "xs-col-1 sm-col-3 md-col-6 lg-col-6 xl-col-6", LayoutOrder = 3 },
	{ name = "C4", tag = "xs-col-1 sm-col-2 md-col-4 lg-col-4 xl-col-4", LayoutOrder = 4 },
	{ name = "C5", tag = "xs-col-1 sm-col-2 md-col-4 lg-col-4 xl-col-4", LayoutOrder = 5 },
	{ name = "C6", tag = "xs-col-1 sm-col-2 md-col-4 lg-col-4 xl-col-4", LayoutOrder = 6 },
	{ name = "C3", tag = "xs-col-0 sm-col-1 md-col-3 lg-col-3 xl-col-3", LayoutOrder = 7 },
	{ name = "C4", tag = "xs-col-0 sm-col-2 md-col-3 lg-col-3 xl-col-3", LayoutOrder = 8 },
	{ name = "C5", tag = "xs-col-0 sm-col-2 md-col-3 lg-col-3 xl-col-3", LayoutOrder = 9 },
	{ name = "C6", tag = "xs-col-0 sm-col-1 md-col-3 lg-col-3 xl-col-3", LayoutOrder = 10 },
	{ name = "C3", tag = "xs-col-0 sm-col-1 md-col-2 lg-col-2 xl-col-2", LayoutOrder = 11 },
	{ name = "C4", tag = "xs-col-0 sm-col-1 md-col-2 lg-col-2 xl-col-2", LayoutOrder = 12 },
	{ name = "C5", tag = "xs-col-0 sm-col-1 md-col-2 lg-col-2 xl-col-2", LayoutOrder = 13 },
	{ name = "C6", tag = "xs-col-0 sm-col-1 md-col-2 lg-col-2 xl-col-2", LayoutOrder = 14 },
	{ name = "C6", tag = "xs-col-0 sm-col-1 md-col-2 lg-col-2 xl-col-2", LayoutOrder = 15 },
	{ name = "C6", tag = "xs-col-0 sm-col-1 md-col-2 lg-col-2 xl-col-2", LayoutOrder = 16 },
}

local GRID_CELL_COUNT = 12

local function PlaygroundStory(controls: Controls)
	return withDebug(controls, function(debug)
		return grid(controls, children(PLAYGROUND_CHILDREN, debug))
	end)
end

local function BaseWithGridCellStory(controls: Controls)
	return withDebug(controls, function(debug)
		local cells = {}
		for index, spec in CELL_CHILDREN do
			cells[index] = ChildCell({
				name = spec.name,
				size = spec.size,
				debug = debug,
				LayoutOrder = index,
			})
		end
		return grid(controls, cells)
	end)
end

local function GridStory(controls: Controls)
	return withDebug(controls, function()
		local cells = {}
		for i = 1, GRID_CELL_COUNT do
			cells[i] = GridCell({
				size = { xs = 1, sm = 2, md = 3, lg = 4, xl = 6 },
				tag = "size-full-full aspect-2-1 margin-bottom-large",
				LayoutOrder = i,
				children = VF.View({
					tag = "size-full-full bg-action-emphasis",
					children = VF.Text({
						tag = "position-center-center anchor-center-center size-full-full text-label-small text-wrap",
						Text = `{i}`,
					}),
				}),
			})
		end
		return grid(controls, cells)
	end)
end

local function FluidStory(controls: Controls)
	return withDebug(controls, function(debug)
		return grid(controls, children(FLUID_CHILDREN, debug))
	end)
end

local function TemplateStory(controls: Controls)
	local function templateGrid(debug: boolean, specs: { ChildSpec }, height: number)
		local function build()
			local list = {}
			for index, spec in specs do
				list[index] = Child({
					name = spec.name,
					tag = spec.tag,
					Size = UDim2.fromOffset(0, height),
					LayoutOrder = spec.LayoutOrder,
					debug = debug,
				})
			end
			return grid(controls, list, 1)
		end
		return if debug then GridDebug({ align = align(controls), children = build }) else build()
	end

	--* Each grid sits in its own Grid.Debug while the control is on, as Foundation nests them. Siblings share
	--* LayoutOrder 1, so they are listed in the order React mounts Foundation's keyed children.
	return foundation.rebuildOn(controls.debug, function(debug: boolean)
		return VF.View({
			tag = "row size-full-3000 auto-y",
			children = {
				VF.View({
					tag = "col flex-y-fill items-stretch auto-y",
					Size = UDim2.fromScale(0.666, 1),
					children = templateGrid(debug, {
						{ name = "SC1", tag = "xs-col-1 sm-col-3 md-col-6 lg-col-4 xl-col-4", LayoutOrder = 1 },
						{ name = "SC1", tag = "xs-col-2 sm-col-3 md-col-6 lg-col-8 xl-col-8", LayoutOrder = 1 },
					}, 250),
				}),
				VF.View({
					tag = "col flex-y-fill auto-y",
					Size = UDim2.fromScale(0.333, 1),
					children = {
						templateGrid(debug, {
							{ name = "SC2", tag = "xs-col-3 sm-col-6 md-col-12 lg-col-12 xl-col-12", LayoutOrder = 1 },
						}, 125),
						templateGrid(debug, {
							{ name = "SC1", tag = "xs-col-3 sm-col-6 md-col-12 lg-col-12 xl-col-12", LayoutOrder = 1 },
						}, 125),
					},
				}),
			},
		})
	end)
end

return foundation.sections({
	summary = "Grid",
	controls = {
		align = UILabs.Choose(ALIGN_OPTIONS),
		wraps = true,
		debug = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Base w/ GridCell", story = BaseWithGridCellStory },
		{ name = "Grid", story = GridStory },
		{ name = "Fluid", story = FluidStory },
		{ name = "Template", story = TemplateStory },
	},
})
