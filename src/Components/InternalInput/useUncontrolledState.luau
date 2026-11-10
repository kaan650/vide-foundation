local Vide = require("../../Packages/Vide")

local Types = require("../Types")
local Value = require("../../Utility/Value")

type Value<T> = Types.Value<T>

--- The checked state of an input that is controlled while `isChecked` is non-nil and keeps its own state otherwise.
--- Returns the state as a source and the activation callback to hand to the input. Call it while the component is
--- being created.
local function useUncontrolledState(
	isChecked: Value<boolean?>?,
	onActivated: (value: boolean) -> ()
): (() -> boolean, (value: boolean) -> ())
	local function controlled(): boolean?
		return Value.read(isChecked)
	end

	local internalIsChecked = Vide.source(Vide.untrack(controlled) or false)
	Vide.effect(function()
		local value = controlled()
		if value ~= nil then
			Vide.untrack(function()
				internalIsChecked(value)
			end)
		end
	end)

	local function internalOnActivated(value: boolean)
		if Vide.untrack(controlled) == nil then
			internalIsChecked(value)
		end
		onActivated(value)
	end

	return internalIsChecked, internalOnActivated
end

return useUncontrolledState
