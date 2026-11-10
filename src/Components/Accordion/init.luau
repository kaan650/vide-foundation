local AccordionItem = require("@self/Item")
local AccordionRoot = require("@self/Accordion")

export type AccordionProps = AccordionRoot.AccordionProps
export type AccordionItemProps = AccordionItem.AccordionItemProps

return {
	Root = AccordionRoot,
	Item = AccordionItem,
}
