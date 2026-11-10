local Vide = require("../../Packages/Vide")

local Logger = require("../../Utility/Logger")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local named = require("../../Utility/named")

local BaseMenuContext = require("./BaseMenuContext")
local BaseMenuGroup = require("./BaseMenuGroup")
local BaseMenuItem = require("./BaseMenuItem")

type ItemId = Types.ItemId
type OnItemActivated = Types.OnItemActivated
type Value<T> = Types.Value<T>

export type LeadingAccessory = BaseMenuItem.LeadingAccessory
export type TrailingAccessory = BaseMenuItem.TrailingAccessory

export type BaseMenuItemGroup<Item> = {
	title: string?,
	items: { Item },
}

export type BaseMenuItem = {
	id: ItemId,
	icon: string?,
	leading: (string | LeadingAccessory)?,
	trailing: TrailingAccessory?,
	isDisabled: boolean?,
	isChecked: boolean?,
	text: string,
	onActivated: OnItemActivated?,
	items: { BaseMenuItem | BaseMenuItemGroup<BaseMenuItem> }?,
	-- Receives the item's instance.
	ref: ((GuiObject) -> ())?,
}

export type BaseMenuItems<Item = BaseMenuItem> = { Item } | { BaseMenuItemGroup<Item> }

type Group = BaseMenuItemGroup<BaseMenuItem>

local NO_GROUPS: { Group } = {}

--- Flat items become one untitled group. A group has `items` and no `id`; an item may have `items` for a submenu.
local function toGroups(items: BaseMenuItems?): { Group }
	if items == nil then
		return NO_GROUPS
	end
	local first = (items :: { any })[1]
	if first ~= nil and first.items ~= nil and first.id == nil then
		return items :: { Group }
	end
	return { { items = items :: { BaseMenuItem } } }
end

local function DeclarativeBaseMenuContent(props: { items: Value<BaseMenuItems?> }): any
	local context = BaseMenuContext()

	local groups = Vide.derive(function()
		return toGroups(Value.read(props.items))
	end)

	local menuHasCheck = Vide.derive(function()
		for _, group in groups() do
			for _, item in group.items do
				if item.isChecked == true then
					return true
				end
			end
		end
		return false
	end)

	local function Item(item: () -> BaseMenuItem, id: ItemId, layoutOrder: () -> number, groupHasLeading: () -> boolean)
		local function itemProps(isSubmenu: boolean): BaseMenuItem.BaseMenuItemProps
			return {
				id = id,
				LayoutOrder = layoutOrder,
				icon = function()
					return item().icon
				end,
				leading = function()
					return item().leading
				end,
				trailing = function()
					return item().trailing
				end,
				isChecked = function()
					return item().isChecked
				end,
				isDisabled = function()
					return item().isDisabled
				end,
				text = function()
					return item().text
				end,
				--* Item data can change, so its callback is looked up on activation.
				onActivated = function(itemId: ItemId)
					local callback = Vide.untrack(item).onActivated or context.onActivated
					if callback then
						callback(itemId)
					else
						Logger:warning("Menu should have either onActivated on itself or on all of its children")
					end
				end,
				testId = if isSubmenu then "--foundation-menu-submenu-item" else "--foundation-menu-item",
				ref = function(instance: GuiObject)
					local ref = Vide.untrack(item).ref
					if ref then
						ref(instance)
					end
				end,
				menuHasLeading = groupHasLeading,
				menuHasCheck = menuHasCheck,
				children = if isSubmenu
					then function()
						return DeclarativeBaseMenuContent({
							items = function()
								return item().items
							end,
						})
					end
					else nil,
			}
		end

		return Vide.switch(function()
			return item().items ~= nil
		end)({
			[true] = function()
				return BaseMenuItem(itemProps(true))
			end,
			[false] = function()
				return named(tostring(id), BaseMenuItem(itemProps(false)))
			end,
		})
	end

	return Vide.indexes(groups, function(group: () -> Group, groupIndex: number)
		local groupHasLeading = Vide.derive(function()
			for _, item in group().items do
				if item.leading ~= nil or item.icon ~= nil then
					return true
				end
			end
			return false
		end)

		--* React keys items by id, so an item keeps its instance when its data or position changes.
		local itemsById = Vide.derive(function()
			local byId: { [ItemId]: BaseMenuItem } = {}
			for _, item in group().items do
				byId[item.id] = item
			end
			return byId
		end)
		local positions = Vide.derive(function()
			local byId: { [ItemId]: number } = {}
			for index, item in group().items do
				byId[item.id] = index
			end
			return byId
		end)

		return BaseMenuGroup({
			LayoutOrder = groupIndex,
			title = function()
				return group().title
			end,
			menuHasLeading = groupHasLeading,
			menuHasCheck = menuHasCheck,
			children = Vide.indexes(itemsById, function(item: () -> BaseMenuItem, id: ItemId)
				return Item(item, id, function()
					return positions()[id] or 0
				end, groupHasLeading)
			end),
		})
	end)
end

return DeclarativeBaseMenuContent
