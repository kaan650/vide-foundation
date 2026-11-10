local Vide = require("../../Packages/Vide")

local FillBehavior = require("../../Enums/FillBehavior")
local OptionSelectorGroupSize = require("../../Enums/OptionSelectorGroupSize")
local Orientation = require("../../Enums/Orientation")
local Types = require("../Types")

type FillBehavior = FillBehavior.FillBehavior
type OptionSelectorGroupSize = OptionSelectorGroupSize.OptionSelectorGroupSize
type Orientation = Orientation.Orientation

export type OptionSelectorGroupContextValue = {
	value: () -> string?,
	onValueChanged: (newValue: string?) -> (),
	orientation: () -> Orientation,
	Selectable: Types.Value<boolean>?,
	testId: string,
	-- nil when the group leaves the size to each item.
	size: () -> OptionSelectorGroupSize?,
	-- nil when the group leaves the fill behavior to each item.
	fillBehavior: () -> FillBehavior?,
}

return Vide.context({
	value = function(): string?
		return nil
	end,
	onValueChanged = function(_newValue: string?)
		warn("No OptionSelectorGroupProvider found for OptionSelectorGroup")
	end,
	orientation = function(): Orientation
		return Orientation.Vertical
	end,
	Selectable = true,
	testId = "",
	size = function(): OptionSelectorGroupSize?
		return OptionSelectorGroupSize.Medium
	end,
	fillBehavior = function(): FillBehavior?
		return nil
	end,
} :: OptionSelectorGroupContextValue)
