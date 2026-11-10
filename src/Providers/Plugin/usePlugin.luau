local PluginContext = require("./PluginContext")
local isPluginElevated = require("./isPluginElevated")

local function usePlugin(): (Plugin?, boolean)
	local plugin = PluginContext()
	if plugin then
		return plugin, isPluginElevated(plugin)
	end
	return nil, false
end

return usePlugin
