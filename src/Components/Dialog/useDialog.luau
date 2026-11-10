local DialogContext = require("./DialogContext")

local function useDialog(): DialogContext.DialogContextValue
	return DialogContext()
end

return useDialog
