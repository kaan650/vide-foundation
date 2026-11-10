local OptionSelectorGroupContext = require("./OptionSelectorGroupContext")
type OptionSelectorGroupContextValue = OptionSelectorGroupContext.OptionSelectorGroupContextValue

--- The enclosing OptionSelectorGroup's selection and layout. Call it while the component is being created.
local function useOptionSelectorGroup(): OptionSelectorGroupContextValue
	return OptionSelectorGroupContext()
end

return useOptionSelectorGroup
