--- Names `child` after the React key it renders under. A source of an instance, such as `rebuildOn` returns, names
--- every instance it yields; anything else that is not an instance is returned unchanged.
local function named<T>(name: string, child: T): T
	if type(child) == "function" then
		local source: () -> any = child :: any
		return (function()
			local instance = source()
			if typeof(instance) == "Instance" then
				instance.Name = name
			end
			return instance
		end) :: any
	elseif typeof(child) == "Instance" then
		(child :: any).Name = name
	end
	return child :: any
end

return named
