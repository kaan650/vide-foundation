local Wrappers = require("./Wrappers")

local function isPluginSecurity(): boolean
	local coreGui = Wrappers.Services.CoreGui
	local childAccessSuccess, _ = pcall(function()
		local _ = coreGui:GetChildren()
	end)

	return childAccessSuccess
end

return isPluginSecurity
