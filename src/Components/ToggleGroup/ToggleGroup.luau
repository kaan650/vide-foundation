local Vide = require("../../Packages/Vide")

local InputPlacement = require("../../Enums/InputPlacement")
local InternalInputGroup = require("../InternalInputGroup")
local Types = require("../Types")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InputPlacement = InputPlacement.InputPlacement
type Value<T> = Types.Value<T>

export type ToggleGroupProps = {
	-- Optional label above the grouped inputs.
	legend: Value<string?>?,
	-- Size applied to the group and inherited by its inputs.
	size: Types.InputGroupSize?,
	-- Where the input sits relative to its label.
	placement: InputPlacement?,
	-- Builds the toggles. They are created inside the group, so they take its size and placement.
	children: (() -> any)?,
} & Types.CommonProps

local defaultProps = {
	testId = "--foundation-toggle-group",
}

--- A column of toggles under an optional legend.
local function ToggleGroup(toggleGroupProps: ToggleGroupProps): GuiObject
	local props = withDefaults(toggleGroupProps, defaultProps)
	local children = props.children

	return InternalInputGroup(withCommonProps(props, {
		legend = props.legend,
		size = props.size,
		placement = props.placement,
		--* Built inside the group's children binding, under its InputGroupContext.
		children = if children
			then function()
				return Vide.untrack(children)
			end
			else nil,
	}) :: any)
end

return ToggleGroup
