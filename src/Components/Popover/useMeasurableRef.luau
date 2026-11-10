local Vide = require("../../Packages/Vide")

local Types = require("../Types")
local Value = require("../../Utility/Value")

type MeasurableObject = Types.MeasurableObject
type MeasurableObjectSignal<T> = Types.MeasurableObjectSignal<T>
type Value<T> = Types.Value<T>

type SignalWrapper<T> = { signal: MeasurableObjectSignal<T>, fire: (value: T) -> () }

local function createSignal<T>(): SignalWrapper<T>
	local listeners: { [{}]: (value: T) -> () } = {}

	local signal = {}
	function signal.Connect(_self: any, callback: (value: T) -> ())
		local key = {}
		listeners[key] = callback
		return {
			Disconnect = function(_connection: any)
				listeners[key] = nil
			end,
		}
	end

	local function fire(value: T)
		for _, callback in table.clone(listeners) do
			callback(value)
		end
	end

	return { signal = signal :: any, fire = fire }
end

local MeasurableObject = {}
MeasurableObject.__index = MeasurableObject

function MeasurableObject.new(position: Vector2, size: Vector2)
	return setmetatable({
		AbsolutePosition = position,
		AbsoluteSize = size,
		_signals = {
			AbsolutePosition = createSignal() :: SignalWrapper<Vector2>,
			AbsoluteSize = createSignal() :: SignalWrapper<Vector2>,
		},
	}, MeasurableObject)
end

function MeasurableObject:GetPropertyChangedSignal(propertyName: string): MeasurableObjectSignal<any>
	local wrapper = self._signals[propertyName]
	if wrapper then
		return wrapper.signal
	end
	error(`{propertyName} is not a valid property name.`)
end

function MeasurableObject:SetPosition(newPosition: Vector2)
	if self.AbsolutePosition ~= newPosition then
		self.AbsolutePosition = newPosition
		self._signals.AbsolutePosition.fire(newPosition)
	end
end

function MeasurableObject:SetSize(newSize: Vector2)
	if self.AbsoluteSize ~= newSize then
		self.AbsoluteSize = newSize
		self._signals.AbsoluteSize.fire(newSize)
	end
end

--- A stand-in popover anchor with a screen position and size instead of an instance, for anchoring to a point (a
--- context menu at the cursor). It follows `position` and `size` while they are sources. Call it while the component
--- is being created.
local function useMeasurableRef(position: Value<Vector2>, size: Value<Vector2?>?): MeasurableObject
	local function currentSize(): Vector2
		local resolved: Vector2? = Value.read(size)
		return resolved or Vector2.one
	end

	local function currentPosition(): Vector2
		return Value.read(position)
	end

	local object = MeasurableObject.new(Vide.untrack(currentPosition), Vide.untrack(currentSize))

	Vide.effect(function()
		local resolved = currentPosition()
		Vide.untrack(function()
			object:SetPosition(resolved)
		end)
	end)
	Vide.effect(function()
		local resolved = currentSize()
		Vide.untrack(function()
			object:SetSize(resolved)
		end)
	end)

	return object :: any
end

return useMeasurableRef
