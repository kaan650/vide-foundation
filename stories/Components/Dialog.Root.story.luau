local DialogStoryHelpers = require("../Shared/DialogStoryHelpers")
local MatrixGrid = require("../Shared/MatrixGrid")
local foundation = require("../foundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local DialogActions = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Dialog/Actions")
local DialogSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/DialogSize")
local OnCloseCallbackReason = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/OnCloseCallbackReason")

type DialogAction = DialogActions.DialogAction
type DialogSize = DialogSize.DialogSize
type OnCloseCallbackReason = OnCloseCallbackReason.OnCloseCallbackReason

local DialogExample = DialogStoryHelpers.DialogExample
local LabeledDialogTrigger = DialogStoryHelpers.LabeledDialogTrigger
local Section = DialogStoryHelpers.Section
local dialogStoryList = DialogStoryHelpers.dialogStoryList
local heroMediaDialogChildren = DialogStoryHelpers.heroMediaDialogChildren
local listDialogChildren = DialogStoryHelpers.listDialogChildren
local makeDialogChildren = DialogStoryHelpers.makeDialogChildren
local minimalDialogChildren = DialogStoryHelpers.minimalDialogChildren

local SIZE_ORDER: { DialogSize } = DialogStoryHelpers.SIZE_ORDER
local DEFAULT_SIZE: DialogSize = DialogStoryHelpers.DEFAULT_SIZE
local FULL_COMPOSITION_MATRIX_LABEL_WIDTH = 180
local ACTIONS_MATRIX_CELL_WIDTH = 160
local FULL_COMPOSITION_ACTIONS_LABEL = "Actions label copy can wrap across multiple lines."
local FULL_COMPOSITION_CONTENT = "Text string example — body copy passed to Dialog.Text."
local FULL_COMPOSITION_RICH_CONTENT = table.concat({
	"Text string example — body copy passed to Dialog.Text.",
	"This dialog shows a longer description that spans multiple lines, similar to welcome or confirmation copy in production flows.",
	"<b>Important:</b> Review the details below before confirming. Contact support if you have <i>questions</i> about your account.",
}, "\n\n")

local function fullDialogChildren()
	return makeDialogChildren({
		hasHeroMedia = true,
		hasActions = true,
		actionsLabel = FULL_COMPOSITION_ACTIONS_LABEL,
		contentChildren = function()
			return {
				VF.Dialog.Text({
					Text = FULL_COMPOSITION_CONTENT,
					LayoutOrder = 1,
				}),
				dialogStoryList(3, 2),
			}
		end,
	})
end

local function formatCloseReason(reason: OnCloseCallbackReason?): string
	if reason == OnCloseCallbackReason.BackdropClick then
		return "Backdrop click"
	end

	return "Close affordance"
end

local function ControlledExample(props: {
	label: string,
	layoutOrder: number,
	hasOnClose: boolean,
})
	local isOpen = Vide.source(false)
	local closeReason = Vide.source("")

	local function dismiss(reason: string)
		closeReason(reason)
		isOpen(false)
	end

	return VF.View({
		tag = "col gap-small auto-xy",
		LayoutOrder = props.layoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "auto-xy",
				LayoutOrder = 2,
				children = VF.Button({
					text = function()
						return if isOpen() then "Close" else "Open"
					end,
					onActivated = function()
						if isOpen() then
							dismiss("Close")
						else
							closeReason("")
							isOpen(true)
						end
					end,
					variant = function()
						return if isOpen() then ButtonVariant.Standard else ButtonVariant.Emphasis
					end,
				}),
			}),
			VF.Text({
				Text = function()
					if closeReason() ~= "" then
						return `Closed via: {closeReason()}`
					end
					return if props.hasOnClose
						then "Open the dialog, then dismiss with the close affordance or a backdrop click."
						else "Open the dialog, then dismiss with Cancel or Confirm."
				end,
				tag = "size-full-0 auto-y text-body-small text-wrap text-align-x-left content-default",
				LayoutOrder = 3,
			}),
			Vide.show(isOpen, function()
				return DialogExample({
					size = DEFAULT_SIZE,
					hasBackdrop = props.hasOnClose,
					onClose = if props.hasOnClose
						then function(reason: OnCloseCallbackReason?)
							dismiss(formatCloseReason(reason))
						end
						else nil,
					children = if props.hasOnClose
						then minimalDialogChildren()
						else makeDialogChildren({
							hasActions = true,
							actions = {
								{
									text = "Cancel",
									variant = ButtonVariant.Standard,
									onActivated = function()
										dismiss("Cancel")
									end,
								},
								{
									text = "Confirm",
									variant = ButtonVariant.Emphasis,
									onActivated = function()
										dismiss("Confirm")
									end,
								},
							} :: { DialogAction },
						}),
				})
			end),
		},
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
		size = controls.size,
		hasBackdrop = controls.hasBackdrop,
		disablePortal = controls.disablePortal,
	})
end

local function SizingStory()
	local triggers = {}
	for index, size in SIZE_ORDER do
		triggers[index] = LabeledDialogTrigger({
			label = size,
			layoutOrder = index,
			size = size,
			children = minimalDialogChildren(),
		})
	end

	return Page(Section({
		layoutOrder = 1,
		name = "Size",
		children = triggers,
	}))
end

local function ControlledStory()
	return Page(Section({
		layoutOrder = 1,
		name = "Dismiss paths",
		children = {
			ControlledExample({
				label = "onClose",
				layoutOrder = 1,
				hasOnClose = true,
			}),
			ControlledExample({
				label = "Actions dismiss",
				layoutOrder = 2,
				hasOnClose = false,
			}),
		},
	}))
end

local function ContentStory()
	local function trigger(size: DialogSize, children: DialogStoryHelpers.DialogChildren)
		return LabeledDialogTrigger({
			layoutOrder = 1,
			size = size,
			children = children,
		})
	end

	local sizeHeaders: { string } = {}
	local withListCells = {}
	local withoutScrollingCells = {}
	for index, size in SIZE_ORDER do
		sizeHeaders[index] = size
		withListCells[index] = trigger(size, fullDialogChildren())
		withoutScrollingCells[index] = trigger(
			size,
			makeDialogChildren({
				hasHeroMedia = true,
				content = FULL_COMPOSITION_RICH_CONTENT,
				hasActions = true,
				actionsLabel = FULL_COMPOSITION_ACTIONS_LABEL,
			})
		)
	end

	return Page({
		Section({
			layoutOrder = 1,
			name = "Subparts",
			children = {
				LabeledDialogTrigger({
					label = "Title and text",
					layoutOrder = 1,
					children = minimalDialogChildren(),
				}),
				LabeledDialogTrigger({
					label = "Text",
					layoutOrder = 2,
					children = makeDialogChildren({ hasTitle = false }),
				}),
				LabeledDialogTrigger({
					label = "Actions",
					layoutOrder = 3,
					children = makeDialogChildren({ hasActions = true }),
				}),
				LabeledDialogTrigger({
					label = "Actions label",
					layoutOrder = 4,
					children = makeDialogChildren({
						hasActions = true,
						actionsLabel = FULL_COMPOSITION_ACTIONS_LABEL,
					}),
				}),
				LabeledDialogTrigger({
					label = "HeroMedia",
					layoutOrder = 5,
					children = heroMediaDialogChildren(),
				}),
				LabeledDialogTrigger({
					label = "Content",
					layoutOrder = 6,
					children = listDialogChildren(6),
				}),
			},
		}),
		Section({
			layoutOrder = 2,
			name = "Full composition",
			note = "Hero media, title, Dialog.Text, actions, and actions label composed at every size.",
			contentTag = "auto-xy",
			children = MatrixGrid.MatrixGrid({
				labelColumnWidth = FULL_COMPOSITION_MATRIX_LABEL_WIDTH,
				columnHeaders = sizeHeaders,
				cellColumnWidth = ACTIONS_MATRIX_CELL_WIDTH,
				headerTextAlign = "left",
				cellAlign = "left",
				rowGap = "xxlarge",
				rows = {
					{
						label = MatrixGrid.matrixInfoLabel(
							"With list",
							"Dialog.Text plus list content. List may scroll when it overflows."
						),
						cells = withListCells,
					},
					{
						label = MatrixGrid.matrixInfoLabel(
							"Without scrolling",
							"Dialog.Text only — no list content."
						),
						cells = withoutScrollingCells,
					},
				},
			}),
		}),
		Section({
			layoutOrder = 3,
			name = "Backdrop",
			children = {
				LabeledDialogTrigger({
					label = "hasBackdrop = true",
					layoutOrder = 1,
					hasBackdrop = true,
					children = minimalDialogChildren(),
				}),
				LabeledDialogTrigger({
					label = "hasBackdrop = false",
					layoutOrder = 2,
					hasBackdrop = false,
					children = minimalDialogChildren(),
				}),
			},
		}),
	})
end

return foundation.sections({
	summary = "A modal container for title, content, media, and actions with fixed semantic sizes.",
	controls = {
		size = UILabs.Choose(foundation.Dash.values(DialogSize :: any)),
		disablePortal = false,
		hasBackdrop = true,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizing", story = SizingStory },
		{
			name = "Controlled component",
			summary = "Parent owns open state; dismiss via onClose or action buttons.",
			story = ControlledStory,
		},
		{
			name = "Content",
			summary = "Optional subparts and backdrop.",
			story = function()
				return foundation.scroll(ContentStory())
			end,
		},
	},
})
