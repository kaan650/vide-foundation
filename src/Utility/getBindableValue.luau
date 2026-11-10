local Vide = require("../Packages/Vide")

local Types = require("../Components/Types")
local Value = require("./Value")

type Value<T> = Types.Value<T>

--- The current value of a plain value or a source, without subscribing to the source.
local function getBindableValue<T>(bindable: Value<T>): T
	return Vide.untrack(function()
		return Value.read(bindable) :: any
	end)
end

return getBindableValue
