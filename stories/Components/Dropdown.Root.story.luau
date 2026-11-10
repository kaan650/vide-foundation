local foundation = require("../foundation")
local scrollToSelected = require("../Shared/ScrollToSelected")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local BadgeVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/BadgeVariant")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local InputVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputVariant")
local Types = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Types")

type DropdownItem = VideFoundation.DropdownItem
type DropdownItems = VideFoundation.DropdownItems
type BadgeVariant = BadgeVariant.BadgeVariant
type InputSize = InputSize.InputSize
type InputVariant = InputVariant.InputVariant
type ItemId = Types.ItemId
type Value<T> = VideFoundation.Value<T>

local IconName = VF.Enums.IconName

local LEADING_ICON_PALETTE = {
	IconName.Pencil,
	IconName.ClipboardPencil,
	IconName.TextBBold,
	IconName.PaperAirplane,
	IconName.TwoStackedSquares,
	IconName.TrashCan,
}

local HINT_PALETTE = { "\u{2318}B", "\u{2318}I", "\u{2318}C", "\u{2318}V", "\u{2318}S", "\u{2318}Z" }

local BADGE_PALETTE: { { text: string, variant: BadgeVariant } } = {
	{ text = "New", variant = BadgeVariant.Success },
	{ text = "Beta", variant = BadgeVariant.Warning },
	{ text = "Pro", variant = BadgeVariant.Contrast },
	{ text = "Soon", variant = BadgeVariant.Neutral },
}

local AVATAR_USER_ID = 24813339

local SHOWCASE_WIDTH = UDim.new(0, 220)
local SCROLL_TO_SELECTION_MAX_HEIGHT = 120
local SCROLL_TO_SELECTION_ITEM_COUNT = 20

local function leadingFor(mode: string?, index: number): any
	if mode == nil or mode == "None" then
		return nil
	end
	if mode == "Avatar" then
		return { type = "Avatar", userId = AVATAR_USER_ID }
	end
	if mode == "Mixed" then
		local r = (index - 1) % 3
		if r == 1 then
			return { type = "Avatar", userId = AVATAR_USER_ID }
		elseif r == 2 then
			return nil
		end
	end
	return LEADING_ICON_PALETTE[((index - 1) % #LEADING_ICON_PALETTE) + 1]
end

local function trailingFor(mode: string?, index: number): any
	if mode == nil or mode == "None" then
		return nil
	end
	if mode == "Hint" or (mode == "Mixed" and index % 2 == 1) then
		return { type = "Hint", text = HINT_PALETTE[((index - 1) % #HINT_PALETTE) + 1] }
	end
	local badge = BADGE_PALETTE[((index - 1) % #BADGE_PALETTE) + 1]
	return { type = "Badge", text = badge.text, variant = badge.variant }
end

local function getItems(hasIcon: boolean?): { DropdownItem }
	local icon = if hasIcon then IconName.ShieldCheck else nil
	return {
		{ id = "A", text = "Item A", icon = icon },
		{ id = "B", text = "Item B", isDisabled = true },
		{ id = "G", text = "Long text item that should be truncated in the dropdown menu" },
		{ id = "C", text = "Item C", icon = icon },
	}
end

type DemoDropdownProps = {
	label: Value<string>,
	size: Value<InputSize>?,
	variant: Value<InputVariant>?,
	isDisabled: Value<boolean?>?,
	hasError: Value<boolean?>?,
	hasIcon: boolean?,
	placeholder: Value<string?>?,
	hint: Value<string?>?,
	items: Value<DropdownItems>?,
	width: Value<UDim>?,
	maxHeight: number?,
	value: ItemId?,
}

--- A Dropdown that keeps its own selection, used by every showcase.
local function DemoDropdown(props: DemoDropdownProps)
	local id = Vide.source(props.value)
	local getId: () -> ItemId? = id :: any

	return VF.Dropdown.Root({
		value = getId,
		placeholder = props.placeholder,
		onItemChanged = function(itemId: ItemId)
			id(itemId)
		end,
		hasError = props.hasError,
		isDisabled = props.isDisabled,
		items = props.items or getItems(props.hasIcon),
		size = props.size,
		variant = props.variant,
		label = props.label,
		hint = props.hint,
		width = props.width,
		maxHeight = props.maxHeight,
	})
end

local function Section(label: string, layoutOrder: number, containerTag: string, children: any)
	return VF.View({
		tag = "col gap-xsmall " .. containerTag,
		LayoutOrder = layoutOrder,
		children = {
			VF.Text({
				Text = label,
				tag = "auto-xy text-label-medium content-muted",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = containerTag,
				LayoutOrder = 2,
				children = children,
			}),
		},
	})
end

local function Column(children: any)
	return VF.View({
		tag = "col gap-xlarge size-full-0 auto-y",
		children = children,
	})
end

local PLAYGROUND_TEXTS = { "Action one", "Action two", "Action three", "Other one", "Other two", "Other three" }

local function PlaygroundStory(controls: { [string]: any })
	return DemoDropdown({
		label = controls.label,
		size = controls.size,
		variant = controls.variant,
		isDisabled = controls.isDisabled,
		hasError = controls.hasError,
		placeholder = function(): string?
			return if controls.hasPlaceholder() then controls.placeholder() else nil
		end,
		hint = function(): string?
			return if controls.hasHint() then controls.hint() else nil
		end,
		width = function()
			return UDim.new(0, controls.width())
		end,
		items = function(): DropdownItems
			local leadingMode: string = controls.leading()
			local trailingMode: string = controls.trailing()
			local built: { DropdownItem } = {}
			for index, text in PLAYGROUND_TEXTS do
				table.insert(built, {
					id = `item-{index}`,
					text = text,
					leading = leadingFor(leadingMode, index),
					trailing = trailingFor(trailingMode, index),
					isDisabled = index == 5,
				})
			end
			return built
		end,
	})
end

local function SizesStory()
	local sections = {}
	for index, size in { InputSize.Large, InputSize.Medium, InputSize.Small, InputSize.XSmall } :: { InputSize } do
		sections[index] = Section(
			size,
			index,
			"auto-xy",
			DemoDropdown({
				label = "Label",
				size = size,
				placeholder = "Select an option",
				width = SHOWCASE_WIDTH,
			})
		)
	end
	return Column(sections)
end

local function VariantsStory()
	local sections = {}
	for index, variant in { InputVariant.Standard, InputVariant.Contrast, InputVariant.Utility } :: { InputVariant } do
		sections[index] = Section(
			variant,
			index,
			"auto-xy",
			DemoDropdown({
				label = "Label",
				variant = variant,
				placeholder = "Select an option",
				width = SHOWCASE_WIDTH,
			})
		)
	end
	return Column(sections)
end

local function StatesStory()
	return Column({
		Section(
			"Default",
			1,
			"auto-xy",
			DemoDropdown({ label = "Label", placeholder = "Select an option", width = SHOWCASE_WIDTH })
		),
		Section(
			"With hint",
			2,
			"auto-xy",
			DemoDropdown({
				label = "Label",
				placeholder = "Select an option",
				hint = "Pick wisely",
				width = SHOWCASE_WIDTH,
			})
		),
		Section(
			"Disabled",
			3,
			"auto-xy",
			DemoDropdown({
				label = "Label",
				placeholder = "Select an option",
				isDisabled = true,
				width = SHOWCASE_WIDTH,
			})
		),
		Section(
			"Error",
			4,
			"auto-xy",
			DemoDropdown({
				label = "Label",
				placeholder = "Select an option",
				hasError = true,
				hint = "This field is required",
				width = SHOWCASE_WIDTH,
			})
		),
	})
end

local NARROW_ITEMS: { DropdownItem } = {
	{ id = "A", text = "Item A" },
	{ id = "B", text = "Item B", isDisabled = true },
}

local function WidthsStory()
	return Column({
		Section(
			"Narrow dropdown — narrow items",
			1,
			"auto-xy",
			DemoDropdown({
				label = "Label",
				placeholder = "Pick one",
				width = UDim.new(0, 150),
				items = NARROW_ITEMS,
			})
		),
		Section(
			"Narrow dropdown — wide items (truncate)",
			2,
			"auto-xy",
			DemoDropdown({ label = "Label", placeholder = "Pick one", width = UDim.new(0, 150) })
		),
		Section(
			"Fill width — narrow items",
			3,
			"size-full-0 auto-y",
			DemoDropdown({
				label = "Label",
				placeholder = "Pick one",
				width = UDim.new(1, 0),
				items = NARROW_ITEMS,
			})
		),
	})
end

local function ItemGroupsStory()
	return DemoDropdown({
		label = "With item groups",
		placeholder = "Select an option",
		width = SHOWCASE_WIDTH,
		items = {
			{
				title = "First title",
				items = {
					{ id = "a1", icon = IconName.Robux, text = "Alpha 1" },
					{ id = "a2", text = "Alpha 2" },
				},
			},
			{
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
	})
end

local function OverflowStory()
	local items: { DropdownItem } = {}
	for i = 1, 100 do
		local itemId = tostring(i)
		table.insert(items, {
			id = itemId,
			icon = IconName.Robux,
			text = `Item {itemId}`,
			isDisabled = i % 7 == 0,
		})
	end

	return DemoDropdown({
		label = "Overflow",
		placeholder = "Choose a value",
		width = SHOWCASE_WIDTH,
		maxHeight = 500,
		items = items,
	})
end

local function ScrollToSelectionStory()
	local items: { DropdownItem } = {}
	for index = 1, SCROLL_TO_SELECTION_ITEM_COUNT do
		table.insert(items, { id = `item-{index}`, text = `Item {index}` })
	end

	local value = Vide.source("item-18" :: ItemId)

	return VF.Dropdown.Root({
		label = "Year",
		placeholder = "Choose a year",
		width = SHOWCASE_WIDTH,
		maxHeight = SCROLL_TO_SELECTION_MAX_HEIGHT,
		value = value,
		onItemChanged = function(id: ItemId)
			value(id)
		end,
		items = items,
		scrollingFrameRef = scrollToSelected(function()
			return items
		end, value),
	})
end

local function LeadingAccessoriesStory()
	local iconItems: { DropdownItem } = {
		{ id = "edit", text = "Edit", leading = IconName.Pencil },
		{ id = "share", text = "Share", leading = IconName.PaperAirplane },
		{ id = "copy", text = "Duplicate", leading = IconName.TwoStackedSquares },
		{ id = "delete", text = "Delete", leading = IconName.TrashCan },
	}
	local avatarItems: { DropdownItem } = {
		{ id = "u1", text = "Builderman", leading = { type = "Avatar", userId = 156 } },
		{ id = "u2", text = "User", leading = { type = "Avatar", userId = AVATAR_USER_ID } },
		{ id = "u3", text = "Roblox", leading = { type = "Avatar", userId = 1 } },
	}
	local mixedItems: { DropdownItem } = {
		{ id = "i1", text = "Settings", leading = IconName.Pencil },
		{ id = "i2", text = "Profile", leading = { type = "Avatar", userId = AVATAR_USER_ID } },
		{ id = "i3", text = "No leading" },
		{ id = "i4", text = "Trash", leading = IconName.TrashCan },
	}

	return Column({
		Section(
			"Icon leading",
			1,
			"auto-xy",
			DemoDropdown({
				label = "Action",
				placeholder = "Pick an action",
				width = SHOWCASE_WIDTH,
				items = iconItems,
			})
		),
		Section(
			"Avatar leading",
			2,
			"auto-xy",
			DemoDropdown({
				label = "Member",
				placeholder = "Pick a member",
				width = SHOWCASE_WIDTH,
				items = avatarItems,
			})
		),
		Section(
			"Mixed leading (some items have none)",
			3,
			"auto-xy",
			DemoDropdown({
				label = "Sample",
				placeholder = "Pick one",
				width = SHOWCASE_WIDTH,
				items = mixedItems,
			})
		),
	})
end

local function TrailingAccessoriesStory()
	local hintItems: { DropdownItem } = {
		{ id = "b", text = "Bold", trailing = { type = "Hint", text = "\u{2318}B" } },
		{ id = "i", text = "Italic", trailing = { type = "Hint", text = "\u{2318}I" } },
		{ id = "u", text = "Underline", trailing = { type = "Hint", text = "\u{2318}U" } },
	}
	local badgeItems: { DropdownItem } = {
		{
			id = "new",
			text = "New feature",
			trailing = { type = "Badge", text = "New", variant = BadgeVariant.Success },
		},
		{
			id = "beta",
			text = "Beta channel",
			trailing = { type = "Badge", text = "Beta", variant = BadgeVariant.Warning },
		},
		{
			id = "pro",
			text = "Pro mode",
			trailing = { type = "Badge", text = "Pro", variant = BadgeVariant.Contrast },
		},
	}
	local mixedItems: { DropdownItem } = {
		{ id = "save", text = "Save", trailing = { type = "Hint", text = "\u{2318}S" } },
		{
			id = "publish",
			text = "Publish",
			trailing = { type = "Badge", text = "New", variant = BadgeVariant.Success },
		},
		{ id = "plain", text = "Plain item" },
	}

	return Column({
		Section(
			"Hint trailing",
			1,
			"auto-xy",
			DemoDropdown({
				label = "Format",
				placeholder = "Pick a style",
				width = SHOWCASE_WIDTH,
				items = hintItems,
			})
		),
		Section(
			"Badge trailing",
			2,
			"auto-xy",
			DemoDropdown({
				label = "Channel",
				placeholder = "Pick a channel",
				width = SHOWCASE_WIDTH,
				items = badgeItems,
			})
		),
		Section(
			"Mixed trailing",
			3,
			"auto-xy",
			DemoDropdown({
				label = "Action",
				placeholder = "Pick an action",
				width = SHOWCASE_WIDTH,
				items = mixedItems,
			})
		),
	})
end

local function CheckColumnStory()
	--* The selected item gets a check, and every other row keeps the check column so titles stay aligned. The two
	--* dropdowns differ only in their selected value.
	local items: { DropdownItem } = {
		{ id = "low", text = "Low quality", leading = IconName.Pencil },
		{ id = "med", text = "Medium quality", leading = IconName.PaperAirplane },
		{ id = "high", text = "High quality", leading = IconName.ClipboardPencil },
	}
	local function noop() end

	return Column({
		Section(
			"Pre-selected (check + leading both visible)",
			1,
			"auto-xy",
			VF.Dropdown.Root({
				value = "med",
				onItemChanged = noop,
				items = items,
				label = "Quality",
				width = SHOWCASE_WIDTH,
			})
		),
		Section(
			"Unselected (no check column reserved)",
			2,
			"auto-xy",
			VF.Dropdown.Root({
				onItemChanged = noop,
				items = items,
				label = "Quality",
				placeholder = "Pick a quality",
				width = SHOWCASE_WIDTH,
			})
		),
	})
end

return foundation.sections({
	summary = "Dropdown",
	controls = {
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		variant = UILabs.Choose(Dash.values(InputVariant :: any)),
		isDisabled = false,
		hasError = false,
		hasPlaceholder = false,
		hasHint = false,
		label = "Dropdown Label",
		placeholder = "Choose an option",
		hint = "Optional hint text",
		width = 400,
		leading = UILabs.Choose({ "Icon", "Avatar", "Mixed", "None" }),
		trailing = UILabs.Choose({ "Hint", "Badge", "Mixed", "None" }),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizes", story = SizesStory },
		{ name = "Variants", story = VariantsStory },
		{ name = "States", story = StatesStory },
		{ name = "Widths", story = WidthsStory },
		{ name = "Item groups", story = ItemGroupsStory },
		{ name = "Overflow", story = OverflowStory },
		{ name = "Scroll-to-selection", story = ScrollToSelectionStory },
		{ name = "Leading accessories", story = LeadingAccessoriesStory },
		{ name = "Trailing accessories", story = TrailingAccessoriesStory },
		{ name = "Check column", story = CheckColumnStory },
	},
})
