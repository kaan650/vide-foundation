local TextService = require("./Wrappers").Services.TextService
local noYield = require("./noYield")

local function getTextSizeOffset(): number?
	return (
		noYield(function(): number?
			local success, offset = pcall(function()
				return TextService:GetTextSizeOffsetAsync(0, Font.fromEnum(Enum.Font.BuilderSans))
			end)
			return if success then offset else nil
		end) :: any
	) :: number?
end

return getTextSizeOffset
