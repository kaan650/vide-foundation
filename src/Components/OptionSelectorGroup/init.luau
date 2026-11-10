local OptionSelectorGroup = require("@self/OptionSelectorGroup")
local OptionSelectorGroupItem = require("@self/Item")

export type OptionSelectorGroupProps = OptionSelectorGroup.OptionSelectorGroupProps
export type OptionSelectorGroupItemProps = OptionSelectorGroupItem.OptionSelectorGroupItemProps

return {
	Root = OptionSelectorGroup,
	Item = OptionSelectorGroupItem,
}
