local foundation = require("../foundation")
local KeyCodeCategories = require("../Shared/KeyCodeCategories")
local MatrixGrid = require("../Shared/MatrixGrid")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local ChipSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ChipSize")
local getVisualForKey = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/KeyLabel/getVisualForKey")

type ColorStyleValue = VideFoundation.ColorStyleValue
type HoldBehavior = {
	holdTime: number?,
	resetTime: number?,
	onEndHold: (didActivate: boolean) -> (),
	onBeginHold: (() -> ())?,
}

local DEFAULT_KEY_LABEL_SIZE = UDim2.fromOffset(35, 35)

--* Choose controls hold names, mapped to the KeyCodes and sizes Foundation's controls list.
local PLAYGROUND_KEYCODE_OPTIONS = { "Comma", "A", "ButtonStart" }

local PLAYGROUND_SIZE_LABELS = { "35×35", "48×48", "64×64" }
local PLAYGROUND_SIZE_OPTIONS: { [string]: UDim2 } = {
	["35×35"] = DEFAULT_KEY_LABEL_SIZE,
	["48×48"] = UDim2.fromOffset(48, 48),
	["64×64"] = UDim2.fromOffset(64, 64),
}

type VisualTypeExample = {
	keyCode: Enum.KeyCode,
	name: string,
	description: string,
}

local VISUAL_TYPES: { VisualTypeExample } = {
	{
		keyCode = Enum.KeyCode.Comma,
		name = "String",
		description = "UserInputService:GetImageForKeyCode returns nothing. KeyLabel renders GetStringForKeyCode text on a sliced key cap.",
	},
	{
		keyCode = Enum.KeyCode.ButtonStart,
		name = "Image",
		description = "UserInputService:GetImageForKeyCode returns a platform glyph. KeyLabel renders the image — not text on a key cap.",
	},
	{
		keyCode = Enum.KeyCode.Space,
		name = "Empty",
		description = "Both lookups return empty on the current platform. KeyLabel shows an empty key cap with no label.",
	},
}

local REPRESENTATIVE_SIZES = {
	{ label = "35×35", size = DEFAULT_KEY_LABEL_SIZE },
	{ label = "48×48", size = UDim2.fromOffset(48, 48) },
	{ label = "64×64", size = UDim2.fromOffset(64, 64) },
}

type SizingContentType = {
	name: string,
	keyCode: Enum.KeyCode,
	hasHoldBehavior: boolean?,
}

local SIZING_CONTENT_TYPES: { SizingContentType } = {
	{ name = "String", keyCode = Enum.KeyCode.Comma },
	{ name = "Image", keyCode = Enum.KeyCode.ButtonStart },
	{ name = "String with ring", keyCode = Enum.KeyCode.Comma, hasHoldBehavior = true },
	{ name = "Image with ring", keyCode = Enum.KeyCode.ButtonStart, hasHoldBehavior = true },
}

local DEMO_HOLD_BEHAVIOR: HoldBehavior = {
	holdTime = 1,
	resetTime = 0.5,
	onBeginHold = function() end,
	onEndHold = function(_didActivate: boolean) end,
}

local SIZE_MATRIX_LABEL_WIDTH = 56
local SIZE_MATRIX_CELL_WIDTH = 72

local ALL_KEYCODES = Enum.KeyCode:GetEnumItems()
table.sort(ALL_KEYCODES, function(a, b)
	return KeyCodeCategories.getKeyCodeName(a) < KeyCodeCategories.getKeyCodeName(b)
end)

local KEYCODES_BY_CATEGORY = KeyCodeCategories.groupByCategory(ALL_KEYCODES)
local NON_EMPTY_CATEGORIES = KeyCodeCategories.getNonEmptyCategories(KEYCODES_BY_CATEGORY)

local KEYCODE_LABEL_COLUMN_WIDTH = 200
local KEYCODE_CELL_COLUMN_WIDTH = 48
local EMPTY_ROW_BACKGROUND_TRANSPARENCY = 0.9

local ALL_KEY_TYPE_VALUE = "All"

local KEY_TYPE_CATEGORY_OPTIONS: { string } = { ALL_KEY_TYPE_VALUE }
for _, categoryName in NON_EMPTY_CATEGORIES do
	table.insert(KEY_TYPE_CATEGORY_OPTIONS, categoryName)
end

local function Section(props: { layoutOrder: number, name: string, contentTag: string?, children: any })
	return VF.View({
		tag = "col gap-medium size-full-0 auto-y",
		LayoutOrder = props.layoutOrder,
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

local function getHoldBehavior(controls: { [string]: any }): HoldBehavior?
	return if controls.hasHoldBehavior()
		then {
			holdTime = controls.holdTime(),
			resetTime = controls.resetTime(),
			onBeginHold = DEMO_HOLD_BEHAVIOR.onBeginHold,
			onEndHold = DEMO_HOLD_BEHAVIOR.onEndHold,
		}
		else nil
end

local function PlaygroundStory(controls: { [string]: any })
	local function holdKey(): string
		return `{controls.hasHoldBehavior()}|{controls.holdTime()}|{controls.resetTime()}`
	end

	--* holdBehavior is a plain table, so a change to it builds the key again.
	return foundation.rebuildOn(holdKey, function()
		return VF.KeyLabel({
			keyCode = function(): Enum.KeyCode
				return (Enum.KeyCode :: any)[controls.keyCode()]
			end,
			Size = function()
				return PLAYGROUND_SIZE_OPTIONS[controls.Size()]
			end,
			holdBehavior = getHoldBehavior(controls),
		})
	end)
end

local function VisualTypeExampleView(props: VisualTypeExample & { layoutOrder: number })
	return VF.View({
		tag = "col align-x-left gap-medium auto-xy",
		LayoutOrder = props.layoutOrder,
		children = {
			VF.KeyLabel({
				keyCode = props.keyCode,
				Size = DEFAULT_KEY_LABEL_SIZE,
				LayoutOrder = 1,
			}),
			VF.Text({
				Text = props.description,
				tag = "auto-xy text-body-small text-wrap text-align-x-left content-muted",
				LayoutOrder = 2,
			}),
		},
	})
end

local function SizingStory()
	local columnHeaders = {}
	for index, contentType in SIZING_CONTENT_TYPES do
		columnHeaders[index] = contentType.name
	end

	local rows: { MatrixGrid.MatrixGridRow } = {}
	for index, entry in REPRESENTATIVE_SIZES do
		local cells = {}
		for cellIndex, contentType in SIZING_CONTENT_TYPES do
			cells[cellIndex] = VF.KeyLabel({
				keyCode = contentType.keyCode,
				Size = entry.size,
				holdBehavior = if contentType.hasHoldBehavior then DEMO_HOLD_BEHAVIOR else nil,
			})
		end
		rows[index] = {
			label = MatrixGrid.matrixLabel(entry.label),
			cells = cells,
		}
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = Section({
			layoutOrder = 1,
			name = "Size",
			contentTag = "auto-xy",
			children = MatrixGrid.MatrixGrid({
				labelColumnWidth = SIZE_MATRIX_LABEL_WIDTH,
				columnHeaders = columnHeaders,
				cellColumnWidth = SIZE_MATRIX_CELL_WIDTH,
				rows = rows,
			}),
		}),
	})
end

local function HoldBehaviorExample(props: {
	keyCode: Enum.KeyCode,
	holdTime: number,
	resetTime: number?,
	caption: string,
	layoutOrder: number,
})
	local callbackLog = Vide.source({} :: { string })

	local function appendCallbackLog(entry: string)
		local nextLog = table.clone(callbackLog())
		table.insert(nextLog, entry)
		callbackLog(nextLog)
	end

	return VF.View({
		tag = "col align-x-left gap-medium auto-xy",
		LayoutOrder = props.layoutOrder,
		children = {
			VF.Text({
				Text = props.caption,
				tag = "auto-xy text-caption-small content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "row align-y-center gap-large auto-xy",
				LayoutOrder = 2,
				children = VF.KeyLabel({
					keyCode = props.keyCode,
					Size = DEFAULT_KEY_LABEL_SIZE,
					holdBehavior = {
						holdTime = props.holdTime,
						resetTime = props.resetTime,
						onBeginHold = function()
							appendCallbackLog("onBeginHold()")
						end,
						onEndHold = function(didActivate: boolean)
							appendCallbackLog(`onEndHold(didActivate = {tostring(didActivate)})`)
						end,
					},
					LayoutOrder = 1,
				}),
			}),
			VF.Text({
				Text = function()
					local log = callbackLog()
					return if #log > 0
						then table.concat(log, "\n")
						else "No callbacks yet — press the key to trigger onBeginHold and onEndHold."
				end,
				tag = "auto-xy text-body-small text-wrap text-align-x-left content-muted",
				LayoutOrder = 3,
			}),
		},
	})
end

local function HoldBehaviorStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = {
			Section({
				layoutOrder = 1,
				name = "Hold to activate",
				contentTag = "auto-xy",
				children = HoldBehaviorExample({
					keyCode = Enum.KeyCode.Space,
					holdTime = 1,
					resetTime = 0.5,
					caption = "Hold Space for 1 second to activate.",
					layoutOrder = 1,
				}),
			}),
			Section({
				layoutOrder = 2,
				name = "Instant activation",
				contentTag = "auto-xy",
				children = HoldBehaviorExample({
					keyCode = Enum.KeyCode.A,
					holdTime = 0,
					resetTime = 0,
					caption = "Press A to activate immediately (holdTime = 0).",
					layoutOrder = 1,
				}),
			}),
			Section({
				layoutOrder = 3,
				name = "Reset time",
				contentTag = "row gap-xlarge auto-xy wrap",
				children = {
					HoldBehaviorExample({
						keyCode = Enum.KeyCode.Space,
						holdTime = 1,
						resetTime = 0.25,
						caption = "resetTime = 0.25 — release early to see the progress ring drain quickly.",
						layoutOrder = 1,
					}),
					HoldBehaviorExample({
						keyCode = Enum.KeyCode.Space,
						holdTime = 1,
						resetTime = 1.5,
						caption = "resetTime = 1.5 — release early to see the progress ring drain slowly.",
						layoutOrder = 2,
					}),
				},
			}),
		},
	})
end

local function KeyCodeMatrix(keyCodes: { Enum.KeyCode })
	local tokens = VF.Hooks.useTokens()
	local function emptyRowBackground(): ColorStyleValue
		return {
			Color3 = tokens().Color.System.Alert.Color3,
			Transparency = EMPTY_ROW_BACKGROUND_TRANSPARENCY,
		}
	end

	local rows: { MatrixGrid.MatrixGridRow } = {}
	for index, keyCode in keyCodes do
		local isEmpty = getVisualForKey(keyCode).key == ""
		rows[index] = {
			label = VF.Text({
				Text = KeyCodeCategories.getKeyCodeName(keyCode),
				tag = "auto-xy text-caption-small text-align-x-left",
			}),
			cells = {
				VF.KeyLabel({
					keyCode = keyCode,
					Size = DEFAULT_KEY_LABEL_SIZE,
				}),
			},
			rowTag = if isEmpty then "padding-x-small radius-small size-full-0 auto-y" else nil,
			--* MatrixGrid hands the style to View, which takes a source, so it follows the theme.
			backgroundStyle = if isEmpty then emptyRowBackground :: any else nil,
		}
	end

	return MatrixGrid.MatrixGrid({
		labelColumnWidth = KEYCODE_LABEL_COLUMN_WIDTH,
		cellColumnWidth = KEYCODE_CELL_COLUMN_WIDTH,
		showHeader = false,
		columnHeaders = { "" },
		headerTextAlign = "left",
		cellAlign = "left",
		rows = rows,
	})
end

local function CategoryKeyLabelTable(props: { categoryName: string, layoutOrder: number })
	local keyCodes = KEYCODES_BY_CATEGORY[props.categoryName]

	return Section({
		layoutOrder = props.layoutOrder,
		name = `{props.categoryName} ({#keyCodes})`,
		contentTag = "auto-xy",
		children = KeyCodeMatrix(keyCodes),
	})
end

local function ByKeyTypeSection()
	local selectedCategory = Vide.source(ALL_KEY_TYPE_VALUE)

	local categoryChips = {}
	for index, categoryName in KEY_TYPE_CATEGORY_OPTIONS do
		categoryChips[index] = VF.Chip({
			text = if categoryName == ALL_KEY_TYPE_VALUE
				then ALL_KEY_TYPE_VALUE
				else `{categoryName} ({#KEYCODES_BY_CATEGORY[categoryName]})`,
			size = ChipSize.Small,
			isChecked = function()
				return selectedCategory() == categoryName
			end,
			onActivated = function()
				selectedCategory(categoryName)
			end,
			LayoutOrder = index,
		})
	end

	return VF.View({
		tag = "col gap-large size-full-0 auto-y",
		children = {
			VF.View({
				tag = "row wrap gap-small size-full-0 auto-y",
				LayoutOrder = 1,
				children = categoryChips,
			}),
			foundation.rebuildOn(selectedCategory, function(category: string)
				local tables = {}
				if category == ALL_KEY_TYPE_VALUE then
					for index, categoryName in NON_EMPTY_CATEGORIES do
						tables[index] = CategoryKeyLabelTable({ categoryName = categoryName, layoutOrder = index })
					end
				else
					tables[1] = CategoryKeyLabelTable({ categoryName = category, layoutOrder = 1 })
				end
				return VF.View({
					tag = "col gap-xxlarge size-full-0 auto-y",
					LayoutOrder = 2,
					children = tables,
				})
			end),
		},
	})
end

local function ContentStory()
	local visualTypes = {}
	for index, visualType in VISUAL_TYPES do
		visualTypes[index] = Section({
			layoutOrder = index,
			name = visualType.name,
			contentTag = "auto-xy",
			children = VisualTypeExampleView({
				layoutOrder = 1,
				keyCode = visualType.keyCode,
				name = visualType.name,
				description = visualType.description,
			}),
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = {
			Section({
				layoutOrder = 2,
				name = "Visual types",
				contentTag = "col gap-xxlarge auto-xy",
				children = visualTypes,
			}),
			Section({
				layoutOrder = 3,
				name = "By key type",
				contentTag = "auto-xy",
				children = ByKeyTypeSection(),
			}),
		},
	})
end

return foundation.sections({
	summary = "KeyLabel displays a key or button glyph and optionally handles long-press input with a circular progress indicator.",
	controls = {
		keyCode = UILabs.Choose(PLAYGROUND_KEYCODE_OPTIONS),
		Size = UILabs.Choose(PLAYGROUND_SIZE_LABELS),
		hasHoldBehavior = false,
		holdTime = 1,
		resetTime = 0.5,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Sizing",
			summary = "Size accepts any UDim2; values shown are representative examples. Hold the key on ring columns to preview the progress indicator at each size.",
			story = SizingStory,
		},
		{
			name = "Hold behavior",
			story = function()
				return foundation.scroll(HoldBehaviorStory())
			end,
		},
		{
			name = "Content",
			story = function()
				return foundation.scroll(ContentStory())
			end,
		},
	},
})
