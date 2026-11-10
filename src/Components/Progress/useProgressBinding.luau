local Types = require("../Types")
local Value = require("../../Utility/Value")

type Value<T> = Types.Value<T>

--- The progress as a fraction from 0 to 1 (nil while indeterminate), and whether it is indeterminate.
local function useProgressBinding(value: Value<number?>?): (() -> number?, () -> boolean)
	local function progress(): number?
		local current: number? = Value.read(value)
		return if current ~= nil then math.clamp(current / 100, 0, 1) else nil
	end
	local function isIndeterminate(): boolean
		return Value.read(value) == nil
	end
	return progress, isIndeterminate
end

return useProgressBinding
