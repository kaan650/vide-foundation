local DialogStoryHelpers = require("../Shared/DialogStoryHelpers")
local MatrixGrid = require("../Shared/MatrixGrid")
local foundation = require("../foundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local DialogActions = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Dialog/Actions")
local DialogSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/DialogSize")
local Orientation = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/Orientation")

type DialogAction = DialogActions.DialogAction
type DialogSize = DialogSize.DialogSize
type Orientation = Orientation.Orientation

local LabeledDialogTrigger = DialogStoryHelpers.LabeledDialogTrigger
local Section = DialogStoryHelpers.Section
local makeDialogChildren = DialogStoryHelpers.makeDialogChildren

local SIZE_ORDER: { DialogSize } = DialogStoryHelpers.SIZE_ORDER
local ORIENTATION_ORDER: { Orientation } = {
	Orientation.Horizontal,
	Orientation.Vertical,
}
local ACTION_COUNTS = { 1, 2, 3 }
local ACTIONS_MATRIX_LABEL_WIDTH = 80
local ACTIONS_MATRIX_CELL_WIDTH = 160
local LONG_ACTIONS_LABEL = "Actions label copy can wrap across multiple lines when the dialog is narrow."

local function makeActions(actionCount: number): { DialogAction }
	if actionCount == 1 then
		return {
			{
				text = "Confirm",
				variant = ButtonVariant.Emphasis,
				onActivated = function() end,
			},
		}
	end

	if actionCount == 2 then
		return DialogStoryHelpers.DEFAULT_ACTIONS
	end

	return {
		{
			text = "Cancel",
			variant = ButtonVariant.Standard,
			onActivated = function() end,
		},
		{
			text = "Maybe",
			variant = ButtonVariant.Standard,
			onActivated = function() end,
		},
		{
			text = "Confirm",
			variant = ButtonVariant.Emphasis,
			onActivated = function() end,
		},
	}
end

local function dialogSizeForOrientation(orientation: Orientation): DialogSize?
	if orientation == Orientation.Vertical then
		return DialogSize.Small
	end

	return nil
end

local function orientationLabel(orientation: Orientation): string
	if orientation == Orientation.Vertical then
		return "Vertical (Small)"
	end

	return "Horizontal"
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
		children = makeDialogChildren({
			hasActions = true,
			actionsOrientation = controls.orientation,
			actionsLabel = function()
				local label = controls.label()
				return if label ~= "" then label else nil
			end,
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
			children = makeDialogChildren({
				hasActions = true,
				actionsOrientation = Orientation.Horizontal,
			}),
		})
	end

	return Page(Section({
		layoutOrder = 1,
		name = "Size",
		children = triggers,
	}))
end

local function OrientationStory()
	local triggers = {}
	for index, orientation in ORIENTATION_ORDER do
		triggers[index] = LabeledDialogTrigger({
			label = orientationLabel(orientation),
			layoutOrder = index,
			size = dialogSizeForOrientation(orientation),
			children = makeDialogChildren({
				hasActions = true,
				actionsOrientation = orientation,
			}),
		})
	end

	return VF.View({
		tag = "row gap-large align-y-start auto-xy wrap padding-large bg-surface-0",
		children = triggers,
	})
end

local function ContentStory()
	local orientationHeaders: { string } = {}
	local labelCells = {}
	for index, orientation in ORIENTATION_ORDER do
		orientationHeaders[index] = orientationLabel(orientation)
		labelCells[index] = LabeledDialogTrigger({
			layoutOrder = 1,
			size = dialogSizeForOrientation(orientation),
			children = makeDialogChildren({
				hasActions = true,
				actionsOrientation = orientation,
				actionsLabel = "Choose an option below.",
			}),
		})
	end

	local countHeaders: { string } = {}
	for index, actionCount in ACTION_COUNTS do
		countHeaders[index] = if actionCount == 1 then "1 button" else `{actionCount} buttons`
	end

	local countRows: { MatrixGrid.MatrixGridRow } = {}
	for index, orientation in ORIENTATION_ORDER do
		local cells = {}
		for cellIndex, actionCount in ACTION_COUNTS do
			cells[cellIndex] = LabeledDialogTrigger({
				layoutOrder = 1,
				size = dialogSizeForOrientation(orientation),
				children = makeDialogChildren({
					hasActions = true,
					actionsOrientation = orientation,
					actions = makeActions(actionCount),
				}),
			})
		end
		countRows[index] = {
			label = MatrixGrid.matrixLabel(orientationLabel(orientation)),
			cells = cells,
		}
	end

	return Page({
		Section({
			layoutOrder = 1,
			name = "Label",
			contentTag = "auto-xy",
			children = MatrixGrid.MatrixGrid({
				labelColumnWidth = ACTIONS_MATRIX_LABEL_WIDTH,
				columnHeaders = orientationHeaders,
				cellColumnWidth = ACTIONS_MATRIX_CELL_WIDTH,
				headerTextAlign = "left",
				cellAlign = "left",
				rows = {
					{
						label = MatrixGrid.matrixLabel("With label"),
						cells = labelCells,
					},
				},
			}),
		}),
		Section({
			layoutOrder = 2,
			name = "Long label",
			children = LabeledDialogTrigger({
				layoutOrder = 1,
				children = makeDialogChildren({
					hasActions = true,
					actionsLabel = LONG_ACTIONS_LABEL,
				}),
			}),
		}),
		Section({
			layoutOrder = 3,
			name = "Button count",
			note = "Action count is unbounded; 1–3 are representative examples. Prefer no more than 3.",
			contentTag = "auto-xy",
			children = MatrixGrid.MatrixGrid({
				labelColumnWidth = ACTIONS_MATRIX_LABEL_WIDTH,
				columnHeaders = countHeaders,
				cellColumnWidth = ACTIONS_MATRIX_CELL_WIDTH,
				headerTextAlign = "left",
				cellAlign = "left",
				rows = countRows,
			}),
		}),
	})
end

return foundation.sections({
	summary = "Renders dialog action buttons and an optional label. Layout follows root size — vertical orientation applies only at Small.",
	controls = {
		rootSize = UILabs.Choose(foundation.Dash.values(DialogSize :: any)),
		orientation = UILabs.Choose(foundation.Dash.values(Orientation :: any)),
		label = "",
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizing", story = SizingStory },
		{
			name = "Orientation",
			summary = "Vertical layout only works at Small. At Medium (default), DialogActions always renders horizontal regardless of the orientation prop. The Vertical example opens Small so stacked buttons are visible.",
			story = OrientationStory,
		},
		{ name = "Content", story = ContentStory },
	},
})
