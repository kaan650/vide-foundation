local Vide = require("../../Packages/Vide")

local FillBehavior = require("../../Enums/FillBehavior")
local InputLabel = require("../InputLabel")
local OptionSelectorGroupContext = require("./OptionSelectorGroupContext")
local OptionSelectorGroupSize = require("../../Enums/OptionSelectorGroupSize")
local Orientation = require("../../Enums/Orientation")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local named = require("../../Utility/named")
local useOptionSelectorGroupVariants = require("./useOptionSelectorGroupVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type FillBehavior = FillBehavior.FillBehavior
type OptionSelectorGroupSize = OptionSelectorGroupSize.OptionSelectorGroupSize
type Orientation = Orientation.Orientation
type Value<T> = Types.Value<T>

export type OptionSelectorGroupProps = {
	-- The value of the currently selected OptionSelector item.
	-- If `nil`, the OptionSelectorGroup will be considered uncontrolled.
	value: Value<string?>?,
	-- Called with the activated item's value, or nil when the selected item is activated again.
	onValueChanged: (newValue: string?) -> (),
	-- The orientation to lay the items out in, default is vertical.
	orientation: Value<Orientation>?,
	-- Optional group legend. Omit or `nil` to hide.
	legend: Value<string?>?,
	-- Size of the group. Cascades to items via context.
	size: Value<OptionSelectorGroupSize?>?,
	-- Fill behavior for stacked items in a horizontal group. Cascades to items via context.
	-- Ignored for vertical groups (items always Fill). Omit to let each Item choose.
	fillBehavior: Value<FillBehavior?>?,
	-- Builds the `OptionSelectorGroup.Item`s, which must be created inside the group.
	children: (() -> any)?,
} & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	orientation = Orientation.Vertical :: Orientation,
	size = OptionSelectorGroupSize.Medium :: OptionSelectorGroupSize,
	Selectable = true,
	testId = "--foundation-option-selector-group",
}

--- A list of bordered options of which at most one is selected, under an optional legend. Activating the selected
--- option deselects it.
local function OptionSelectorGroup(optionSelectorGroupProps: OptionSelectorGroupProps): GuiObject
	local props = withDefaults(optionSelectorGroupProps, defaultProps)
	local tokens = useTokens()

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

	local function onValueChanged(newValue: string?)
		value(newValue)
		props.onValueChanged(newValue)
	end

	local function orientation(): Orientation
		return Value.read(props.orientation)
	end

	local variantProps = Vide.derive(function()
		return useOptionSelectorGroupVariants(
			tokens(),
			Value.read(props.size) or OptionSelectorGroupSize.Medium,
			orientation()
		)
	end)

	local legend = Vide.show(function()
		return Value.read(props.legend) ~= nil
	end, function()
		return named(
			"Legend",
			InputLabel({
				Text = function()
					return Value.read(props.legend) or ""
				end,
				size = function()
					return variantProps().legend.size
				end,
				LayoutOrder = 1,
				testId = `{props.testId}--legend`,
			})
		)
	end)

	local children = props.children
	local list = View({
		tag = function()
			return variantProps().list.tag
		end,
		LayoutOrder = 2,
		testId = `{props.testId}--list`,
		children = if children
			then OptionSelectorGroupContext({
				value = getValue,
				onValueChanged = onValueChanged,
				orientation = orientation,
				Selectable = props.Selectable,
				testId = props.testId,
				--* Only what the group sets cascades; otherwise items keep their own size and fill behavior.
				size = function(): OptionSelectorGroupSize?
					return Value.read(optionSelectorGroupProps.size)
				end,
				fillBehavior = function(): FillBehavior?
					return Value.read(optionSelectorGroupProps.fillBehavior)
				end,
			}, children)
			else nil,
	})
	list.Name = "List"

	return View(withCommonProps(props, {
		tag = function()
			return variantProps().container.tag
		end,
		children = { legend, list },
	}) :: any)
end

return OptionSelectorGroup
