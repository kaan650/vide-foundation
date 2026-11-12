local foundation = require("../foundation")
local MatrixGrid = require("../Shared/MatrixGrid")
local StoryIcons = require("../Shared/StoryIcons")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local BuilderIcons = require("@game/ReplicatedStorage/Packages/VideFoundation/Packages/BuilderIcons")
local Breadcrumb = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Breadcrumb")

local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")

type BreadcrumbItem = Breadcrumb.BreadcrumbItem
type InputSize = InputSize.InputSize
type MenuItem = VideFoundation.MenuItem

local IconName = VF.Enums.IconName

local SIZES: { InputSize } = { InputSize.Small, InputSize.Medium, InputSize.Large }
local AVATAR_USER_ID = 24813339
local IMAGE_ACCESSORY = StoryIcons.ICON_TYPE_EXAMPLES[3].name

local TRAIL = {
	"Home",
	"Games",
	"Strategy",
	"Tower Defense",
	"Tower Defense Simulator",
	"Servers",
	"Private server",
	"Settings",
}

local SIBLING_PAGES: { MenuItem } = {
	{ id = "tds", text = "Tower Defense Simulator" },
	{ id = "toilet", text = "Toilet Tower Defense" },
	{ id = "anime", text = "Anime Defenders" },
}

local function navigate(text: string)
	return foundation.action(`Navigate to {text}`)
end

--- The first `count` crumbs of TRAIL; every crumb but the last navigates.
local function trail(count: number, hasLeading: boolean?): { BreadcrumbItem }
	local items: { BreadcrumbItem } = {}
	for index = 1, math.clamp(count, 1, #TRAIL) do
		local text = TRAIL[index]
		items[index] = {
			text = text,
			onActivated = navigate(text),
			leading = if hasLeading and index == 1 then IconName.House else nil,
		}
	end
	items[#items].onActivated = nil
	return items
end

local function PlaygroundStory(controls: { [string]: any })
	--* onDropdownActivated is a plain callback, so turning the dropdown on or off builds the breadcrumb again.
	return foundation.rebuildOn(controls.hasDropdown, function(hasDropdown: boolean)
		return Breadcrumb({
			size = controls.size,
			items = function()
				return trail(controls.itemCount(), controls.hasLeading())
			end,
			onDropdownActivated = if hasDropdown then foundation.action("Dropdown activated") else nil,
		})
	end)
end

local function UsageStory()
	return Breadcrumb({
		size = InputSize.Medium,
		items = {
			{ text = "Home", onActivated = navigate("Home"), leading = IconName.House },
			{ text = "Games", onActivated = navigate("Games") },
			{ text = "Tower Defense Simulator" },
		},
	})
end

local function SizesStory()
	local rows: { MatrixGrid.MatrixGridRow } = {}
	for index, size in SIZES do
		rows[index] = {
			label = MatrixGrid.matrixLabel(size),
			cells = {
				Breadcrumb({ size = size, items = trail(3, true) }),
			},
		}
	end
	return MatrixGrid.MatrixGrid({
		labelColumnWidth = 80,
		columnHeaders = { "Breadcrumb" },
		cellColumnWidth = 420,
		cellAlign = "left",
		rows = rows,
	})
end

local function AccessoriesStory()
	local examples: { { label: string, leading: any } } = {
		{ label = "Icon name", leading = IconName.House },
		{
			label = "Icon config",
			leading = { iconName = IconName.House, iconVariant = BuilderIcons.IconVariant.Filled },
		},
		{ label = "Avatar", leading = { type = "Avatar", userId = AVATAR_USER_ID } },
		{ label = "Image", leading = IMAGE_ACCESSORY },
	}

	local rows: { MatrixGrid.MatrixGridRow } = {}
	for index, example in examples do
		rows[index] = {
			label = MatrixGrid.matrixLabel(example.label),
			cells = {
				Breadcrumb({
					items = {
						{ text = "Home", onActivated = navigate("Home"), leading = example.leading },
						{ text = "Groups", onActivated = navigate("Groups"), leading = example.leading },
						{ text = "Builders Club", leading = example.leading },
					},
				}),
			},
		}
	end
	return MatrixGrid.MatrixGrid({
		labelColumnWidth = 100,
		columnHeaders = { "Leading" },
		cellColumnWidth = 420,
		cellAlign = "left",
		rows = rows,
	})
end

local function CollapsingStory()
	return VF.View({
		tag = "col gap-large auto-xy",
		children = {
			VF.Text({
				Text = "Four crumbs stay expanded",
				tag = "auto-xy text-caption-small content-default",
				LayoutOrder = 1,
			}),
			Breadcrumb({ items = trail(4), LayoutOrder = 2 }),
			VF.Text({
				Text = "Six crumbs collapse into an overflow menu",
				tag = "auto-xy text-caption-small content-default",
				LayoutOrder = 3,
			}),
			Breadcrumb({ items = trail(6), LayoutOrder = 4 }),
		},
	})
end

local function DropdownStory()
	local current = Vide.source(nil :: GuiObject?)
	local isOpen = Vide.source(false)

	return {
		Breadcrumb({
			items = {
				{ text = "Home", onActivated = navigate("Home") },
				{ text = "Games", onActivated = navigate("Games") },
				{
					text = "Tower Defense Simulator",
					ref = function(instance: GuiObject?)
						current(instance)
					end,
				},
			},
			onDropdownActivated = function()
				isOpen(not isOpen())
			end,
		}),
		VF.Menu({
			isOpen = isOpen,
			anchorRef = current :: any,
			items = SIBLING_PAGES,
			onPressedOutside = function()
				isOpen(false)
			end,
			onActivated = function()
				isOpen(false)
			end,
		}),
	}
end

return foundation.sections({
	summary = "Breadcrumbs are a list of links that help a user visualize a page's location within the hierarchical structure of an experience, and let them navigate up to any of its ancestors.",
	controls = {
		size = UILabs.Choose({ InputSize.Medium, InputSize.Small, InputSize.Large }),
		itemCount = 3,
		hasLeading = true,
		hasDropdown = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Usage", story = UsageStory },
		{ name = "Sizes", story = SizesStory },
		{
			name = "Leading accessories",
			summary = "An icon name, an icon config with a variant, an avatar or an image.",
			story = AccessoriesStory,
		},
		{
			name = "Collapsing",
			summary = "Trails of more than four crumbs keep the first crumb and the current page, and collapse the rest into an overflow menu.",
			story = CollapsingStory,
		},
		{
			name = "Dropdown",
			summary = "The current crumb shows a chevron and opens a menu of sibling pages anchored to it.",
			story = DropdownStory,
		},
	},
})
