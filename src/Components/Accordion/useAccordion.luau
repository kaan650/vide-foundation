local AccordionContext = require("./AccordionContext")

export type onAccordionItemActivated = AccordionContext.onAccordionItemActivated
export type AccordionConfiguration = AccordionContext.AccordionConfiguration

--- The enclosing `Accordion.Root`'s configuration. Call it while the item is being created.
local function useAccordion(): AccordionConfiguration
	return AccordionContext()
end

return useAccordion
