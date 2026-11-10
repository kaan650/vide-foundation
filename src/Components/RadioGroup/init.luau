local RadioGroup = require("@self/RadioGroup")
local RadioGroupItem = require("@self/Item")

export type RadioGroupProps = RadioGroup.RadioGroupProps
export type RadioGroupItemProps = RadioGroupItem.RadioGroupItemProps

return {
	Root = RadioGroup,
	Item = RadioGroupItem,
}
