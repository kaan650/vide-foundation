local BaseMenu = require("@self/BaseMenu")

local BaseMenuContext = require("@self/BaseMenuContext")
local BaseMenuGroup = require("@self/BaseMenuGroup")
local BaseMenuItem = require("@self/BaseMenuItem")

export type BaseMenuProps<Item = BaseMenuItem> = BaseMenu.BaseMenuProps<Item>
export type BaseMenuItem = BaseMenu.BaseMenuItem
export type BaseMenuItems<Item = BaseMenuItem> = BaseMenu.BaseMenuItems<Item>
export type BaseMenuItemGroup<Item = BaseMenuItem> = BaseMenu.BaseMenuItemGroup<Item>
export type BaseMenuItemProps = BaseMenuItem.BaseMenuItemProps
export type BaseMenuGroupProps = BaseMenuGroup.BaseMenuGroupProps
export type LeadingAccessory = BaseMenuItem.LeadingAccessory
export type TrailingAccessory = BaseMenuItem.TrailingAccessory

return {
	Root = BaseMenu,
	Item = BaseMenuItem,
	Context = BaseMenuContext,
	Group = BaseMenuGroup,
}
