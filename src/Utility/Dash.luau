-- The part of Roblox's Dash that Foundation uses, with the same semantics.
local Dash = {}

--- Removes a key when given as a value to `join`.
Dash.None = newproxy(true) :: any
getmetatable(Dash.None :: any).__tostring = function()
	return "Dash.None"
end

function Dash.noop(...: any) end

--- A new table with the keys of every argument; later arguments win and `Dash.None` removes a key.
function Dash.join(...: { [any]: any }?): { [any]: any }
	local result = {}
	for i = 1, select("#", ...) do
		local source = select(i, ...)
		if source then
			for key, value in source do
				if value == Dash.None then
					result[key] = nil
				else
					result[key] = value
				end
			end
		end
	end
	return result
end

Dash.union = Dash.join

--- Merges the keys of the other arguments into `target`, which it returns.
function Dash.assign(target: { [any]: any }, ...: { [any]: any }?): { [any]: any }
	for i = 1, select("#", ...) do
		local source = select(i, ...)
		if source then
			for key, value in source do
				if value == Dash.None then
					target[key] = nil
				else
					target[key] = value
				end
			end
		end
	end
	return target
end

function Dash.copy<T>(source: T): T
	return table.clone(source :: any) :: any
end

function Dash.joinArrays(...: { any }?): { any }
	local result = {}
	for i = 1, select("#", ...) do
		local source = select(i, ...)
		if source then
			for _, value in source do
				table.insert(result, value)
			end
		end
	end
	return result
end

function Dash.map(source: { [any]: any }, handler: (value: any, key: any) -> any): { [any]: any }
	local result = {}
	for key, value in source do
		result[key] = handler(value, key)
	end
	return result
end

function Dash.filter(source: { [any]: any }, handler: (value: any, key: any) -> boolean): { any }
	local result = {}
	for key, value in source do
		if handler(value, key) then
			table.insert(result, value)
		end
	end
	return result
end

function Dash.find(source: { [any]: any }, handler: (value: any, key: any) -> boolean): any
	for key, value in source do
		if handler(value, key) then
			return value
		end
	end
	return nil
end

function Dash.findIndex(source: { any }, handler: (value: any, index: number) -> boolean): number?
	for index, value in ipairs(source) do
		if handler(value, index) then
			return index
		end
	end
	return nil
end

function Dash.includes(source: { [any]: any }, item: any): boolean
	for _, value in source do
		if value == item then
			return true
		end
	end
	return false
end

function Dash.keys(source: { [any]: any }): { any }
	local result = {}
	for key in source do
		table.insert(result, key)
	end
	return result
end

function Dash.values(source: { [any]: any }): { any }
	local result = {}
	for _, value in source do
		table.insert(result, value)
	end
	return result
end

function Dash.omit(source: { [any]: any }, keys: { any }): { [any]: any }
	local omitted = {}
	for _, key in keys do
		omitted[key] = true
	end
	local result = {}
	for key, value in source do
		if not omitted[key] then
			result[key] = value
		end
	end
	return result
end

function Dash.forEach(source: { [any]: any }, handler: (value: any, key: any) -> ())
	for key, value in source do
		handler(value, key)
	end
end

function Dash.forEachArgs(handler: (value: any, index: number) -> (), ...: any)
	for i = 1, select("#", ...) do
		handler(select(i, ...), i)
	end
end

function Dash.get(source: any, path: { any }): any
	local current = source
	for _, key in path do
		if type(current) ~= "table" then
			return nil
		end
		current = current[key]
	end
	return current
end

function Dash.memoize<A, R>(fn: (A) -> R): (A) -> R
	local cache: { [any]: any } = {}
	return function(argument: A): R
		local cached = cache[argument]
		if cached == nil then
			cached = fn(argument)
			cache[argument] = cached
		end
		return cached
	end
end

type ThrottleOptions = { leading: boolean?, trailing: boolean? }

--- Calls `fn` at most once every `wait` seconds; with `trailing` the last skipped call runs when the wait ends.
function Dash.throttle<A...>(fn: (A...) -> (), wait: number, options: ThrottleOptions?): (A...) -> ()
	local leading = if options and options.leading ~= nil then options.leading else true
	local trailing = if options and options.trailing ~= nil then options.trailing else true
	local lastCall = -math.huge
	local pending: thread? = nil
	local pendingArgs: { any }? = nil

	return function(...: A...)
		local now = os.clock()
		local remaining = wait - (now - lastCall)
		if remaining <= 0 and (leading or lastCall ~= -math.huge) then
			lastCall = now
			fn(...)
		elseif trailing then
			pendingArgs = (table.pack :: any)(...)
			if not pending then
				pending = task.delay(math.max(remaining, 0), function()
					pending = nil
					lastCall = os.clock()
					local args = pendingArgs :: { any }
					pendingArgs = nil
					fn(table.unpack(args :: any, 1, (args :: any).n))
				end)
			end
		end
	end
end

return Dash
