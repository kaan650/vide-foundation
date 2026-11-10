local BaseMenu = require("../BaseMenu")
local Types = require("../Types")

type BaseMenuItem = BaseMenu.BaseMenuItem
type BaseMenuItems<Item> = BaseMenu.BaseMenuItems<Item>
type BaseMenuItemGroup<Item> = BaseMenu.BaseMenuItemGroup<Item>

--- `items` with the item whose id is `value` copied and checked, and that item. Nil `value` returns `items` as is.
local function markSelectedItem(items: { any }, value: Types.ItemId?): ({ any }, any)
	if value == nil then
		return items, nil
	end
	local newItems: { any } = {}
	local selectedItem: any = nil
	for _, item in items :: { any } do
		if item.id then
			local newItem = item
			if item.id == value then
				newItem = table.clone(item)
				newItem.isChecked = true
				selectedItem = newItem
			end
			table.insert(newItems, newItem)
		elseif item.items then
			local nestedItems, nestedFound = markSelectedItem(item.items, value)
			table.insert(newItems, { title = item.title, items = nestedItems })
			selectedItem = selectedItem or nestedFound
		end
	end
	return newItems :: any, selectedItem
end

return markSelectedItem
