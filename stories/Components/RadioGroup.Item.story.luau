local foundation = require("../foundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local InputPlacement = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputPlacement")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local RadioGroupContext =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Components/RadioGroup/RadioGroupContext")

type InputSize = InputSize.InputSize

local RadioGroup = VF.RadioGroup

--- Provides a radio group context around `build`, holding the checked value in a source.
local function withContext(build: () -> any)
	local value = Vide.source(nil :: string?)
	local getValue: () -> string? = value :: any
	return RadioGroupContext({
		value = getValue,
		onValueChanged = function(newValue: string)
			value(newValue)
		end,
		Selectable = true,
	}, build)
end

local function PlaygroundStory(controls: { [string]: any })
	return withContext(function()
		--* An item's value is a plain string, so a new value builds the item again.
		return foundation.rebuildOn(controls.value, function(value: string)
			return RadioGroup.Item({
				value = value,
				label = function()
					local label: string = controls.label()
					return if #label > 0 then `{label} {value}` else ""
				end,
				hint = function()
					local hint: string = controls.hint()
					return if #hint > 0 then hint else nil
				end,
				isDisabled = controls.isDisabled,
				size = controls.size,
				placement = controls.placement,
			}) :: any
		end)
	end)
end

local function SizesStory()
	local sizes: { InputSize } = { InputSize.XSmall, InputSize.Small, InputSize.Medium, InputSize.Large }

	return withContext(function()
		local items = {}
		for index, size in sizes do
			items[index] = RadioGroup.Item({
				value = size,
				label = size,
				size = size,
				LayoutOrder = index,
			})
		end
		return VF.View({
			tag = "row align-y-center gap-large auto-xy",
			children = items,
		})
	end)
end

return foundation.sections({
	summary = "Checkbox component",
	controls = {
		isDisabled = false,
		label = "Label",
		hint = "",
		value = "A",
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		placement = UILabs.Choose(Dash.values(InputPlacement :: any)),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizes", summary = "RadioGroupItem rendered at every supported size", story = SizesStory },
	},
})
