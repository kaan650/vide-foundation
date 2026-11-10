local Vide = require("../../Packages/Vide")

local ResponsiveContext = require("./ResponsiveContext")
local Value = require("../../Utility/Value")
local Types = require("../../Components/Types")
type ResponsiveConfig = ResponsiveContext.ResponsiveConfig
type Value<T> = Types.Value<T>

export type ResponsiveProviderProps = {
	config: Value<ResponsiveConfig?>?,
	children: (() -> any)?,
}

local function ResponsiveProvider(props: ResponsiveProviderProps)
	local value = Vide.derive(function(): ResponsiveContext.ResponsiveContext
		--* A partial config is allowed at runtime; missing parts fall back to the defaults.
		local config: any = Value.read(props.config) or {}
		return {
			config = {
				breakpoint = config.breakpoint or ResponsiveContext.DEFAULT.config.breakpoint,
				grid = config.grid or ResponsiveContext.DEFAULT.config.grid,
			},
		}
	end)

	return ResponsiveContext.context(value, function()
		return if props.children then props.children() else nil
	end)
end

return ResponsiveProvider
