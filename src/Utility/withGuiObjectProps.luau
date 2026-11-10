local Vide = require("../Packages/Vide")

local Types = require("../Components/Types")
local Value = require("./Value")

type GuiObjectProps = Types.GuiObjectProps
type CommonProps = Types.CommonProps
type SelectionGroup = Types.SelectionGroup

local hasInputSink = pcall(game.GetEngineFeature, game, "GuiObjectInputSink")

--- Adds the GuiObject and common props Foundation components forward to their root instance into `properties`, as
--- instance properties and actions. `testId` becomes a tag through the component's `tags` call.
--- `backgroundStyle` is handled by the caller, since Interactable blends it with the state layer.
local function withGuiObjectProps(props: GuiObjectProps & CommonProps, properties: { [any]: any }): { [any]: any }
	properties.AutoLocalize = props.AutoLocalize
	properties.AutomaticSize = props.AutomaticSize
	properties.BorderSizePixel = props.BorderSizePixel
	properties.BorderColor3 = props.BorderColor3
	properties.BorderMode = props.BorderMode
	properties.ClipsDescendants = props.ClipsDescendants
	if hasInputSink then
		properties.InputSink = props.InputSink
	end
	properties.Rotation = props.Rotation
	properties.SizeConstraint = props.SizeConstraint
	properties.Size = props.Size

	local selection = props.selection
	if selection then
		properties.Selectable = selection.Selectable
		properties.SelectionImageObject = selection.SelectionImageObject
		properties.SelectionOrder = selection.SelectionOrder
		properties.NextSelectionDown = selection.NextSelectionDown
		properties.NextSelectionLeft = selection.NextSelectionLeft
		properties.NextSelectionRight = selection.NextSelectionRight
		properties.NextSelectionUp = selection.NextSelectionUp
	end

	local selectionGroup = props.selectionGroup
	if selectionGroup ~= nil then
		if type(selectionGroup) == "boolean" or type(selectionGroup) == "function" then
			properties.SelectionGroup = selectionGroup
		else
			local group = selectionGroup :: SelectionGroup
			properties.SelectionGroup = true
			properties.SelectionBehaviorUp = group.SelectionBehaviorUp
			properties.SelectionBehaviorDown = group.SelectionBehaviorDown
			properties.SelectionBehaviorLeft = group.SelectionBehaviorLeft
			properties.SelectionBehaviorRight = group.SelectionBehaviorRight
		end
	end

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
				local guiObject = instance :: GuiObject
				Vide.cleanup(guiObject:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					onAbsoluteSizeChanged(guiObject)
				end))
			end)
		)
	end

	local onAbsolutePositionChanged = props.onAbsolutePositionChanged
	if onAbsolutePositionChanged then
		table.insert(
			properties,
			Vide.action(function(instance: Instance)
				local guiObject = instance :: GuiObject
				Vide.cleanup(guiObject:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
					onAbsolutePositionChanged(guiObject)
				end))
			end)
		)
	end

	return properties
end

--- The background props for a non-interactable root: `backgroundStyle` split into color and transparency.
local function backgroundProperties(props: GuiObjectProps, properties: { [any]: any })
	local backgroundStyle = props.backgroundStyle
	if backgroundStyle == nil then
		return
	end
	if type(backgroundStyle) == "function" then
		table.insert(properties, Value.bindProperty("BackgroundColor3", Value.index(backgroundStyle, "Color3")))
		table.insert(
			properties,
			Value.bindProperty("BackgroundTransparency", Value.index(backgroundStyle, "Transparency"))
		)
	else
		properties.BackgroundColor3 = backgroundStyle.Color3
		properties.BackgroundTransparency = backgroundStyle.Transparency
	end
end

return {
	withGuiObjectProps = withGuiObjectProps,
	backgroundProperties = backgroundProperties,
}
