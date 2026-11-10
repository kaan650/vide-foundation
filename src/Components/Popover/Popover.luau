local Vide = require("../../Packages/Vide")

local PopoverContext = require("./PopoverContext")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local withDefaults = require("../../Utility/withDefaults")

type PopoverAnchor = Types.PopoverAnchor
type Value<T> = Types.Value<T>

export type PopoverProps = {
	-- Whether the popover is open
	isOpen: Value<boolean>,
	-- Builds the popover's Anchor and Content, which must be created inside it.
	children: () -> any,
	testId: string?,
}

local defaultProps = {
	testId = "--foundation-popover",
}

--- Shares the open state and the anchor between `Popover.Anchor` and `Popover.Content`. Returns what `children`
--- returns.
local function Popover(popoverProps: PopoverProps): any
	local props = withDefaults(popoverProps, defaultProps)
	local anchor = Vide.source(nil :: PopoverAnchor?)
	local getAnchor: () -> PopoverAnchor? = anchor :: any

	return PopoverContext({
		anchor = getAnchor,
		setAnchor = function(value: PopoverAnchor?)
			if Vide.untrack(getAnchor) ~= value then
				anchor(value)
			end
		end,
		isOpen = function()
			return Value.read(props.isOpen) == true
		end,
		testId = props.testId,
	}, props.children)
end

return Popover
