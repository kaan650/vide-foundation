local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local BadgeVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/BadgeVariant")
local IconSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/IconSize")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local PopoverAlign = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/PopoverAlign")
local PopoverSide = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/PopoverSide")
local Types = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Types")

type MenuItem = VideFoundation.MenuItem
type MenuItems = VideFoundation.MenuItems
type BadgeVariant = BadgeVariant.BadgeVariant
type ItemId = Types.ItemId
type PopoverSide = PopoverSide.PopoverSide

local IconName = VF.Enums.IconName

local SAMPLE_MENU_ITEMS: { MenuItem } = {
	{ id = "new", icon = IconName.CirclePlus, text = "New" },
	{ id = "edit", icon = IconName.Pencil, text = "Edit" },
	{ id = "copy", icon = IconName.StackedSquaresPlus, text = "Copy" },
	{ id = "delete", icon = IconName.TrashCan, text = "Delete", isDisabled = true },
}

-- Labels and icons cycled through to build menus of any length in the Playground.
local LONG_MENU_ITEMS: { { icon: string, text: string } } = {
	{ icon = IconName.CirclePlus, text = "New" },
	{ icon = IconName.Pencil, text = "Open" },
	{ icon = IconName.Pencil, text = "Save" },
	{ icon = IconName.Pencil, text = "Save As..." },
	{ icon = IconName.Pencil, text = "Rename" },
	{ icon = IconName.StackedSquaresPlus, text = "Duplicate" },
	{ icon = IconName.StackedSquaresPlus, text = "Copy" },
	{ icon = IconName.StackedSquaresPlus, text = "Cut" },
	{ icon = IconName.StackedSquaresPlus, text = "Paste" },
	{ icon = IconName.Pencil, text = "Export" },
	{ icon = IconName.Pencil, text = "Import" },
	{ icon = IconName.TrashCan, text = "Delete" },
}

local SELECTION_MENU_ITEMS: { MenuItem } = {
	{ id = "r15", text = "R15 Only" },
	{ id = "r6", text = "R6 Only" },
	{ id = "choice", text = "Player Choice" },
}

local LEADING_ICON_PALETTE = {
	IconName.Pencil,
	IconName.ClipboardPencil,
	IconName.TextBBold,
	IconName.ArrowUpFromLandscapeRectangle,
	IconName.StackedSquaresPlus,
	IconName.TrashCan,
}

local HINT_PALETTE = { "⌘B", "⌘I", "⌘C", "⌘V", "⌘S", "⌘Z" }

local BADGE_PALETTE: { { text: string, variant: BadgeVariant } } = {
	{ text = "New", variant = BadgeVariant.Success },
	{ text = "Beta", variant = BadgeVariant.Warning },
	{ text = "Pro", variant = BadgeVariant.Contrast },
	{ text = "Soon", variant = BadgeVariant.Neutral },
}

local AVATAR_USER_ID = 24813339

local SIDE_OPTIONS: { PopoverSide } = { PopoverSide.Bottom, PopoverSide.Top, PopoverSide.Left, PopoverSide.Right }

local function truncateDepth(items: any, depth: number, maxDepth: number): any
	local result = {}
	for _, item in items do
		local processed = table.clone(item)
		if processed.items then
			if depth >= maxDepth then
				processed.items = nil
			else
				processed.items = truncateDepth(processed.items, depth + 1, maxDepth)
			end
		end
		table.insert(result, processed)
	end
	return result
end

local function truncateGroups(groups: any, maxDepth: number): any
	local result = {}
	for _, group in groups do
		if group.items then
			local processed = table.clone(group)
			processed.items = truncateDepth(group.items, 1, maxDepth)
			table.insert(result, processed)
		else
			table.insert(result, truncateDepth({ group }, 1, maxDepth)[1])
		end
	end
	return result
end

local function makeNestedSubmenuItems(close: () -> ()): MenuItems
	local function closeOnActivated(id: string, text: string): MenuItem
		return {
			id = id,
			text = text,
			onActivated = function()
				print(`Menu item activated by child: {id}`)
				close()
			end,
		}
	end

	local obbyVersions: { MenuItem } = {
		{ id = "obby-v3", icon = "check-large", text = "v3.0 (Live)" },
		{ id = "obby-v2", text = "v2.5 (Draft)" },
		{ id = "obby-v1", text = "v1.0 (Archived)" },
		{ id = "obby-restore", icon = "arrow-rotate-right", text = "Restore Backup" },
	}
	local myPlaces: { MenuItem } = {
		{ id = "place-obby", icon = "globe-simplified", text = "Obby World", items = obbyVersions },
		{ id = "place-racing", icon = "globe-simplified", text = "Racing Game" },
		{ id = "place-rpg", icon = "globe-simplified", text = "RPG Quest" },
		{ id = "place-tycoon", icon = "globe-simplified", text = "Tycoon Builder" },
	}
	local openRecent: { MenuItem } = {
		{ id = "recent-places", icon = "folder", text = "My Places", items = myPlaces },
		{ id = "recent-team", icon = "folder", text = "Team Projects" },
		{ id = "recent-templates", text = "Templates" },
		{ id = "recent-clear", icon = "trash-can", text = "Clear History", isDisabled = true },
	}
	local exportItems: { MenuItem } = {
		{ id = "export-rbxl", text = "Place File (.rbxl)" },
		{ id = "export-rbxm", text = "Model File (.rbxm)" },
		{ id = "export-png", icon = "photo-camera", text = "Screenshot (.png)" },
		{ id = "export-json", icon = "code", text = "Selection as JSON" },
	}
	local fileItems: { MenuItem } = {
		{ id = "file-new", icon = "plus-small", text = "New Place" },
		{ id = "file-open-recent", icon = "clock", text = "Open Recent", items = openRecent },
		{ id = "file-save", icon = "floppy-disk", text = "Save" },
		{ id = "file-save-as", text = "Save As...", isDisabled = true },
		{ id = "file-export", icon = "arrow-large-right", text = "Export", items = exportItems },
		{ id = "file-publish", icon = "globe-simplified", text = "Publish to Roblox" },
		{ id = "file-close", icon = "x-large", text = "Close Place" },
	}

	local alignItems: { MenuItem } = {
		{ id = "align-left", icon = "arrow-large-left", text = "Align Left" },
		{ id = "align-center", text = "Align Center" },
		{ id = "align-right", icon = "arrow-large-right", text = "Align Right" },
		{ id = "align-top", icon = "arrow-large-up", text = "Align Top" },
		{ id = "align-middle", text = "Align Middle" },
		{ id = "align-bottom", icon = "arrow-large-down", text = "Align Bottom" },
	}
	local transformItems: { MenuItem } = {
		{ id = "transform-align", icon = "two-arrows-left-right", text = "Align", items = alignItems },
		{ id = "transform-rotate-cw", icon = "arrow-spin-clockwise", text = "Rotate 90\u{00B0} CW" },
		{ id = "transform-rotate-ccw", text = "Rotate 90\u{00B0} CCW" },
		{ id = "transform-flip-h", icon = "two-arrows-left-right", text = "Flip Horizontal" },
		{ id = "transform-flip-v", text = "Flip Vertical" },
		{ id = "transform-reset", text = "Reset Transform", isDisabled = true },
	}
	local editItems: { MenuItem } = {
		{ id = "edit-undo", icon = "arrow-large-left", text = "Undo" },
		{ id = "edit-redo", icon = "arrow-large-right", text = "Redo" },
		closeOnActivated("edit-cut", "Cut"),
		closeOnActivated("edit-copy", "Copy"),
		closeOnActivated("edit-paste", "Paste"),
		{ id = "edit-duplicate", text = "Duplicate", isDisabled = true },
		{ id = "edit-transform", icon = "arrow-spin-clockwise", text = "Transform", items = transformItems },
	}

	local viewItems: { MenuItem } = {
		{ id = "view-explorer", icon = "folder", text = "Explorer" },
		{ id = "view-properties", icon = "rectangle-list", text = "Properties" },
		{ id = "view-output", text = "Output" },
		{ id = "view-cmd-bar", text = "Command Bar" },
		{ id = "view-toolbox", text = "Toolbox" },
		{ id = "view-terrain", text = "Terrain Editor" },
	}

	local particleItems: { MenuItem } = {
		{ id = "style-fire", icon = "flame", text = "Fire" },
		{ id = "style-smoke", icon = "cloud", text = "Smoke" },
		{ id = "style-sparks", icon = "star", text = "Sparks" },
		{ id = "style-custom", icon = "gear", text = "Custom..." },
	}
	local effectItems: { MenuItem } = {
		{ id = "insert-particles", icon = "star", text = "Particles", items = particleItems },
		{ id = "effect-explosion", text = "Explosion" },
		{ id = "effect-highlight", icon = "eye", text = "Highlight" },
		{ id = "effect-bloom", text = "Bloom" },
	}
	local objectItems: { MenuItem } = {
		{ id = "insert-effects", icon = "star", text = "Effects", items = effectItems },
		{ id = "insert-part", icon = "cube-vertexes", text = "Part" },
		{ id = "insert-mesh", text = "Mesh Part" },
		{ id = "insert-model", text = "Model" },
		{ id = "insert-light", icon = "lightning-bolt", text = "Light" },
		{ id = "insert-sound", icon = "speaker", text = "Sound", isDisabled = true },
	}
	local insertItems: { MenuItem } = {
		{ id = "insert-object", icon = "cube-vertexes", text = "Object", items = objectItems },
		{ id = "insert-script", icon = "code", text = "Script" },
		{ id = "insert-local-script", text = "Local Script" },
		{ id = "insert-module", text = "Module Script" },
		{ id = "insert-folder", icon = "folder", text = "Folder" },
	}

	return {
		{
			title = "Document",
			items = {
				{ id = "file", icon = "page", text = "File", items = fileItems },
				{ id = "edit", icon = "pencil-square", text = "Edit", items = editItems },
			},
		},
		{
			title = "Workspace",
			items = {
				{ id = "view", icon = "eye", text = "View", items = viewItems },
				{ id = "insert", icon = "plus-large", text = "Insert", items = insertItems },
			},
		},
		{
			title = "Quick Actions",
			items = {
				{ id = "select-all", icon = "check-large", text = "Select All" },
				{ id = "preferences", icon = "gear", text = "Preferences" },
			},
		},
	} :: any
end

local function Stage(height: number, tag: string?, children: any)
	return VF.View({
		Size = UDim2.new(1, 0, 0, height),
		tag = tag,
		children = children,
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local isOpen = Vide.source(false)
	local selectedId = Vide.source(nil :: string?)
	local getSelectedId: () -> string? = selectedId :: any
	local itemTexts: { [string]: string } = {}

	local function leadingFor(leadingMode: string, index: number, currentDepth: number): any
		if leadingMode == "None" then
			return nil
		end
		if leadingMode == "Avatar" then
			return { type = "Avatar", userId = AVATAR_USER_ID }
		end
		if leadingMode == "Mixed" then
			-- icon, avatar, none, repeat
			local r = (index - 1) % 3
			if r == 1 then
				return { type = "Avatar", userId = AVATAR_USER_ID }
			elseif r == 2 then
				return nil
			end
		end
		return LEADING_ICON_PALETTE[((index - 1 + currentDepth) % #LEADING_ICON_PALETTE) + 1]
	end

	local function trailingFor(trailingMode: string, index: number, isSubmenu: boolean): any
		if isSubmenu or trailingMode == "None" then
			return nil
		end
		if trailingMode == "Hint" or (trailingMode == "Mixed" and index % 2 == 1) then
			return { type = "Hint", text = HINT_PALETTE[((index - 1) % #HINT_PALETTE) + 1] }
		end
		local badge = BADGE_PALETTE[((index - 1) % #BADGE_PALETTE) + 1]
		return { type = "Badge", text = badge.text, variant = badge.variant }
	end

	local function items(): MenuItems
		local leadingMode: string = controls.leading()
		local trailingMode: string = controls.trailing()
		local firstItemText: string = controls.firstItemText()
		local count: number = controls.numMenuItems()
		local selected = getSelectedId()

		local function buildMenu(currentDepth: number, prefix: string, isTopLevel: boolean): MenuItems
			local hasNested = currentDepth > 1
			local function buildItem(index: number, isSubmenuTrigger: boolean, isFirstOverall: boolean): MenuItem
				local id = `{prefix}-{index}`
				local poolItem = LONG_MENU_ITEMS[((index - 1) % #LONG_MENU_ITEMS) + 1]
				local label = if isSubmenuTrigger then `More ({poolItem.text})` else poolItem.text
				local resolvedText = if isFirstOverall and firstItemText ~= "" then firstItemText else label
				itemTexts[id] = resolvedText
				local item: MenuItem = {
					id = id,
					text = resolvedText,
					leading = leadingFor(leadingMode, index, currentDepth),
					trailing = trailingFor(trailingMode, index, isSubmenuTrigger),
					isChecked = if isSubmenuTrigger then nil else selected == id,
				}
				if isSubmenuTrigger then
					item.items = buildMenu(currentDepth - 1, `{id}-sub`, false) :: any
				end
				return item
			end

			--* The last item of each group opens a submenu, so every level stays reachable.
			local half = math.max(1, math.ceil(count / 2))
			local groupAItems: { MenuItem } = {}
			local groupBItems: { MenuItem } = {}
			for i = 1, count do
				local isSubmenuTrigger = hasNested and (i == half or i == count)
				local item = buildItem(i, isSubmenuTrigger, isTopLevel and i == 1)
				if i <= half then
					table.insert(groupAItems, item)
				else
					table.insert(groupBItems, item)
				end
			end

			local groupA = { title = "Group A", items = groupAItems }
			local groupB = { title = "Group B", items = groupBItems }
			return (if #groupBItems > 0 then { groupA, groupB } else { groupA }) :: any
		end

		return buildMenu(controls.maxDepth(), "p", true)
	end

	return Stage(
		480,
		"row align-x-center align-y-center",
		VF.Menu({
			isOpen = isOpen,
			items = items,
			size = controls.size,
			side = controls.side,
			align = controls.align,
			maxHeight = function(): number?
				local maxHeight: number = controls.maxHeight()
				return if maxHeight > 0 then maxHeight else nil
			end,
			onPressedOutside = function()
				isOpen(false)
			end,
			onActivated = function(id: ItemId)
				local key = tostring(id)
				print(`Menu: "{itemTexts[key] or key}" activated`)
				selectedId(key)
				isOpen(false)
			end,
			children = VF.Button({
				text = "Open Playground",
				size = InputSize.Medium,
				onActivated = function()
					isOpen(not isOpen())
				end,
			}),
		})
	)
end

local function AlwaysOpenStory(controls: { [string]: any })
	return Stage(
		300,
		"row align-x-center align-y-center",
		VF.Menu({
			isOpen = true,
			items = SAMPLE_MENU_ITEMS,
			size = controls.size,
			side = controls.side,
			align = controls.align,
			onActivated = function(id: ItemId)
				print("Always open menu item activated:", id)
			end,
			children = VF.Button({
				text = "Always Open Menu",
				size = InputSize.Medium,
				onActivated = function()
					print("Button clicked but menu stays open")
				end,
			}),
		})
	)
end

local function BasicMenuStory(controls: { [string]: any })
	local isOpen = Vide.source(false)

	return Stage(
		100,
		"row align-x-center align-y-center",
		VF.Menu({
			isOpen = isOpen,
			items = SAMPLE_MENU_ITEMS,
			size = controls.size,
			side = controls.side,
			align = controls.align,
			onPressedOutside = function()
				isOpen(false)
			end,
			onActivated = function(id: ItemId)
				print("Menu item activated:", id)
				isOpen(false)
			end,
			children = VF.Button({
				text = "Open Menu",
				size = InputSize.Medium,
				onActivated = function()
					isOpen(not isOpen())
				end,
			}),
		})
	)
end

local function SelectionMenuStory(controls: { [string]: any })
	local isOpen = Vide.source(false)
	local selectedItemId = Vide.source(SELECTION_MENU_ITEMS[1].id)

	return Stage(
		300,
		"row align-x-center align-y-center",
		VF.Menu({
			isOpen = isOpen,
			items = function(): MenuItems
				local selected = selectedItemId()
				return Dash.map(SELECTION_MENU_ITEMS, function(item: MenuItem): MenuItem
					return { id = item.id, text = item.text, isChecked = selected == item.id }
				end)
			end,
			size = controls.size,
			side = controls.side,
			align = controls.align,
			onPressedOutside = function()
				isOpen(false)
			end,
			onActivated = function(id: ItemId)
				selectedItemId(id)
			end,
			children = VF.Button({
				text = "Selection Menu",
				size = InputSize.Medium,
				onActivated = function()
					isOpen(not isOpen())
				end,
			}),
		})
	)
end

local function DifferentAnchorsStory(controls: { [string]: any })
	local isOpen1 = Vide.source(false)
	local isOpen2 = Vide.source(false)

	--* Each Menu returns an array, so the anchors need a LayoutOrder to sit in the row in React's order.
	return Stage(300, "row align-x-center align-y-center gap-large", {
		VF.Menu({
			LayoutOrder = 1,
			isOpen = isOpen1,
			items = SAMPLE_MENU_ITEMS,
			size = controls.size,
			side = controls.side,
			align = controls.align,
			onPressedOutside = function()
				isOpen1(false)
			end,
			onActivated = function(id: ItemId)
				print("Button menu item activated:", id)
				isOpen1(false)
			end,
			children = VF.IconButton({
				icon = IconName.CircleThreeDotsHorizontal,
				size = IconSize.Medium :: any,
				onActivated = function()
					isOpen1(not isOpen1())
				end,
			}),
		}),
		VF.Menu({
			LayoutOrder = 2,
			isOpen = isOpen2,
			items = SAMPLE_MENU_ITEMS,
			size = controls.size,
			side = controls.side,
			align = controls.align,
			onPressedOutside = function()
				isOpen2(false)
			end,
			onActivated = function(id: ItemId)
				print("Card menu item activated:", id)
				isOpen2(false)
			end,
			children = VF.View({
				tag = "col gap-medium auto-xy padding-large stroke-neutral radius-medium bg-surface-100",
				onActivated = function()
					isOpen2(not isOpen2())
				end,
				children = {
					VF.Text({
						Text = "Card with Menu",
						tag = "auto-xy text-heading-medium",
					}),
					VF.Text({
						Text = "Click me to open menu",
						tag = "auto-xy text-body-small",
					}),
				},
			}),
		}),
	})
end

local function ReferenceAnchorStory(controls: { [string]: any })
	local isOpen = Vide.source(false)
	local anchor = VF.Button({
		text = "Anchor outside of the menu component",
		size = InputSize.Medium,
		onActivated = function()
			isOpen(true)
		end,
	})

	return Stage(300, "row align-x-center align-y-center", {
		anchor,
		VF.Menu({
			isOpen = isOpen,
			items = SAMPLE_MENU_ITEMS,
			size = controls.size,
			side = controls.side,
			align = controls.align,
			onPressedOutside = function()
				isOpen(false)
			end,
			onActivated = function(id: ItemId)
				print("Always open menu item activated:", id)
			end,
			anchorRef = anchor,
		}),
	})
end

local function CoachmarkOnMenuItemStory(controls: { [string]: any })
	local isOpen = Vide.source(false)
	local isCoachmarkOpen = Vide.source(false)
	local coachmarkAnchor = Vide.source(nil :: GuiObject?)
	local getCoachmarkAnchor: () -> GuiObject? = coachmarkAnchor :: any
	local itemInstances: { [string]: GuiObject } = {}

	local function itemWithRef(id: string, text: string): MenuItem
		return {
			id = id,
			text = text,
			ref = function(instance: GuiObject)
				itemInstances[id] = instance
			end,
		}
	end

	local itemsWithRefs: { MenuItem } = {
		itemWithRef("option-a", "Option A"),
		itemWithRef("option-b", "Option B"),
	}

	return Stage(300, "row align-x-center align-y-center", {
		VF.Menu({
			isOpen = isOpen,
			items = itemsWithRefs,
			size = controls.size,
			side = controls.side,
			align = controls.align,
			onPressedOutside = function()
				isOpen(false)
			end,
			onActivated = function(id: ItemId)
				--* The menu stays open so the item stays mounted for the coachmark to anchor to.
				coachmarkAnchor(itemInstances[id :: string])
				isCoachmarkOpen(true)
			end,
			children = VF.Button({
				text = "Open Menu",
				size = InputSize.Medium,
				onActivated = function()
					isOpen(not isOpen())
				end,
			}),
		}),
		VF.Coachmark({
			title = "Anchored to this item",
			text = "The coachmark is anchored to the menu item you clicked.",
			isOpen = isCoachmarkOpen,
			anchorRef = getCoachmarkAnchor,
			onClose = function()
				isCoachmarkOpen(false)
			end,
		}),
	})
end

local function MatchAnchorWidthStory(controls: { [string]: any })
	local isOpen = Vide.source(false)
	local menuWidth = Vide.source(nil :: UDim?)
	local getMenuWidth: () -> UDim? = menuWidth :: any

	local anchor = VF.Button({
		text = "External anchor",
		size = InputSize.Medium,
		width = UDim.new(0, 220),
		onActivated = function()
			isOpen(not isOpen())
		end,
	})

	local function updateWidth()
		menuWidth(UDim.new(0, anchor.AbsoluteSize.X))
	end
	updateWidth()
	Vide.cleanup(anchor:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateWidth))

	return Stage(300, nil, {
		anchor,
		VF.Menu({
			isOpen = isOpen,
			items = SAMPLE_MENU_ITEMS,
			size = controls.size,
			side = controls.side,
			align = controls.align,
			width = getMenuWidth,
			onPressedOutside = function()
				isOpen(false)
			end,
			onActivated = function(id: ItemId)
				print("Menu item activated:", id)
				isOpen(false)
			end,
			anchorRef = anchor,
		}),
	})
end

local function GroupedStory(controls: { [string]: any })
	local isOpen = Vide.source(false)
	local selectedItemId = Vide.source("a1" :: ItemId)

	local function items(): MenuItems
		local selected = selectedItemId()
		return {
			{
				title = "First title",
				items = {
					{ id = "a1", icon = IconName.Robux, text = "Alpha 1", isChecked = selected == "a1" },
					{ id = "a2", text = "Alpha 2", isChecked = selected == "a2" },
				},
			},
			{
				items = {
					{ id = "b1", text = "Beta 1", isChecked = selected == "b1" },
					{ id = "b2", isDisabled = true, text = "Beta 2 (disabled)", isChecked = selected == "b2" },
				},
			},
			{
				items = {
					{ id = "c1", text = "Untitled group item", isChecked = selected == "c1" },
				},
			},
		} :: any
	end

	return Stage(
		100,
		"row align-x-center align-y-center",
		VF.Menu({
			isOpen = isOpen,
			items = items,
			size = controls.size,
			side = controls.side,
			align = controls.align,
			onPressedOutside = function()
				isOpen(false)
			end,
			onActivated = function(id: ItemId)
				isOpen(false)
				selectedItemId(id)
			end,
			children = VF.Button({
				text = "Open Menu",
				size = InputSize.Medium,
				onActivated = function()
					isOpen(not isOpen())
				end,
			}),
		})
	)
end

local function NestedSubmenusStory(controls: { [string]: any })
	local isOpen = Vide.source(false)
	local function close()
		isOpen(false)
	end

	return Stage(
		600,
		"row align-x-center align-y-center",
		VF.Menu({
			isOpen = isOpen,
			items = function(): MenuItems
				return truncateGroups(makeNestedSubmenuItems(close), controls.maxDepth())
			end,
			size = controls.size,
			side = controls.side,
			align = controls.align,
			onPressedOutside = close,
			onActivated = function(id: ItemId)
				print("Menu item activated by parent:", id)
				close()
			end,
			children = VF.Button({
				text = "Open Menu",
				size = InputSize.Medium,
				onActivated = function()
					isOpen(not isOpen())
				end,
			}),
		})
	)
end

local function printPerItem(id: ItemId)
	print("Per-item onActivated:", id)
end

local PER_ITEM_MENU_ITEMS: { MenuItem } = {
	{
		id = "file",
		icon = "page",
		text = "File",
		items = {
			{ id = "file-new", icon = "plus-small", text = "New Place", onActivated = printPerItem },
			{
				id = "file-open-recent",
				icon = "clock",
				text = "Open Recent",
				items = {
					{ id = "recent-project-a", text = "Project A", onActivated = printPerItem },
					{ id = "recent-project-b", text = "Project B", onActivated = printPerItem },
				} :: any,
			},
		} :: any,
	},
	{
		id = "edit",
		icon = "pencil-square",
		text = "Edit",
		items = {
			{ id = "edit-cut", text = "Cut", onActivated = printPerItem },
			{ id = "edit-copy", text = "Copy", onActivated = printPerItem },
		} :: any,
	},
}

local function PerItemOnActivatedStory(controls: { [string]: any })
	local isOpen = Vide.source(false)

	return Stage(
		600,
		"row align-x-center align-y-center",
		VF.Menu({
			isOpen = isOpen,
			items = PER_ITEM_MENU_ITEMS,
			size = controls.size,
			side = controls.side,
			align = controls.align,
			onPressedOutside = function()
				isOpen(false)
			end,
			children = VF.Button({
				text = "Open Menu",
				size = InputSize.Medium,
				onActivated = function()
					isOpen(not isOpen())
				end,
			}),
		})
	)
end

return foundation.sections({
	summary = "Menu - A popover-based menu component that combines Popover with InternalMenu",
	controls = {
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		side = UILabs.Choose(SIDE_OPTIONS),
		align = UILabs.Choose(Dash.values(PopoverAlign :: any)),
		maxDepth = UILabs.Choose({ 3, 4, 5, 2, 1 }),
		numMenuItems = 6,
		maxHeight = UILabs.Choose({ 0, 180, 240, 360 }),
		firstItemText = "Action one",
		leading = UILabs.Choose({ "Icon", "Avatar", "Mixed", "None" }),
		trailing = UILabs.Choose({ "Hint", "Badge", "Mixed", "None" }),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Always Open", story = AlwaysOpenStory },
		{ name = "Basic Menu", story = BasicMenuStory },
		{ name = "Selection Menu", story = SelectionMenuStory },
		{ name = "Different Anchors", story = DifferentAnchorsStory },
		{ name = "Reference anchor", story = ReferenceAnchorStory },
		{ name = "Coachmark on menu item", story = CoachmarkOnMenuItemStory },
		{ name = "Match anchorRef width", story = MatchAnchorWidthStory },
		{ name = "Grouped", story = GroupedStory },
		{ name = "Nested Submenus", story = NestedSubmenusStory },
		{ name = "Nested Submenus (per-item onActivated)", story = PerItemOnActivatedStory },
	},
})
