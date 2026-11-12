local foundation = require("../foundation")
local MatrixGrid = require("../Shared/MatrixGrid")
local UILabs = foundation.UILabs
local VF = foundation.VF

local Shortcut = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Shortcut")

local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local Placement = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/Placement")
local ShortcutSeparator = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ShortcutSeparator")
local ShortcutVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ShortcutVariant")

type Placement = Placement.Placement
type ShortcutKey = Shortcut.ShortcutKey
type ShortcutSize = Shortcut.ShortcutSize
type ShortcutVariant = ShortcutVariant.ShortcutVariant

local SIZES: { ShortcutSize } = { InputSize.XSmall, InputSize.Small, InputSize.Medium }
local VARIANTS: { ShortcutVariant } = { ShortcutVariant.Standard, ShortcutVariant.Contrast }
local PLACEMENTS: { Placement } = { Placement.Start, Placement.End }

local MOVE_FORWARD: { ShortcutKey } = {
	{ keyCode = Enum.KeyCode.W },
	{ separator = ShortcutSeparator.Or },
	{ keyCode = Enum.KeyCode.Up },
}

local COMMAND_PALETTE: { ShortcutKey } = {
	{ keyCode = Enum.KeyCode.LeftControl },
	{ keyCode = Enum.KeyCode.LeftShift },
	{ keyCode = Enum.KeyCode.P },
}

type KeyExample = { label: string, shortcut: { ShortcutKey }, keybinding: string }

local KEY_EXAMPLES: { KeyExample } = {
	{ label = "One character", shortcut = { { keyCode = Enum.KeyCode.E } }, keybinding = "Interact" },
	{ label = "Word", shortcut = { { keyCode = Enum.KeyCode.PageUp } }, keybinding = "Scroll up" },
	{ label = "Two characters", shortcut = { { keyCode = Enum.KeyCode.F5 } }, keybinding = "Refresh" },
	{ label = "Glyph", shortcut = { { keyCode = Enum.KeyCode.Return } }, keybinding = "Send" },
	{ label = "Mouse", shortcut = { { keyCode = Enum.KeyCode.MouseRightButton } }, keybinding = "Rotate camera" },
	{
		label = "Gamepad",
		shortcut = {
			{ keyCode = Enum.KeyCode.ButtonA },
			{ separator = ShortcutSeparator.Or },
			{ keyCode = Enum.KeyCode.ButtonR2 },
		},
		keybinding = "Jump",
	},
	{
		label = "Chord",
		shortcut = { { keyCode = Enum.KeyCode.LeftControl }, { keyCode = Enum.KeyCode.Z } },
		keybinding = "Undo",
	},
	{
		label = "Or",
		shortcut = MOVE_FORWARD,
		keybinding = "Move forward",
	},
	{
		label = "More",
		shortcut = {
			{ keyCode = Enum.KeyCode.One },
			{ separator = ShortcutSeparator.More },
			{ keyCode = Enum.KeyCode.Nine },
		},
		keybinding = "Equip a tool",
	},
}

local function PlaygroundStory(controls: { [string]: any })
	return Shortcut({
		shortcut = MOVE_FORWARD,
		keybinding = controls.keybinding,
		size = controls.size,
		variant = controls.variant,
		placement = controls.placement,
	})
end

local function UsageStory()
	return Shortcut({
		shortcut = MOVE_FORWARD,
		keybinding = "Move forward",
	})
end

local function SizesStory()
	local rows: { MatrixGrid.MatrixGridRow } = {}
	for index, size in SIZES do
		local cells = {}
		for cellIndex, variant in VARIANTS do
			cells[cellIndex] = Shortcut({
				shortcut = COMMAND_PALETTE,
				keybinding = "Command palette",
				size = size,
				variant = variant,
			})
		end
		rows[index] = { label = MatrixGrid.matrixLabel(size), cells = cells }
	end
	return MatrixGrid.MatrixGrid({
		labelColumnWidth = 80,
		columnHeaders = VARIANTS :: { string },
		cellColumnWidth = 240,
		cellAlign = "left",
		rows = rows,
	})
end

local function KeysStory()
	local rows: { MatrixGrid.MatrixGridRow } = {}
	for index, example in KEY_EXAMPLES do
		rows[index] = {
			label = MatrixGrid.matrixLabel(example.label),
			cells = {
				Shortcut({ shortcut = example.shortcut, keybinding = example.keybinding }),
				Shortcut({ shortcut = example.shortcut, keybinding = example.keybinding, size = InputSize.Medium }),
			},
		}
	end
	return foundation.scroll(MatrixGrid.MatrixGrid({
		labelColumnWidth = 120,
		columnHeaders = { InputSize.XSmall, InputSize.Medium },
		cellColumnWidth = 240,
		cellAlign = "left",
		rows = rows,
	}))
end

local function PlacementStory()
	local rows: { MatrixGrid.MatrixGridRow } = {}
	for index, placement in PLACEMENTS do
		rows[index] = {
			label = MatrixGrid.matrixLabel(placement),
			cells = {
				Shortcut({ shortcut = MOVE_FORWARD, keybinding = "Move forward", placement = placement }),
			},
		}
	end
	return MatrixGrid.MatrixGrid({
		labelColumnWidth = 80,
		columnHeaders = { "Shortcut" },
		cellColumnWidth = 240,
		cellAlign = "left",
		rows = rows,
	})
end

return foundation.sections({
	summary = "Shortcut displays a keyboard or gamepad shortcut as a row of key caps. It does not register the binding. Prefer Shortcut over the deprecated KeyLabel component.",
	controls = {
		keybinding = "Move forward",
		size = UILabs.Choose(SIZES :: { string }),
		variant = UILabs.Choose(VARIANTS :: { string }),
		placement = UILabs.Choose(PLACEMENTS :: { string }),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Usage", story = UsageStory },
		{ name = "Sizes and variants", story = SizesStory },
		{
			name = "Keys",
			summary = "Adjacent keys read as a chord; Or (/) and More (…) separate keys only when adjacency would be wrong. Gamepad glyphs draw without a cap.",
			story = KeysStory,
		},
		{ name = "Placement", story = PlacementStory },
	},
})
