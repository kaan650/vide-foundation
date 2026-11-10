local ListContext = require("./ListContext")
type ListContextValue = ListContext.ListContextValue

--- The enclosing `List.Root`'s configuration. Call it while the item is being created.
local function useList(): ListContextValue
	return ListContext()
end

return useList
