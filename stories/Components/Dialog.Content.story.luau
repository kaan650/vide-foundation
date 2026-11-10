local DialogStoryHelpers = require("../Shared/DialogStoryHelpers")
local foundation = require("../foundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local DialogSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/DialogSize")

type DialogSize = DialogSize.DialogSize

local LabeledDialogTrigger = DialogStoryHelpers.LabeledDialogTrigger
local Section = DialogStoryHelpers.Section
local listDialogChildren = DialogStoryHelpers.listDialogChildren
local makeDialogChildren = DialogStoryHelpers.makeDialogChildren

local SIZE_ORDER: { DialogSize } = DialogStoryHelpers.SIZE_ORDER

local function contentBoundsChildren()
	return makeDialogChildren({
		contentChildren = function()
			return VF.View({
				tag = "col size-full-1200 padding-medium bg-shift-400",
				LayoutOrder = 1,
				children = VF.Text({
					Text = "Dialog.Content — scrollable body region.",
					tag = "size-full-0 auto-y text-body-medium content-default",
					LayoutOrder = 1,
				}),
			})
		end,
	})
end

local function Page(children: any)
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = children,
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return DialogStoryHelpers.RootStory({
		size = controls.rootSize,
		hasBackdrop = true,
		children = contentBoundsChildren(),
	})
end

local function SizingStory()
	local triggers = {}
	for index, size in SIZE_ORDER do
		triggers[index] = LabeledDialogTrigger({
			label = size,
			layoutOrder = index,
			size = size,
			children = contentBoundsChildren(),
		})
	end

	return Page(Section({
		layoutOrder = 1,
		name = "Size",
		children = triggers,
	}))
end

local function OverflowStory()
	return Page({
		Section({
			layoutOrder = 1,
			name = "Scroll",
			note = "Content scrolls when it exceeds the available body height. A scrollbar and right padding appear automatically.",
			children = LabeledDialogTrigger({
				label = "Long list",
				layoutOrder = 1,
				children = listDialogChildren(12),
			}),
		}),
		Section({
			layoutOrder = 2,
			name = "Selectable",
			note = "When content overflows, the scroll view becomes selectable for gamepad navigation unless Selectable is false.",
			children = {
				LabeledDialogTrigger({
					label = "Default",
					layoutOrder = 1,
					children = listDialogChildren(12),
				}),
				LabeledDialogTrigger({
					label = "Selectable = false",
					layoutOrder = 2,
					children = listDialogChildren(12, false),
				}),
			},
		}),
	})
end

return foundation.sections({
	summary = "Scrollable body region for dialog copy. Typography follows root size via DialogProvider. Scrollbar, padding, and selectability activate when content overflows.",
	controls = {
		rootSize = UILabs.Choose(foundation.Dash.values(DialogSize :: any)),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizing", story = SizingStory },
		{ name = "Content", story = OverflowStory },
	},
})
