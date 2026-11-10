local foundation = require("../foundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")

type InputSize = InputSize.InputSize

local DEFAULT_TEXT = "Lorem ipsum"
local LONG_TEXT =
	"This is a very long chip label that should truncate with an ellipsis when it exceeds the available width"
local TRUNCATION_CONTAINER_WIDTH = 120

local SIZE_ORDER: { InputSize } = {
	InputSize.XSmall,
	InputSize.Small,
	InputSize.Medium,
	InputSize.Large,
}

local PLAYGROUND_SIZE_OPTIONS: { InputSize } = {
	InputSize.Medium,
	InputSize.XSmall,
	InputSize.Small,
	InputSize.Large,
}

local INITIAL_CHIPS = { "Design", "Engineering", "Product" }

local IN_CONTEXT_NOTE =
	"Unlike Chip, InputChip represents selections inside active text inputs — not as a standalone control — and is not yet integrated into TextInput or other consumers."

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

local function Page(children: any)
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = children,
	})
end

local function LabeledInputChip(props: { label: string, LayoutOrder: number, text: string, size: InputSize? })
	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "auto-xy",
				LayoutOrder = 2,
				children = VF.InputChip({
					text = props.text,
					size = props.size,
					onClose = noop,
				}),
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.View({
		tag = "row align-x-left size-full-2000 padding-large bg-surface-0",
		children = VF.InputChip({
			text = controls.text,
			size = controls.size,
			isDisabled = controls.isDisabled,
			onClose = noop,
		}),
	})
end

local function SizingStory()
	local chips = {}
	for index, size in SIZE_ORDER do
		chips[index] = LabeledInputChip({
			label = size,
			LayoutOrder = index,
			text = DEFAULT_TEXT,
			size = size,
		})
	end

	return Page(Section({
		LayoutOrder = 1,
		name = "Size",
		contentTag = "row gap-xlarge auto-xy wrap",
		children = chips,
	}))
end

local function StatesStory()
	return Page(Section({
		LayoutOrder = 1,
		name = "Disabled",
		contentTag = "auto-xy",
		children = VF.InputChip({
			text = DEFAULT_TEXT,
			isDisabled = true,
			onClose = noop,
		}),
	}))
end

local function ControlledDismissExample()
	local chips = Vide.source(table.clone(INITIAL_CHIPS))

	return VF.View({
		tag = "col align-x-left gap-medium auto-xy",
		children = {
			VF.View({
				tag = "row wrap gap-small auto-xy",
				LayoutOrder = 1,
				children = Vide.values(chips, function(chipText: string, index: () -> number)
					return VF.InputChip({
						text = chipText,
						onClose = function()
							local remaining = {}
							for _, existingChip in chips() do
								if existingChip ~= chipText then
									table.insert(remaining, existingChip)
								end
							end
							chips(remaining)
						end,
						LayoutOrder = index,
					})
				end),
			}),
			Vide.show(function()
				return #chips() < #INITIAL_CHIPS
			end, function()
				return VF.Button({
					text = "Restore InputChips",
					onActivated = function()
						chips(table.clone(INITIAL_CHIPS))
					end,
					LayoutOrder = 2,
				})
			end),
		},
	})
end

local function ControlledStory()
	return Page(Section({
		LayoutOrder = 1,
		name = "Dismiss",
		contentTag = "auto-xy",
		children = ControlledDismissExample(),
	}))
end

local function TruncatedInputChip(props: { LayoutOrder: number, size: InputSize })
	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.size,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "size-full-0 auto-y padding-small radius-medium bg-surface-100",
				sizeConstraint = {
					MaxSize = Vector2.new(TRUNCATION_CONTAINER_WIDTH, math.huge),
				},
				LayoutOrder = 2,
				children = VF.InputChip({
					text = LONG_TEXT,
					size = props.size,
					onClose = noop,
				}),
			}),
		},
	})
end

local function ContentStory()
	local chips = {}
	for index, size in SIZE_ORDER do
		chips[index] = TruncatedInputChip({
			LayoutOrder = index,
			size = size,
		})
	end

	return Page(Section({
		LayoutOrder = 1,
		name = "Truncation",
		contentTag = "row gap-xlarge auto-xy wrap",
		children = chips,
	}))
end

return foundation.sections({
	summary = "InputChip is a compact, dismissible label used to represent selections inside inputs.",
	controls = {
		text = DEFAULT_TEXT,
		size = UILabs.Choose(PLAYGROUND_SIZE_OPTIONS),
		isDisabled = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizing", story = SizingStory },
		{ name = "States", story = StatesStory },
		{ name = "Controlled component", story = ControlledStory },
		{ name = "Content", story = ContentStory },
		{
			name = "In context",
			summary = IN_CONTEXT_NOTE,
			story = function()
				return nil
			end,
		},
	},
})
