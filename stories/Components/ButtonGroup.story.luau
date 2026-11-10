local foundation = require("../foundation")
local MatrixGrid = require("../Shared/MatrixGrid")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local FillBehavior = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/FillBehavior")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local Orientation = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/Orientation")

local matrixLabel = MatrixGrid.matrixLabel

type FillBehavior = FillBehavior.FillBehavior
type ButtonGroupSize = VideFoundation.ButtonGroupSize
type Orientation = Orientation.Orientation
type ButtonGroupItem = VideFoundation.ButtonGroupItem

local SIZE_ORDER: { ButtonGroupSize } = {
	InputSize.XSmall,
	InputSize.Small,
	InputSize.Medium,
}

local LABEL_COLUMN_WIDTH = 90
local LAYOUT_COLUMN_WIDTH = 280
local MODAL_WIDTH = 360
local OVERFLOW_HUG_WIDTH = 720
local OVERFLOW_FILL_WIDTH = 400

local DEFAULT_BUTTONS: { ButtonGroupItem } = {
	{
		text = "Cancel",
		variant = ButtonVariant.Standard,
		onActivated = function() end,
	},
	{
		text = "Continue",
		variant = ButtonVariant.SoftEmphasis,
		onActivated = function() end,
	},
	{
		text = "Accept",
		variant = ButtonVariant.Emphasis,
		onActivated = function() end,
	},
}

local LONG_LABEL_BUTTONS: { ButtonGroupItem } = {
	{
		text = "Discard all changes and go back",
		variant = ButtonVariant.Standard,
		onActivated = function() end,
	},
	{
		text = "Save progress and close application",
		variant = ButtonVariant.SoftEmphasis,
		onActivated = function() end,
	},
	{
		text = "Confirm and continue to the next step",
		variant = ButtonVariant.Emphasis,
		onActivated = function() end,
	},
}

local BUTTON_COUNTS = { 2, 3 }

local ORIENTATION_ORDER: { Orientation } = {
	Orientation.Horizontal,
	Orientation.Vertical,
}

type FillBehaviorColumn = {
	label: string,
	fillBehavior: FillBehavior?,
}

local FILL_BEHAVIOR_COLUMNS: { FillBehaviorColumn } = {
	{
		label = "Hug",
		fillBehavior = nil,
	},
	{
		label = "Fill",
		fillBehavior = FillBehavior.Fill,
	},
}

local function makeButtons(count: number): { ButtonGroupItem }
	local buttons: { ButtonGroupItem } = {}
	for index = 1, count do
		buttons[index] = DEFAULT_BUTTONS[index]
	end
	return buttons
end

local function needsBoundedContainer(orientation: Orientation, fillBehavior: FillBehavior?): boolean
	return orientation == Orientation.Vertical or fillBehavior == FillBehavior.Fill
end

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
				tag = props.contentTag or "col gap-large size-full-0 auto-y",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function GroupContainer(props: {
	LayoutOrder: number?,
	orientation: Orientation,
	fillBehavior: FillBehavior?,
	size: ButtonGroupSize,
	buttonCount: number,
	containerWidth: number?,
})
	local bounded = needsBoundedContainer(props.orientation, props.fillBehavior)
	local width = props.containerWidth or LAYOUT_COLUMN_WIDTH

	return VF.View({
		tag = if bounded then "size-full-0 auto-y" else "auto-xy",
		Size = if bounded then UDim2.fromOffset(width, 0) else nil,
		LayoutOrder = props.LayoutOrder,
		children = VF.ButtonGroup({
			orientation = props.orientation,
			fillBehavior = props.fillBehavior,
			size = props.size,
			buttons = makeButtons(props.buttonCount),
		}),
	})
end

local function LabeledGroup(props: {
	label: string,
	LayoutOrder: number,
	size: ButtonGroupSize?,
	orientation: Orientation?,
	fillBehavior: FillBehavior?,
	buttonCount: number?,
})
	return VF.View({
		tag = "col gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			GroupContainer({
				LayoutOrder = 2,
				orientation = props.orientation or Orientation.Horizontal,
				fillBehavior = props.fillBehavior,
				size = props.size or InputSize.Medium,
				buttonCount = props.buttonCount or 2,
			}),
		},
	})
end

local function MatrixCell(props: {
	LayoutOrder: number,
	orientation: Orientation,
	fillBehavior: FillBehavior?,
	buttonCount: number,
})
	return VF.View({
		tag = "col align-x-left auto-xy",
		Size = UDim2.fromOffset(LAYOUT_COLUMN_WIDTH, 0),
		LayoutOrder = props.LayoutOrder,
		children = GroupContainer({
			orientation = props.orientation,
			fillBehavior = props.fillBehavior,
			size = InputSize.Medium,
			buttonCount = props.buttonCount,
		}),
	})
end

local function OverflowExampleCell(props: { LayoutOrder: number, column: FillBehaviorColumn })
	local isFill = props.column.fillBehavior == FillBehavior.Fill
	local containerWidth = if isFill then OVERFLOW_FILL_WIDTH else OVERFLOW_HUG_WIDTH

	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		Size = UDim2.fromOffset(containerWidth, 0),
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = if isFill then "fillBehavior = Fill" else "fillBehavior = nil",
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.Text({
				Text = if isFill then "Text truncates" else "Buttons wrap",
				tag = "auto-xy text-caption-small text-align-x-left content-muted",
				LayoutOrder = 2,
			}),
			VF.View({
				tag = if isFill
					then "size-full-0 auto-y padding-large radius-medium bg-surface-100"
					else "col align-x-left auto-y padding-large radius-medium bg-surface-100",
				Size = UDim2.fromOffset(containerWidth, 0),
				LayoutOrder = 3,
				children = VF.ButtonGroup({
					orientation = Orientation.Horizontal,
					fillBehavior = props.column.fillBehavior,
					size = InputSize.Medium,
					buttons = LONG_LABEL_BUTTONS,
				}),
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local fillBehavior = foundation.orNil(controls.fillBehavior)
	local function bounded(): boolean
		return needsBoundedContainer(controls.orientation(), fillBehavior())
	end

	return VF.View({
		tag = "col gap-large size-full-0 auto-y",
		--* The unbounded container leaves Size unset (the engine's 100x100), which a Size binding cannot do.
		children = foundation.rebuildOn(bounded, function(isBounded: boolean)
			return VF.View({
				tag = if isBounded then "size-full-0 auto-y" else "auto-xy",
				Size = if isBounded then UDim2.fromOffset(MODAL_WIDTH, 0) else nil,
				children = VF.ButtonGroup({
					orientation = controls.orientation,
					fillBehavior = fillBehavior,
					size = controls.size,
					buttons = function()
						return makeButtons(controls.buttonCount())
					end,
				}),
			})
		end),
	})
end

local function ContentStory()
	local columnHeaders = {}
	for index, buttonCount in BUTTON_COUNTS do
		columnHeaders[index] = `{buttonCount} buttons`
	end

	local rows: { MatrixGrid.MatrixGridRow } = {}
	for index, orientation in ORIENTATION_ORDER do
		local cells = {}
		for cellIndex, buttonCount in BUTTON_COUNTS do
			cells[cellIndex] = MatrixCell({
				LayoutOrder = 1,
				orientation = orientation,
				buttonCount = buttonCount,
			})
		end
		rows[index] = { label = matrixLabel(orientation), cells = cells }
	end

	local overflowExamples = {}
	for index, column in FILL_BEHAVIOR_COLUMNS do
		overflowExamples[index] = OverflowExampleCell({ LayoutOrder = index, column = column })
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Buttons",
				contentTag = "auto-xy",
				children = MatrixGrid.MatrixGrid({
					labelColumnWidth = LABEL_COLUMN_WIDTH,
					columnHeaders = columnHeaders,
					cellColumnWidth = LAYOUT_COLUMN_WIDTH,
					headerTextAlign = "left",
					cellAlign = "left",
					rows = rows,
				}),
			}),
			Section({
				LayoutOrder = 2,
				name = "Overflow",
				contentTag = "col gap-large align-x-left auto-xy",
				children = VF.View({
					tag = "col align-x-left gap-xlarge auto-xy",
					LayoutOrder = 1,
					children = overflowExamples,
				}),
			}),
		},
	})
end

local function SizingStory()
	local sizes = {}
	for index, size in SIZE_ORDER do
		sizes[index] = LabeledGroup({
			label = size,
			LayoutOrder = index,
			size = size,
			orientation = Orientation.Horizontal,
			buttonCount = 2,
		})
	end

	local fillColumns = {}
	for index, column in FILL_BEHAVIOR_COLUMNS do
		fillColumns[index] = VF.View({
			tag = "col align-x-left gap-small auto-xy",
			LayoutOrder = index,
			children = {
				VF.Text({
					Text = column.label,
					tag = "auto-xy text-caption-small text-align-x-left content-muted",
					LayoutOrder = 1,
				}),
				MatrixCell({
					LayoutOrder = 2,
					orientation = Orientation.Horizontal,
					fillBehavior = column.fillBehavior,
					buttonCount = 2,
				}),
			},
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
				contentTag = "row gap-xxlarge auto-xy",
				children = fillColumns,
			}),
		},
	})
end

local function OrientationStory()
	local groups = {}
	for index, orientation in ORIENTATION_ORDER do
		groups[index] = LabeledGroup({
			label = orientation,
			LayoutOrder = index,
			orientation = orientation,
			size = InputSize.Medium,
			buttonCount = 2,
		})
	end
	return VF.View({
		tag = "row wrap gap-large auto-xy padding-y-large bg-surface-0",
		children = groups,
	})
end

return foundation.sections({
	summary = "A wrapper for multiple, related buttons.",
	controls = {
		orientation = UILabs.Choose({ Orientation.Horizontal, Orientation.Vertical }),
		fillBehavior = UILabs.Choose({ foundation.NONE, FillBehavior.Fit, FillBehavior.Fill }),
		size = UILabs.Choose({ InputSize.Medium, InputSize.Small, InputSize.XSmall }),
		buttonCount = UILabs.Choose(BUTTON_COUNTS),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Sizing",
			summary = "fillBehavior only applies to horizontal orientation. Vertical buttons always stretch to full width.",
			story = SizingStory,
		},
		{ name = "Orientation", story = OrientationStory },
		{
			name = "Content",
			story = function()
				return foundation.scroll(ContentStory())
			end,
		},
	},
})
