local Vide = require("../../Packages/Vide")

local Types = require("../Types")

export type RadioGroupContextValue = {
	value: () -> string?,
	onValueChanged: (newValue: string) -> (),
	Selectable: Types.Value<boolean>?,
	testId: string?,
}

return Vide.context({
	value = function(): string?
		return nil
	end,
	onValueChanged = function(_newValue: string)
		warn("No RadioGroupProvider found for RadioGroup")
	end,
	Selectable = true,
	testId = "",
} :: RadioGroupContextValue)
