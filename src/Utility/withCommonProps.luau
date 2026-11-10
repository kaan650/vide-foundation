local Vide = require("../Packages/Vide")

local Types = require("../Components/Types")
type CommonProps = Types.CommonProps

--- Adds the props every Foundation component forwards to its root instance into `properties`.
local function withCommonProps(props: CommonProps, properties: { [any]: any }): { [any]: any }
	properties.AnchorPoint = props.AnchorPoint
	properties.LayoutOrder = props.LayoutOrder
	properties.Position = props.Position
	properties.Visible = props.Visible
	properties.ZIndex = props.ZIndex

	local onAbsoluteSizeChanged = props.onAbsoluteSizeChanged
	if onAbsoluteSizeChanged then
		table.insert(
			properties,
			Vide.action(function(instance: Instance)
				Vide.cleanup((instance :: GuiObject):GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					onAbsoluteSizeChanged(instance :: GuiObject)
				end))
			end)
		)
	end

	local onAbsolutePositionChanged = props.onAbsolutePositionChanged
	if onAbsolutePositionChanged then
		table.insert(
			properties,
			Vide.action(function(instance: Instance)
				Vide.cleanup((instance :: GuiObject):GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
					onAbsolutePositionChanged(instance :: GuiObject)
				end))
			end)
		)
	end

	return properties
end

return withCommonProps
