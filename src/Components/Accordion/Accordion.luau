local AccordionContext = require("./AccordionContext")
local InputPlacement = require("../../Enums/InputPlacement")
local InputSize = require("../../Enums/InputSize")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InputPlacement = InputPlacement.InputPlacement
type InputSize = InputSize.InputSize
type Value<T> = Types.Value<T>

export type AccordionProps = {
	-- Width of the accordion and its items.
	width: Value<UDim>?,
	-- Builds each item's activation handler from its id; items without their own onActivated use it.
	onActivated: AccordionContext.onAccordionItemActivated?,
	-- Size of the items.
	size: Value<InputSize>?,
	-- Whether the items get contained spacing.
	isContained: Value<boolean>?,
	-- Side of each item header where the collapse chevron sits.
	chevronPosition: Value<InputPlacement>?,
	-- Builds the `Accordion.Item`s, which must be created inside the accordion to read its configuration.
	children: (() -> any)?,
} & Types.CommonProps

local defaultProps = {
	chevronPosition = InputPlacement.End,
	isContained = false,
	size = InputSize.Medium,
	width = UDim.new(1, 0),
	testId = "--foundation-accordion",
}

--- A column of collapsible `Accordion.Item`s sharing a size and an activation handler.
local function Accordion(accordionProps: AccordionProps): GuiObject
	local props = withDefaults(accordionProps, defaultProps)
	local buildChildren = props.children

	local children = AccordionContext({
		onAccordionItemActivated = props.onActivated,
		itemSize = function()
			return Value.read(props.size)
		end,
		isContained = function()
			return Value.read(props.isContained)
		end,
		chevronPosition = function()
			return Value.read(props.chevronPosition)
		end,
		testId = props.testId,
	}, function()
		return if buildChildren then buildChildren() else nil
	end)

	return View(withCommonProps(props, {
		tag = "col flex-y-evenly auto-y",
		Size = function()
			return UDim2.new(Value.read(props.width), UDim.new(0, 0))
		end,
		children = children,
	}) :: any)
end

return Accordion
