local Vide = require("../Packages/Vide")

local Types = require("../Components/Types")
local Value = require("../Utility/Value")
local create = require("../Utility/create")

type Value<T> = Types.Value<T>

export type StyleRuleProps = {
	Priority: Value<number>?,
	Selector: Value<string>,
	properties: Value<{ [string]: any }>,
}

--- A StyleRule instance whose properties follow `properties`. Priority 0 is reserved for default styles.
local function StyleRule(props: StyleRuleProps): StyleRule
	return create("StyleRule")({
		Priority = function()
			return Value.read(props.Priority) or 1
		end,
		Selector = props.Selector,
		Vide.action(function(instance: Instance)
			Vide.effect(function()
				(instance :: StyleRule):SetProperties(Value.read(props.properties))
			end)
		end),
	})
end

return StyleRule
