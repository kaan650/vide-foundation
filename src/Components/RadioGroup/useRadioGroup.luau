local RadioGroupContext = require("./RadioGroupContext")
type RadioGroupContextValue = RadioGroupContext.RadioGroupContextValue

--- The enclosing RadioGroup's selection. Call it while the component is being created.
local function useRadioGroup(): RadioGroupContextValue
	return RadioGroupContext()
end

return useRadioGroup
