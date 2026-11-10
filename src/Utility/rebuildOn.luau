local Vide = require("../Packages/Vide")

local Types = require("../Components/Types")

--* Vide.switch shows nothing for a nil key.
local NIL_KEY = newproxy()

--- `render(value)`, built again whenever `value` changes, the way React remounts a host instance whose class changed
--- (a disabled control fading into a CanvasGroup, a label losing its input handlers). A plain value builds once and
--- returns the instance; a source returns a source of the current instance. Name the result with `named`.
local function rebuildOn<T>(value: Types.Value<T>, render: (T) -> GuiObject): GuiObject | () -> GuiObject
	if type(value) ~= "function" then
		return render(value :: T)
	end
	local read = value :: () -> T
	local builders = setmetatable({}, {
		__index = function(_, key: any)
			return function()
				return render(if key == NIL_KEY then nil :: any else key)
			end
		end,
	})
	return Vide.switch(function(): any
		local current = read()
		return if current == nil then NIL_KEY else current
	end)(builders :: any) :: any
end

return rebuildOn
