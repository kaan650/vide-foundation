local Vide = require("../../Packages/Vide")

local InputPlacement = require("../../Enums/InputPlacement")
local InputSize = require("../../Enums/InputSize")
local InternalInputGroup = require("../InternalInputGroup")
local RadioGroupContext = require("./RadioGroupContext")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InputPlacement = InputPlacement.InputPlacement
type Value<T> = Types.Value<T>

export type RadioGroupProps = {
	-- The value of the currently checked radio item.
	-- If `nil`, the radio group will be considered uncontrolled.
	value: Value<string?>?,
	onValueChanged: (newValue: string) -> (),
	-- Optional label above the grouped inputs.
	legend: Value<string?>?,
	-- Size applied to the group and inherited by its items.
	size: Types.InputGroupSize?,
	-- Where the input sits relative to its label.
	placement: InputPlacement?,
	-- Builds the `RadioGroup.Item`s, which must be created inside the group.
	children: (() -> any)?,
} & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	size = InputSize.Medium,
	placement = InputPlacement.Start,
	Selectable = true,
	testId = "--foundation-radio-group",
}

--- A column of radio items of which one is checked, under an optional legend.
local function RadioGroup(radioGroupProps: RadioGroupProps): GuiObject
	local props = withDefaults(radioGroupProps, defaultProps)

	local function controlled(): string?
		return Value.read(props.value)
	end
	local value = Vide.source(Vide.untrack(controlled))
	local getValue: () -> string? = value :: any
	--* Like React, a new non-nil `value` wins, but activation still moves the selection while `value` stays put.
	Vide.effect(function()
		local current = controlled()
		if current ~= nil then
			Vide.untrack(function()
				value(current)
			end)
		end
	end)

	local function onValueChanged(newValue: string)
		value(newValue)
		props.onValueChanged(newValue)
	end

	local children = props.children

	return InternalInputGroup(withCommonProps(props, {
		size = props.size,
		placement = props.placement,
		legend = props.legend,
		--* Built inside the group's children binding, under its InputGroupContext.
		children = if children
			then function()
				return Vide.untrack(function()
					return RadioGroupContext({
						value = getValue,
						onValueChanged = onValueChanged,
						Selectable = props.Selectable,
						testId = props.testId,
					}, children)
				end)
			end
			else nil,
	}) :: any)
end

return RadioGroup
