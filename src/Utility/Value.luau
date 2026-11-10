local Vide = require("../Packages/Vide")

local Types = require("../Components/Types")
type Value<T> = Types.Value<T>

--- `T` with every function in it replaced by what the function returns: the type `Value.read` gives back.
export type function Unwrap(value: type)
	local function unwrap(component: type): type
		if component.tag == "function" then
			local returns = component:returns().head
			return if returns and returns[1] then returns[1] else types.unknown
		elseif component.tag == "union" then
			local parts = {}
			for _, part in component:components() do
				table.insert(parts, unwrap(part))
			end
			return if #parts == 1 then parts[1] else types.unionof(table.unpack(parts))
		end
		return component
	end
	return unwrap(value)
end

local Value = {}

local function read(value: any): any
	return if type(value) == "function" then (value :: any)() else value
end

--- Reads a plain value or a source. Inside a reactive scope this subscribes to the source.
--! Typed through a cast: declared directly, the solver reduces Unwrap<T> while T is still generic and returns T.
Value.read = (read :: any) :: <T>(value: T) -> Unwrap<T>

--- Turns a plain value into a constant source; returns a source unchanged.
function Value.source<T>(value: Value<T>): () -> T
	if type(value) == "function" then
		return value :: () -> T
	end
	return function()
		return value :: T
	end
end

--- `container[key]`, staying reactive when either the container or the field is a source.
function Value.index(container: any, key: string): any
	if type(container) == "function" then
		return function()
			local resolved: any = (container :: any)()
			return if resolved ~= nil then read(resolved[key]) else nil
		end
	elseif container == nil then
		return nil
	end
	return container[key]
end

--- `map(value)`, as a source when `value` is one.
function Value.map<T, U>(value: Value<T>, map: (T) -> U): Value<U>
	if type(value) == "function" then
		return function()
			return map((value :: () -> T)())
		end
	end
	return map(value :: T)
end

--- An action that keeps `property` equal to `value`. While `value` is nil the property is reset to its engine
--- default, so StyleSheet rules can style it again.
function Value.bindProperty(property: string, value: Value<any>, priority: number?)
	return Vide.action(function(instance: Instance)
		Vide.effect(function()
			local resolved = Value.read(value)
			if resolved == nil then
				instance:ResetPropertyToDefault(property)
			else
				(instance :: any)[property] = resolved
			end
		end)
	end, priority)
end

return Value
