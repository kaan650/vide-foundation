local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local FillBehavior = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/FillBehavior")
local OptionSelectorGroupSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/OptionSelectorGroupSize")
local Orientation = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/Orientation")

type FillBehavior = FillBehavior.FillBehavior
type OptionSelectorGroupSize = OptionSelectorGroupSize.OptionSelectorGroupSize
type Orientation = Orientation.Orientation
type Value<T> = VideFoundation.Value<T>

local SIZE_ORDER: { OptionSelectorGroupSize } = {
	OptionSelectorGroupSize.XSmall,
	OptionSelectorGroupSize.Small,
	OptionSelectorGroupSize.Medium,
}

local PLAYGROUND_SIZE_OPTIONS = {
	foundation.NONE,
	OptionSelectorGroupSize.XSmall,
	OptionSelectorGroupSize.Small,
	OptionSelectorGroupSize.Medium,
}

local PLAYGROUND_FILL_BEHAVIOR_OPTIONS = {
	foundation.NONE,
	FillBehavior.Fit,
	FillBehavior.Fill,
}

local ORIENTATION_ORDER: { Orientation } = {
	Orientation.Vertical,
	Orientation.Horizontal,
}

local ITEM_VALUES = { "Option A", "Option B", "Option C" }
-- Varied lengths so wrapping and taller items show up in the Orientation and Sizing stories.
local ITEM_DESCRIPTIONS = {
	"Description",
	"A little bit longer description",
}

local GROUP_COLUMN_WIDTH = 280

local function noop() end

local function Section(props: { LayoutOrder: number, name: string, contentTag: string?, children: any })
	return VF.View({
		tag = "col gap-medium size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.name,
				tag = "auto-xy text-label-medium content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = props.contentTag or "row gap-large auto-xy wrap",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function makeItems(props: { count: number?, withDescriptions: boolean? })
	local items = {}
	for index = 1, props.count or #ITEM_VALUES do
		local value = ITEM_VALUES[index]
		items[index] = VF.OptionSelectorGroup.Item({
			value = value,
			label = value,
			description = if props.withDescriptions then ITEM_DESCRIPTIONS[index] else nil,
			LayoutOrder = index,
		})
	end
	return items
end

type GroupExampleProps = {
	LayoutOrder: number?,
	orientation: Orientation?,
	value: Value<string?>?,
	onValueChanged: ((string?) -> ())?,
	size: Value<OptionSelectorGroupSize?>?,
	legend: Value<string?>?,
	itemCount: number?,
	fillBehavior: Value<FillBehavior?>?,
	containerWidth: number?,
	-- Draws a surface behind the bounded parent so Fill vs Fit sizing is easier to see.
	parentSurface: boolean?,
	withDescriptions: boolean?,
}

local function GroupExample(props: GroupExampleProps)
	local orientation: Orientation = props.orientation or Orientation.Vertical
	local needsBoundedWidth = orientation == Orientation.Vertical
		or props.fillBehavior == FillBehavior.Fill
		or props.containerWidth ~= nil

	local wrapperTag = if needsBoundedWidth then "size-full-0 auto-y" else "auto-xy"
	if props.parentSurface then
		wrapperTag = `{wrapperTag} bg-surface-100 radius-medium padding-large`
	end

	return VF.View({
		tag = wrapperTag,
		Size = if needsBoundedWidth then UDim2.fromOffset(props.containerWidth or GROUP_COLUMN_WIDTH, 0) else nil,
		LayoutOrder = props.LayoutOrder,
		children = VF.OptionSelectorGroup.Root({
			value = props.value,
			onValueChanged = props.onValueChanged or noop,
			orientation = orientation,
			size = props.size,
			fillBehavior = props.fillBehavior,
			legend = props.legend,
			Selectable = true,
			children = function()
				return makeItems({ count = props.itemCount, withDescriptions = props.withDescriptions })
			end,
		}),
	})
end

local function LabeledGroup(props: {
	label: string,
	LayoutOrder: number,
	orientation: Orientation?,
	size: OptionSelectorGroupSize?,
	legend: string?,
	itemCount: number?,
	fillBehavior: FillBehavior?,
	containerWidth: number?,
	parentSurface: boolean?,
	note: string?,
})
	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			if props.note ~= nil
				then VF.Text({
					Text = props.note,
					tag = "size-full-0 auto-y text-caption-small text-wrap text-align-x-left content-muted",
					Size = UDim2.fromOffset(props.containerWidth or GROUP_COLUMN_WIDTH, 0),
					LayoutOrder = 2,
				})
				else nil,
			GroupExample({
				LayoutOrder = 3,
				orientation = props.orientation,
				size = props.size,
				legend = props.legend,
				itemCount = props.itemCount,
				fillBehavior = props.fillBehavior,
				containerWidth = props.containerWidth,
				parentSurface = props.parentSurface,
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	--* The wrapper's width and surface follow the orientation, so a new orientation builds the example again.
	return foundation.rebuildOn(controls.orientation, function(orientation: Orientation)
		local isHorizontal = orientation == Orientation.Horizontal
		return GroupExample({
			orientation = orientation,
			size = foundation.orNil(controls.size),
			fillBehavior = foundation.orNil(controls.fillBehavior),
			legend = function(): string?
				local legend: string = controls.legend()
				return if #legend > 0 then legend else nil
			end,
			onValueChanged = noop,
			itemCount = 2,
			containerWidth = if isHorizontal then GROUP_COLUMN_WIDTH * 2 else nil,
			parentSurface = isHorizontal,
		})
	end)
end

local function SizingStory()
	local sizes = {}
	for index, size in SIZE_ORDER do
		sizes[index] = LabeledGroup({
			label = size,
			LayoutOrder = index,
			size = size,
			orientation = Orientation.Vertical,
			itemCount = 2,
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Size",
				contentTag = "row gap-large auto-xy wrap",
				children = sizes,
			}),
			Section({
				LayoutOrder = 2,
				name = "Fill behavior",
				contentTag = "col gap-large align-x-left size-full-0 auto-y",
				children = {
					LabeledGroup({
						label = "Fit",
						LayoutOrder = 1,
						orientation = Orientation.Horizontal,
						itemCount = 2,
						fillBehavior = FillBehavior.Fit,
						containerWidth = 560,
						parentSurface = true,
					}),
					LabeledGroup({
						label = "Fill",
						LayoutOrder = 2,
						orientation = Orientation.Horizontal,
						itemCount = 2,
						fillBehavior = FillBehavior.Fill,
						containerWidth = 560,
						parentSurface = true,
					}),
				},
			}),
		},
	})
end

local FILL_BEHAVIOR_ORDER: { { label: string, value: FillBehavior } } = {
	{ label = "Fit", value = FillBehavior.Fit },
	{ label = "Fill", value = FillBehavior.Fill },
}

local ORIENTATION_MATRIX_LABEL_WIDTH = 90
local ORIENTATION_MATRIX_CELL_WIDTH = 400

local function OrientationStory()
	local headerCells = {
		VF.View({
			Size = UDim2.fromOffset(ORIENTATION_MATRIX_LABEL_WIDTH, 0),
			LayoutOrder = 1,
		}),
	}
	for columnIndex, fill in FILL_BEHAVIOR_ORDER do
		table.insert(
			headerCells,
			VF.Text({
				Text = `fillBehavior = {fill.label}`,
				tag = "auto-xy text-caption-small text-align-x-left content-muted",
				Size = UDim2.fromOffset(ORIENTATION_MATRIX_CELL_WIDTH, 0),
				LayoutOrder = columnIndex + 1,
			})
		)
	end

	local rows = {}
	for rowIndex, orientation in ORIENTATION_ORDER do
		local cells = {
			VF.Text({
				Text = orientation,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				Size = UDim2.fromOffset(ORIENTATION_MATRIX_LABEL_WIDTH, 0),
				LayoutOrder = 1,
			}),
		}
		for columnIndex, fill in FILL_BEHAVIOR_ORDER do
			table.insert(
				cells,
				GroupExample({
					LayoutOrder = columnIndex + 1,
					orientation = orientation,
					onValueChanged = noop,
					itemCount = 2,
					fillBehavior = fill.value,
					containerWidth = ORIENTATION_MATRIX_CELL_WIDTH,
					parentSurface = true,
					withDescriptions = true,
				})
			)
		end
		rows[rowIndex] = VF.View({
			tag = "row gap-large auto-xy",
			LayoutOrder = rowIndex + 1,
			children = cells,
		})
	end

	return VF.View({
		tag = "col gap-large size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			VF.Text({
				Text = "A horizontal OptionSelectorGroup lays its items out in a single row and does not wrap: items that don't fit overflow the parent instead of moving to a new line.",
				tag = "size-full-0 auto-y text-caption-small text-wrap text-align-x-left content-muted",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "row align-y-center gap-large auto-xy",
				LayoutOrder = 2,
				children = headerCells,
			}),
			VF.View({
				tag = "col gap-large auto-xy",
				LayoutOrder = 3,
				children = rows,
			}),
			LabeledGroup({
				label = "No wrap (horizontal)",
				LayoutOrder = 4,
				orientation = Orientation.Horizontal,
				itemCount = 3,
				fillBehavior = FillBehavior.Fit,
				containerWidth = 240,
				parentSurface = true,
				note = "The parent (gray) is too narrow for all three items, so the row overflows to the right instead of wrapping onto a new line.",
			}),
		},
	})
end

local function ContentStory()
	local legends = {}
	for index, size in SIZE_ORDER do
		legends[index] = LabeledGroup({
			label = size,
			LayoutOrder = index,
			size = size,
			legend = "Legend",
			orientation = Orientation.Vertical,
			itemCount = 2,
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "Legend",
			contentTag = "row gap-large auto-xy wrap",
			children = legends,
		}),
	})
end

local function ControlledExample()
	local value = Vide.source(nil :: string?)
	local getValue: () -> string? = value :: any

	return VF.View({
		tag = "col gap-medium auto-xy",
		children = {
			GroupExample({
				LayoutOrder = 1,
				value = getValue,
				onValueChanged = function(newValue: string?)
					value(newValue)
				end,
				itemCount = 3,
			}),
			VF.Text({
				Text = function()
					return `Selected: {getValue() or "none"}`
				end,
				tag = "auto-xy text-body-medium text-align-x-left content-emphasis",
				LayoutOrder = 2,
			}),
		},
	})
end

local function ControlledStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "Selection updates value",
			contentTag = "auto-xy",
			children = ControlledExample(),
		}),
	})
end

return foundation.sections({
	summary = "A single-choice list of options laid out vertically or horizontally. Selecting an option deselects the previous one; selecting the same option again clears the selection.",
	controls = {
		orientation = UILabs.Choose(ORIENTATION_ORDER),
		size = UILabs.Choose(PLAYGROUND_SIZE_OPTIONS),
		fillBehavior = UILabs.Choose(PLAYGROUND_FILL_BEHAVIOR_OPTIONS),
		legend = "",
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Sizing",
			story = function()
				return foundation.scroll(SizingStory())
			end,
		},
		{
			name = "Orientation",
			story = function()
				return foundation.scroll(OrientationStory())
			end,
		},
		{ name = "Controlled component", story = ControlledStory },
		{ name = "Content", story = ContentStory },
	},
})
