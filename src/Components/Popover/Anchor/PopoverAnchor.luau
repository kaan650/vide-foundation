local Vide = require("../../../Packages/Vide")

local PopoverContext = require("../PopoverContext")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local withCommonProps = require("../../../Utility/withCommonProps")

type PopoverAnchor = Types.PopoverAnchor
type Value<T> = Types.Value<T>

export type PopoverAnchorProps = {
	-- What to anchor the popover to: an instance, a source of one, or a `useMeasurableRef` object. If provided,
	-- children are not rendered.
	anchorRef: Value<PopoverAnchor?>?,
	children: Types.Children?,
} & Types.CommonProps

--- The element the popover attaches to: a View wrapping `children`, or nothing when `anchorRef` names the anchor.
local function PopoverAnchor(props: PopoverAnchorProps): GuiObject?
	local popoverContext = PopoverContext()

	local anchorRef = props.anchorRef
	if anchorRef ~= nil then
		Vide.effect(function()
			local anchor = Value.read(anchorRef)
			Vide.untrack(function()
				popoverContext.setAnchor(anchor)
			end)
		end)
		return nil
	end

	local viewProps: View.ViewProps = withCommonProps(props, {
		tag = "auto-xy",
		children = props.children,
	} :: View.ViewProps)
	viewProps.testId = `{popoverContext.testId}--anchor`

	local anchor = View(viewProps)
	anchor.Name = "Anchor"
	popoverContext.setAnchor(anchor)
	return anchor
end

return PopoverAnchor
