local Vide = require("../Packages/Vide")

local TagsContext = require("../Providers/Style/TagsContext")
local Types = require("../Components/Types")
local Value = require("./Value")
local getFormattedTags = require("./getFormattedTags")

type Tags = Types.Tags

--- An action that keeps the instance's CollectionService tags equal to the union of `values`, and registers them with
--- the provider's StyleSheet so their rules exist. Replaces Foundation's `useStyleTags` and `[React.Tag]`; it works
--- on any instance, Foundation component or not. Call it while the component is being created.
local function tags(...: Types.Value<Tags?>?)
	local values = { ... }
	local count = select("#", ...)
	local addTags = TagsContext()

	return Vide.action(function(instance: Instance)
		local applied: { [string]: boolean } = {}

		Vide.effect(function()
			local nextTags: { [string]: boolean } = {}
			local list: { string } = {}
			for i = 1, count do
				local formatted = getFormattedTags(Value.read(values[i]))
				if formatted then
					for _, tag in string.split(formatted, " ") do
						if tag ~= "" and not nextTags[tag] then
							nextTags[tag] = true
							table.insert(list, tag)
						end
					end
				end
			end

			addTags(list)

			for tag in applied do
				if not nextTags[tag] then
					instance:RemoveTag(tag)
				end
			end
			for tag in nextTags do
				if not applied[tag] then
					instance:AddTag(tag)
				end
			end
			applied = nextTags
		end)
	end)
end

return tags
