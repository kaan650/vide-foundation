local Vide = require("../Packages/Vide")

local Value = require("./Value")

--* Vide.switch shows nothing for a nil key.
local NIL_KEY = newproxy()

local function rebuildOn(value: any, render: (any) -> GuiObject): GuiObject | () -> GuiObject
	if type(value) ~= "function" then
		return render(value)
	end
	local read = value :: () -> any
	local builders = setmetatable({}, {
		__index = function(_, key: any)
			return function()
				return render(if key == NIL_KEY then nil else key)
			end
		end,
	})
	return Vide.switch(function(): any
		local current = read()
		return if current == nil then NIL_KEY else current
	end)(builders :: any) :: any
end

--- `render(value)`, built again whenever `value` changes, the way React remounts a host instance whose class changed
--- (a disabled control fading into a CanvasGroup, a label losing its input handlers). A plain value builds once and
--- returns the instance; a source returns a source of the current instance. Name the result with `named`.
--! Typed through a cast like `Value.read`: inferring T from a `T | () -> T` argument fails, so `render` takes the
--! value's own type with its functions unwrapped.
return (rebuildOn :: any) :: <V>(value: V, render: (Value.Unwrap<V>) -> GuiObject) -> GuiObject | () -> GuiObject
