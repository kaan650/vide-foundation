local DialogStoryHelpers = require("../Shared/DialogStoryHelpers")
local foundation = require("../foundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local DialogSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/DialogSize")

type DialogSize = DialogSize.DialogSize

local LabeledDialogTrigger = DialogStoryHelpers.LabeledDialogTrigger
local Section = DialogStoryHelpers.Section
local makeDialogChildren = DialogStoryHelpers.makeDialogChildren

local SIZE_ORDER: { DialogSize } = DialogStoryHelpers.SIZE_ORDER
local LONG_CONTENT = table.concat({
	"This is a longer block of dialog body copy meant to exceed the available content height and trigger vertical scrolling.",
	"Use enough paragraphs that the scroll view shows a scrollbar and applies right padding for the thumb.",
	"Each paragraph adds more line wraps so the behavior is easy to see at Medium and Small sizes.",
	"Scrolling keeps the title and actions fixed while only the body moves inside the scroll view.",
	"Long copy is common for terms, release notes, or detailed confirmations that need full context.",
	"Keep titles short in these examples so overflow is clearly coming from the body text.",
	"The scrollbar appears automatically when canvas height exceeds the scroll window.",
	"Right padding adjusts when a scrollbar is visible so text does not sit under the thumb.",
}, "\n\n")
local RICH_TEXT_CONTENT = table.concat({
	"Please review the following before continuing:",
	"<b>Important:</b> This action cannot be undone once you confirm.",
	"Terms apply to <b>all linked accounts</b>. Contact support if you have <i>questions</i> about your subscription.",
}, "\n\n")

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
		children = makeDialogChildren({
			content = controls.text,
		}),
	})
end

local function SizingStory()
	local triggers = {}
	for index, size in SIZE_ORDER do
		triggers[index] = LabeledDialogTrigger({
			label = size,
			layoutOrder = index,
			size = size,
			children = makeDialogChildren({}),
		})
	end

	return Page(Section({
		layoutOrder = 1,
		name = "Size",
		children = triggers,
	}))
end

local function ContentStory()
	return Page({
		Section({
			layoutOrder = 1,
			name = "Long text",
			children = LabeledDialogTrigger({
				layoutOrder = 1,
				children = makeDialogChildren({
					content = LONG_CONTENT,
				}),
			}),
		}),
		Section({
			layoutOrder = 2,
			name = "Rich text",
			note = "Dialog.Text always renders with RichText enabled, so markup in the Text prop is supported.",
			children = LabeledDialogTrigger({
				layoutOrder = 1,
				children = makeDialogChildren({
					content = RICH_TEXT_CONTENT,
				}),
			}),
		}),
	})
end

return foundation.sections({
	summary = "Renders dialog body copy inside Content. Typography follows the root size via DialogProvider.",
	controls = {
		text = "Dialog.Text content goes here.",
		rootSize = UILabs.Choose(foundation.Dash.values(DialogSize :: any)),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizing", story = SizingStory },
		{ name = "Content", story = ContentStory },
	},
})
