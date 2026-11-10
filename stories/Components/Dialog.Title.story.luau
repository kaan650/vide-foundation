local DialogStoryHelpers = require("../Shared/DialogStoryHelpers")
local foundation = require("../foundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local DialogSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/DialogSize")

type DialogSize = DialogSize.DialogSize

local LabeledDialogTrigger = DialogStoryHelpers.LabeledDialogTrigger
local Section = DialogStoryHelpers.Section
local makeDialogChildren = DialogStoryHelpers.makeDialogChildren
local minimalDialogChildren = DialogStoryHelpers.minimalDialogChildren

local SIZE_ORDER: { DialogSize } = DialogStoryHelpers.SIZE_ORDER
local LONG_TITLE =
	"This is a dialog title that spans multiple lines and should wrap within the dialog header while leaving room for the close affordance."

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
		children = minimalDialogChildren(controls.text),
	})
end

local function SizingStory()
	local triggers = {}
	for index, size in SIZE_ORDER do
		triggers[index] = LabeledDialogTrigger({
			label = size,
			layoutOrder = index,
			size = size,
			children = minimalDialogChildren("Dialog title"),
		})
	end

	return Page(Section({
		layoutOrder = 1,
		name = "Size",
		children = triggers,
	}))
end

local function ContentStory()
	local triggers = {}
	for index, size in SIZE_ORDER do
		triggers[index] = LabeledDialogTrigger({
			label = size,
			layoutOrder = index,
			size = size,
			children = makeDialogChildren({
				title = LONG_TITLE,
				content = "Body text stays short so wrapping is visible on the title.",
			}),
		})
	end

	return Page(Section({
		layoutOrder = 1,
		name = "Long title",
		children = triggers,
	}))
end

return foundation.sections({
	summary = "Renders the dialog heading. Typography and padding follow the root size via DialogProvider.",
	controls = {
		text = "Dialog title",
		rootSize = UILabs.Choose(foundation.Dash.values(DialogSize :: any)),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizing", story = SizingStory },
		{ name = "Content", story = ContentStory },
	},
})
