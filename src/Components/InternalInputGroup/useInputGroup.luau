local InputGroupContext = require("./InputGroupContext")
type InputGroupConfiguration = InputGroupContext.InputGroupConfiguration

--- The size and placement of the enclosing InternalInputGroup. Call it while the component is being created.
local function useInputGroup(): InputGroupConfiguration
	return InputGroupContext()
end

return useInputGroup
