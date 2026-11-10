local foundation = require("../foundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local PopoverAlign = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/PopoverAlign")
local PopoverSide = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/PopoverSide")

type PopoverAlign = PopoverAlign.PopoverAlign
type PopoverSide = PopoverSide.PopoverSide

local SHORTCUT = { Enum.KeyCode.LeftControl, Enum.KeyCode.S }

local LONG_TEXT =
	"Generally we should avoid tooltips with long titles and bodies. Consider using other affordances for sharing contextual information when content expands beyond a few lines."

local SIDE_ORDER: { PopoverSide } = {
	PopoverSide.Top,
	PopoverSide.Right,
	PopoverSide.Bottom,
	PopoverSide.Left,
}

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
				tag = props.contentTag or "row gap-xxlarge align-y-center auto-xy wrap",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function LabeledTarget(props: {
	LayoutOrder: number,
	label: string,
	buttonText: string?,
	title: string,
	text: string?,
	shortcut: { Enum.KeyCode }?,
	hasArrow: boolean?,
	side: PopoverSide?,
	align: PopoverAlign?,
})
	return VF.View({
		tag = "col align-x-center gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-center content-muted",
				LayoutOrder = 1,
			}),
			VF.Tooltip({
				LayoutOrder = 2,
				title = props.title,
				text = props.text,
				shortcut = props.shortcut,
				hasArrow = props.hasArrow,
				side = props.side,
				align = props.align,
				children = VF.Button({
					text = props.buttonText or "Hover me",
					onActivated = noop,
				}),
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.View({
		tag = "col align-x-center align-y-center padding-xxlarge",
		Size = UDim2.new(1, 0, 0, 200),
		children = VF.Tooltip({
			title = controls.title,
			text = function(): string?
				local text = controls.text()
				return if text ~= "" then text else nil
			end,
			shortcut = function(): { Enum.KeyCode }?
				return if controls.hasShortcut() then SHORTCUT else nil
			end,
			hasArrow = controls.hasArrow,
			side = controls.side,
			align = controls.align,
			children = VF.Button({
				text = "Hover me",
				onActivated = noop,
			}),
		}),
	})
end

local function PlacementStory()
	local targets = {}
	for index, side in SIDE_ORDER do
		targets[index] = LabeledTarget({
			LayoutOrder = index,
			label = side,
			buttonText = side,
			title = "Tooltip",
			text = "Appears on the " .. side:lower() .. " side.",
			side = side,
		})
	end

	return VF.View({
		tag = "col align-x-center gap-xxlarge auto-y padding-y-xxlarge",
		Size = UDim2.fromScale(1, 0),
		children = VF.View({
			tag = "row align-x-center align-y-center gap-xxlarge auto-y",
			Size = UDim2.fromScale(1, 0),
			children = targets,
		}),
	})
end

local function ContentStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large",
		children = Section({
			LayoutOrder = 1,
			name = "Content",
			contentTag = "row gap-xxlarge align-y-center auto-xy wrap padding-y-xlarge",
			children = {
				LabeledTarget({
					LayoutOrder = 1,
					label = "Title only",
					buttonText = "Title",
					title = "Save changes",
					side = PopoverSide.Top,
				}),
				LabeledTarget({
					LayoutOrder = 2,
					label = "With description",
					buttonText = "Description",
					title = "Save changes",
					text = "Stores your latest edits to this project.",
					side = PopoverSide.Top,
				}),
				LabeledTarget({
					LayoutOrder = 3,
					label = "With shortcut",
					buttonText = "Shortcut",
					title = "Save",
					shortcut = SHORTCUT,
					side = PopoverSide.Top,
				}),
				LabeledTarget({
					LayoutOrder = 4,
					label = "Long description",
					buttonText = "Long",
					title = "Heads up",
					text = LONG_TEXT,
					side = PopoverSide.Top,
				}),
				LabeledTarget({
					LayoutOrder = 5,
					label = "Without arrow",
					buttonText = "No arrow",
					title = "Save changes",
					text = "Stores your latest edits to this project.",
					hasArrow = false,
					side = PopoverSide.Top,
				}),
			},
		}),
	})
end

return foundation.sections({
	summary = "Provides additional information about an element on hover. Descriptions should be no longer than three lines.",
	controls = {
		title = "Tooltip",
		text = "Tooltip body text",
		hasShortcut = false,
		hasArrow = true,
		side = UILabs.Choose(SIDE_ORDER),
		align = UILabs.Choose({ PopoverAlign.Center, PopoverAlign.Start, PopoverAlign.End }),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Placement",
			summary = "Use side and align to control where the tooltip appears relative to its anchor.",
			story = PlacementStory,
		},
		{ name = "Content", story = ContentStory },
	},
})
