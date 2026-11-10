local foundation = require("../foundation")
local scrollToSelected = require("../Shared/ScrollToSelected")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local BaseMenu = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/BaseMenu")
local BuilderIcons = require("@game/ReplicatedStorage/Packages/VideFoundation/Packages/BuilderIcons")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local ThumbnailType = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ThumbnailType")
local Types = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Types")
local getRbxThumb = require("@game/ReplicatedStorage/Packages/VideFoundation/Utility/getRbxThumb")

type BaseMenuItem = BaseMenu.BaseMenuItem
type BaseMenuItems = BaseMenu.BaseMenuItems
type InputSize = InputSize.InputSize
type ItemId = Types.ItemId

local IconName = BuilderIcons.Icon

local exampleIcons: { string } = {}
for uibloxIcon in BuilderIcons.Migration["uiblox"] :: { [string]: any } do
	table.insert(exampleIcons, uibloxIcon)
end

local BASE_ITEMS: { BaseMenuItem } = {
	{ id = "1", icon = IconName.Robux, text = "Item" },
	{ id = "2", icon = IconName.Diamond, isChecked = true, text = "Item" },
	{ id = "3", isDisabled = true, text = "Item" },
}

local EXPERIENCE_DATA: { { name: string, universeId: number } } = {
	{ name = "[💘] RIVALS", universeId = 6035872082 },
	{ name = "[❤️ Event] Blox Fruits", universeId = 994732206 },
	{ name = "Bee Swarm Simulator", universeId = 601130232 },
	{ name = "Murder Mystery 2", universeId = 66654135 },
	{ name = "[❤️‍🔥] Adopt Me!", universeId = 383310974 },
}

local SCROLL_TO_SELECTION_MAX_HEIGHT = 120
local SCROLL_TO_SELECTION_ITEM_COUNT = 20

local function noop() end

local function PlaygroundStory(controls: { [string]: any })
	local selectedItem = Vide.source("1" :: ItemId)

	return BaseMenu.Root({
		size = controls.size,
		onActivated = function(id: ItemId)
			selectedItem(id)
		end,
		items = function(): BaseMenuItems
			local icon: string? = if controls.hasIcon() then controls.icon() else nil
			local selected = selectedItem()
			local items: { BaseMenuItem } = {
				{ id = "1", icon = icon, isChecked = selected == "1", isDisabled = false, text = "Item 1" },
				{
					id = "2",
					icon = icon,
					isChecked = selected == "2",
					isDisabled = false,
					text = "Item with a longer label",
				},
				{ id = "3", icon = icon, isChecked = selected == "3", isDisabled = true, text = "Item 3" },
			}
			return items
		end,
	})
end

local function MultiSelectStory(controls: { [string]: any })
	local items = Vide.source({
		{ id = "1", icon = IconName.Robux, text = "Item 1" },
		{ id = "2", icon = IconName.Robux, text = "Item 2" },
		{ id = "3", icon = IconName.Robux, text = "Item 3" },
	} :: { BaseMenuItem })

	return BaseMenu.Root({
		size = controls.size,
		items = items,
		onActivated = function(id: ItemId)
			local updated = {}
			for index, item in Vide.untrack(items) do
				local copy = table.clone(item)
				if copy.id == id then
					copy.isChecked = not copy.isChecked
				end
				updated[index] = copy
			end
			items(updated)
		end,
	})
end

local ACTION_ITEMS: { BaseMenuItem } = {
	{ id = "1", icon = IconName.Robux, text = "Item 1" },
	{ id = "2", icon = IconName.Robux, text = "Item 2" },
	{ id = "3", icon = IconName.Robux, text = "Item 3" },
}

local function ActionsMenuStory(controls: { [string]: any })
	return BaseMenu.Root({
		size = controls.size,
		onActivated = function(itemId: ItemId)
			print("Clicked item: " .. tostring(itemId))
		end,
		items = ACTION_ITEMS,
	})
end

--* React keys these menus by size name, so they render in that keyed table's order, not the enum's.
local ALL_SIZES_ORDER: { InputSize } = { InputSize.Small, InputSize.XSmall, InputSize.Medium, InputSize.Large }

local function AllSizesStory()
	local menus = {}
	for index, size in ALL_SIZES_ORDER do
		menus[index] = BaseMenu.Root({
			size = size,
			items = BASE_ITEMS,
			onActivated = noop,
			LayoutOrder = index,
		})
	end
	return VF.View({
		tag = "row wrap gap-xxlarge size-full-0 auto-y",
		children = menus,
	})
end

local function FixedWidthStory()
	return BaseMenu.Root({ width = UDim.new(0, 300), items = BASE_ITEMS, onActivated = noop })
end

local function FullWidthStory()
	return BaseMenu.Root({ width = UDim.new(1, 0), items = BASE_ITEMS, onActivated = noop })
end

local function GroupedStory(controls: { [string]: any })
	return BaseMenu.Root({
		size = controls.size,
		items = {
			{
				title = "First Title",
				items = {
					{ id = "a1", icon = IconName.Robux, text = "Alpha 1" },
					{ id = "a2", text = "Alpha 2" },
				},
			},
			{
				title = "Second Title",
				items = {
					{ id = "b1", text = "Beta 1" },
					{ id = "b2", isDisabled = true, text = "Beta 2 (disabled)" },
				},
			},
			{
				items = {
					{ id = "c1", text = "Untitled group item" },
				},
			},
		} :: any,
		onActivated = noop,
	})
end

local function CompositesStory(controls: { [string]: any })
	return BaseMenu.Root({
		size = controls.size,
		onActivated = function(id: ItemId)
			print(`Clicked {id}`)
		end,
		children = function()
			return {
				BaseMenu.Group({
					LayoutOrder = 1,
					title = "Test title",
					children = {
						BaseMenu.Item({ LayoutOrder = 1, id = "a1", text = "Text 1", icon = IconName.Robux }),
						BaseMenu.Item({ LayoutOrder = 2, id = "a2", text = "Text 2" }),
						BaseMenu.Item({ LayoutOrder = 3, id = "a3", text = "Text 3" }),
					},
				}),
				BaseMenu.Group({
					LayoutOrder = 2,
					children = {
						BaseMenu.Item({ LayoutOrder = 1, id = "b1", text = "Text 11" }),
						BaseMenu.Item({ LayoutOrder = 2, id = "b2", text = "Text 22" }),
						BaseMenu.Item({ LayoutOrder = 3, id = "b3", text = "Text 33" }),
					},
				}),
			}
		end,
	})
end

local function OverflowStory(controls: { [string]: any })
	local items: { BaseMenuItem } = {}
	for i = 1, 100 do
		table.insert(items, {
			id = tostring(i),
			icon = IconName.Robux,
			text = "Item " .. tostring(i),
			isChecked = i % 3 == 0,
			isDisabled = i % 7 == 0,
		})
	end
	return BaseMenu.Root({
		size = controls.size,
		items = items,
		maxHeight = 500,
		onActivated = noop,
	})
end

local function ScrollToSelectionStory(controls: { [string]: any })
	local selectedId = Vide.source("18" :: ItemId)

	local items = Vide.derive(function(): { BaseMenuItem }
		local selected = selectedId()
		local list: { BaseMenuItem } = {}
		for index = 1, SCROLL_TO_SELECTION_ITEM_COUNT do
			local id = tostring(index)
			table.insert(list, { id = id, text = `Item {index}`, isChecked = selected == id })
		end
		return list
	end)

	return BaseMenu.Root({
		size = controls.size,
		items = items,
		maxHeight = SCROLL_TO_SELECTION_MAX_HEIGHT,
		scrollingFrameRef = scrollToSelected(items, selectedId),
		onActivated = function(id: ItemId)
			selectedId(id)
		end,
	})
end

local function DynamicallySizingStory()
	local searchContent = Vide.source("")

	return VF.View({
		tag = "col gap-large auto-xy",
		children = {
			VF.TextInput({
				onChanged = function(text: string)
					searchContent(text)
				end,
				label = "Search",
				text = searchContent,
				LayoutOrder = 1,
			}),
			BaseMenu.Root({
				width = UDim.new(0, 260),
				items = function(): BaseMenuItems
					local search = searchContent()
					local matches = Dash.filter(IconName :: any, function(icon: string)
						return string.find(icon, search, nil, true) ~= nil
					end)
					return Dash.map(matches, function(icon: string): BaseMenuItem
						return { id = icon, icon = icon, text = icon }
					end)
				end,
				maxHeight = 600,
				LayoutOrder = 2,
			}),
		},
	})
end

local function ExperienceIconsStory(controls: { [string]: any })
	local selectedItem = Vide.source(EXPERIENCE_DATA[1].name :: ItemId)

	return BaseMenu.Root({
		size = controls.size,
		onActivated = function(id: ItemId)
			selectedItem(id)
		end,
		items = function(): BaseMenuItems
			local selected = selectedItem()
			local items: { BaseMenuItem } = {}
			for _, experience in EXPERIENCE_DATA do
				table.insert(items, {
					id = experience.name,
					icon = getRbxThumb(ThumbnailType.GameIcon, experience.universeId),
					isChecked = selected == experience.name,
					text = experience.name,
				})
			end
			return items
		end,
	})
end

return foundation.sections({
	summary = "BaseMenu",
	controls = {
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		icon = UILabs.Choose(exampleIcons),
		hasIcon = true,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Multi select", story = MultiSelectStory },
		{ name = "Actions menu", story = ActionsMenuStory },
		{ name = "All Sizes", story = AllSizesStory },
		{ name = "Fixed width", story = FixedWidthStory },
		{ name = "Full width", story = FullWidthStory },
		{ name = "Grouped", story = GroupedStory },
		{ name = "Composites", story = CompositesStory },
		{ name = "Overflow", story = OverflowStory },
		{
			name = "Scroll-to-selection",
			summary = "Use scrollingFrameRef to scroll the menu to the selected item.",
			story = ScrollToSelectionStory,
		},
		{ name = "Dynamically Sizing", story = DynamicallySizingStory },
		{ name = "Experience Icons", story = ExperienceIconsStory },
	},
})
