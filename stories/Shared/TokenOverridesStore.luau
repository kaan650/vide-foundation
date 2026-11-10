local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require("@game/ReplicatedStorage/Packages/Vide")

--* UI Labs loads fresh module copies for every story, so the overrides live in an instance all stories can see.
local HOLDER_NAME = "VideFoundationStoryTokenOverrides"

--- A token path to remap to, or a literal color.
export type Override = string | { Color3: Color3, Transparency: number }
export type Overrides = { [string]: Override }

local function encode(overrides: Overrides): string
	local data = {}
	for path, value in overrides do
		data[path] = if type(value) == "string"
			then value
			else { value.Color3.R, value.Color3.G, value.Color3.B, value.Transparency }
	end
	return HttpService:JSONEncode(data)
end

local function decode(json: string): Overrides?
	if json == "" then
		return nil
	end
	local data: { [string]: any } = HttpService:JSONDecode(json)
	local overrides: Overrides = {}
	for path, value in data do
		overrides[path] = if type(value) == "string"
			then value
			else { Color3 = Color3.new(value[1], value[2], value[3]), Transparency = value[4] }
	end
	return if next(overrides) then overrides else nil
end

local function findHolder(): StringValue?
	local holder = ReplicatedStorage:FindFirstChild(HOLDER_NAME)
	return if holder and holder:IsA("StringValue") then holder else nil
end

--- The overrides set by the TokenOverrides story, or nil.
local function get(): Overrides?
	local holder = findHolder()
	return if holder then decode(holder.Value) else nil
end

--- Sets the overrides every story applies; nil or an empty table clears them.
local function set(overrides: Overrides?)
	local json = if overrides and next(overrides) then encode(overrides) else ""
	local holder = findHolder()
	if holder == nil then
		if json == "" then
			return
		end
		local created = Instance.new("StringValue")
		created.Name = HOLDER_NAME
		created.Archivable = false
		created.Parent = ReplicatedStorage
		holder = created
	end
	if (holder :: StringValue).Value ~= json then
		(holder :: StringValue).Value = json
	end
end

--- A source of the overrides that follows `set`. Call it while a story is being created.
local function use(): () -> Overrides?
	local overrides = Vide.source(get())
	local connections: { RBXScriptConnection } = {}

	local function follow(holder: StringValue)
		table.insert(
			connections,
			holder.Changed:Connect(function()
				overrides(decode(holder.Value))
			end)
		)
		overrides(decode(holder.Value))
	end

	local holder = findHolder()
	if holder then
		follow(holder)
	else
		table.insert(
			connections,
			ReplicatedStorage.ChildAdded:Connect(function(child)
				if child.Name == HOLDER_NAME and child:IsA("StringValue") then
					follow(child)
				end
			end)
		)
	end

	Vide.cleanup(function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)

	return overrides :: any
end

return {
	get = get,
	set = set,
	use = use,
}
