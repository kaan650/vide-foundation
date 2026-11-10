local TextSizeOffsetContext = require("./TextSizeOffsetContext")

local function useTextSizeOffset(): () -> number
	return TextSizeOffsetContext()
end

return useTextSizeOffset
