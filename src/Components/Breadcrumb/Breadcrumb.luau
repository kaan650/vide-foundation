local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
local IconName = BuilderIcons.Icon

local ButtonVariant = require("../../Enums/ButtonVariant")

local InputSize = require("../../Enums/InputSize")
type InputSize = InputSize.InputSize

local LinkVariant = require("../../Enums/LinkVariant")

local Icon = require("../Icon")
local IconButton = require("../IconButton")
local Link = require("../Link")
local Menu = require("../Menu")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
type MenuItem = Menu.MenuItem

local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local BreadcrumbAccessory = require("./BreadcrumbAccessory")
type BreadcrumbAccessory = BreadcrumbAccessory.BreadcrumbAccessory

local useBreadcrumbVariants = require("./useBreadcrumbVariants")
type BreadcrumbVariantProps = useBreadcrumbVariants.BreadcrumbVariantProps
local useTokens = require("../../Providers/Style/useTokens")

type Value<T> = Types.Value<T>

local MAX_ITEMS = 4
local SEPARATOR = "/"

export type BreadcrumbItem = {
	-- Label shown for this crumb.
	text: string,
	-- Called when an ancestor crumb is activated. Omitted crumbs, including the current page, render as non-interactive text.
	onActivated: (() -> ())?,
	-- Accessory rendered before the crumb text: a BuilderIcons name, an icon config, an avatar, or an image.
	leading: (string | BreadcrumbAccessory)?,
	-- Receives the crumb so a menu or tooltip can anchor to it, and nil when the crumb goes away. Not called while the
	-- crumb is collapsed into the overflow menu.
	ref: ((GuiObject?) -> ())?,
	-- Identifier for this crumb. Defaults to `{breadcrumb testId}--item-{index}`.
	testId: string?,

	-- **DEPRECATED**: Accessories are leading-only. Use `leading` instead. Still accepted but ignored.
	trailing: (string | BreadcrumbAccessory)?,
}

export type BreadcrumbProps = {
	-- Ordered crumbs from the top-most ancestor to the current page.
	items: Value<{ BreadcrumbItem }>,
	-- Size of every crumb and separator. Defaults to `InputSize.Medium`.
	size: Value<InputSize>?,
	-- When set, the current crumb shows a dropdown chevron and calls this on activation.
	onDropdownActivated: (() -> ())?,

	-- **DEPRECATED**: The separator is always `/`. Still accepted but ignored.
	separator: string?,
	-- **DEPRECATED**: Trails longer than four crumbs collapse automatically. Still accepted but ignored.
	maxItems: number?,
	-- **DEPRECATED**: Collapse always keeps the first crumb visible. Still accepted but ignored.
	itemsBeforeCollapse: number?,
	-- **DEPRECATED**: Collapse always keeps the current page visible. Still accepted but ignored.
	itemsAfterCollapse: number?,
} & Types.CommonProps

type Entry = { item: BreadcrumbItem?, index: number?, overflow: boolean? }

type State = {
	items: { BreadcrumbItem },
	size: InputSize,
	variantProps: BreadcrumbVariantProps,
}

local defaultProps = {
	size = InputSize.Medium,
	testId = "--foundation-breadcrumb",
}

type BreadcrumbItemProps = {
	item: BreadcrumbItem,
	isCurrent: boolean,
	hasDropdown: boolean,
	onDropdownActivated: (() -> ())?,
	size: InputSize,
	variantProps: BreadcrumbVariantProps,
	LayoutOrder: number,
	testId: string,
}

local function BreadcrumbItem(props: BreadcrumbItemProps): GuiObject
	local item = props.item
	local variantProps = props.variantProps
	local testId = props.testId

	local text: GuiObject
	if props.isCurrent or item.onActivated == nil then
		text = Text({
			Text = item.text,
			tag = if props.isCurrent then variantProps.current.tag else variantProps.label.tag,
			LayoutOrder = 1,
			testId = `{testId}--text`,
		})
	else
		text = Link({
			text = item.text,
			onActivated = item.onActivated :: () -> (),
			variant = LinkVariant.Standard,
			size = props.size,
			hasUnderline = false,
			LayoutOrder = 1,
			testId = `{testId}--link`,
		})
	end
	text.Name = "Text"

	local chevron: GuiObject? = nil
	if props.hasDropdown then
		chevron = Icon({
			name = IconName.ChevronLargeDown,
			size = variantProps.accessory.iconSize,
			style = variantProps.accessory.style,
			LayoutOrder = 2,
			testId = `{testId}--chevron`,
		})
		chevron.Name = "Chevron"
	end

	local itemText = View({
		tag = variantProps.itemText.tag,
		LayoutOrder = 2,
		children = { text, chevron },
	})
	itemText.Name = "ItemText"

	local leading: GuiObject? = nil
	if item.leading ~= nil then
		leading = BreadcrumbAccessory({
			config = item.leading,
			variant = variantProps.accessory,
			LayoutOrder = 1,
			testId = `{testId}--leading`,
		})
		leading.Name = "Leading"
	end

	local onDropdownActivated = props.onDropdownActivated
	local crumb = View({
		tag = variantProps.item.tag,
		onActivated = if props.hasDropdown and onDropdownActivated
			then function()
				onDropdownActivated()
			end
			else nil,
		LayoutOrder = props.LayoutOrder,
		testId = testId,
		children = { leading, itemText },
	})

	local ref = item.ref
	if ref then
		ref(crumb)
		Vide.cleanup(function()
			ref(nil)
		end)
	end

	return crumb
end

--- A trail of links from the top-most ancestor to the current page, separated by slashes. Trails of more than four
--- crumbs keep the first and the current one and collapse the rest into an overflow menu.
local function Breadcrumb(breadcrumbProps: BreadcrumbProps): GuiObject
	local props = withDefaults(breadcrumbProps, defaultProps)
	local tokens = useTokens()
	local testId = props.testId

	local state = Vide.derive(function(): State
		local size: InputSize = Value.read(props.size)
		return {
			items = Value.read(props.items :: Value<{ BreadcrumbItem }>),
			size = size,
			variantProps = useBreadcrumbVariants(tokens(), size),
		}
	end)

	local isCollapsed = Vide.derive(function()
		return #state().items > MAX_ITEMS
	end)
	local isMenuOpen = Vide.source(false)

	Vide.effect(function()
		if not isCollapsed() then
			isMenuOpen(false)
		end
	end)

	local function toggleMenu()
		isMenuOpen(not Vide.untrack(isMenuOpen))
	end
	local function closeMenu()
		isMenuOpen(false)
	end

	local function onMenuItemActivated(id: Types.ItemId)
		isMenuOpen(false)
		local item = Vide.untrack(state).items[id :: number]
		if item and item.onActivated then
			item.onActivated()
		end
	end

	--* Crumbs are built again when the items, size or tokens change, as React re-renders them with new props.
	local function buildChildren(current: State): { any }
		local items = current.items
		local variantProps = current.variantProps
		local count = #items
		local collapsed = count > MAX_ITEMS

		local entries: { Entry } = {}
		if collapsed then
			entries = {
				{ item = items[1], index = 1 },
				{ overflow = true },
				{ item = items[count], index = count },
			}
		else
			for index, item in items do
				table.insert(entries, { item = item, index = index })
			end
		end

		local children: { any } = {}
		local overflow: GuiObject? = nil
		for i, entry in entries do
			if entry.overflow then
				overflow = IconButton({
					icon = IconName.ThreeDotsHorizontal,
					onActivated = toggleMenu,
					size = variantProps.overflow.size,
					variant = ButtonVariant.Standard,
					LayoutOrder = 2 * i - 1,
					testId = `{testId}--overflow`,
				}) :: GuiObject
				table.insert(children, named("Overflow", overflow))
			else
				local item = entry.item :: BreadcrumbItem
				local index = entry.index :: number
				local isCurrent = index == count
				table.insert(
					children,
					named(
						`Item{index}`,
						BreadcrumbItem({
							item = item,
							isCurrent = isCurrent,
							hasDropdown = isCurrent and props.onDropdownActivated ~= nil,
							onDropdownActivated = if isCurrent then props.onDropdownActivated else nil,
							size = current.size,
							variantProps = variantProps,
							LayoutOrder = 2 * i - 1,
							testId = item.testId or `{testId}--item-{index}`,
						})
					)
				)
			end

			if i ~= #entries then
				local separatorKey = if entry.overflow then "overflow" else entry.index
				local slash = Text({
					Text = SEPARATOR,
					tag = variantProps.separator.textTag,
					LayoutOrder = 1,
					testId = `{testId}--separator-{separatorKey}--text`,
				})
				slash.Name = "Slash"
				local separator = View({
					tag = variantProps.separator.tag,
					LayoutOrder = 2 * i,
					testId = `{testId}--separator-{separatorKey}`,
					children = slash,
				})
				separator.Name = `Separator{separatorKey}`
				table.insert(children, separator)
			end
		end

		if collapsed then
			local menuItems: { MenuItem } = {}
			for index = 2, count - 1 do
				local item = items[index]
				table.insert(menuItems, {
					id = index,
					text = item.text,
					isDisabled = item.onActivated == nil,
				})
			end

			table.insert(
				children,
				Menu({
					isOpen = isMenuOpen,
					items = menuItems,
					size = current.size,
					anchorRef = overflow,
					onActivated = onMenuItemActivated,
					onPressedOutside = closeMenu,
					LayoutOrder = 2 * #entries,
					testId = `{testId}--overflow-menu`,
				})
			)
		end

		return children
	end

	return View(withCommonProps(props, {
		tag = function()
			return state().variantProps.container.tag
		end,
		children = rebuildOn(state, buildChildren :: any),
	}) :: any)
end

return Breadcrumb
