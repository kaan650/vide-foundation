local PluginContext = require("./PluginContext")

type Props = {
	plugin: Plugin?,
	children: (() -> any)?,
}

local function PluginProvider(props: Props)
	return PluginContext(props.plugin, function()
		return if props.children then props.children() else nil
	end)
end

return PluginProvider
