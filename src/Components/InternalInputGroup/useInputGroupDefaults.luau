local useInputGroup = require("./useInputGroup")
local withDefaults = require("../../Utility/withDefaults")

--- Component props over the enclosing InputGroup's configuration over the component's defaults. Call it while the
--- component is being created.
local function useInputGroupDefaults<P, D>(props: P, defaultProps: D): P & D
	local context = useInputGroup()
	return withDefaults(props, withDefaults(context, defaultProps)) :: any
end

return useInputGroupDefaults
