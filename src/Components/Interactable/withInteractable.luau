local Vide = require("../../Packages/Vide")

local ControlState = require("../../Enums/ControlState")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local StateLayerMode = require("../../Enums/StateLayerMode")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local blendColors = require("../../Utility/blendColors")
local getStateLayerStyle = require("./getStateLayerStyle")
local useCursor = require("../../Providers/Cursor/useCursor")
local useGuiControlState = require("../../Utility/Control/useGuiControlState")
local useTokens = require("../../Providers/Style/useTokens")

type ControlState = ControlState.ControlState
type StateLayerAffordance = StateLayerAffordance.StateLayerAffordance
type StateLayerMode = StateLayerMode.StateLayerMode
type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

export type WithInteractableProps = {
	BackgroundColor3: Value<Color3?>?,
	BackgroundTransparency: Value<number?>?,
	SelectionImageObject: Value<GuiObject?>?,
	cursor: Types.Cursor?,
} & Types.BaseInteractableProps

--* Engine default for BackgroundColor3; a GetStyled value equal to it with no transparency means "never styled".
local DEFAULT_GRAY = Color3.fromRGB(163, 162, 165)

--- Turns `properties` into an interactable GuiObject's: state-layer background, activation events, control state
--- and selection cursor. Foundation's Interactable, as properties for the caller's own `create` call.
local function withInteractable(props: WithInteractableProps, properties: { [any]: any }): { [any]: any }
	local tokens = useTokens()
	local cursor = useCursor(props.cursor)
	local controlState = Vide.source(ControlState.Initialize :: ControlState)
	local instance: GuiObject? = nil
	local realBackgroundStyle: ColorStyleValue? = nil

	local function onStateChanged(newState: ControlState)
		if Vide.untrack(controlState) == ControlState.Default and instance ~= nil then
			--* Remember the styled background before the state layer overrides it, to blend over it.
			local color3 = instance:GetStyled("BackgroundColor3")
			local transparency = instance:GetStyled("BackgroundTransparency")
			if color3 ~= DEFAULT_GRAY or transparency ~= 0 then
				realBackgroundStyle = { Color3 = color3, Transparency = transparency }
			end
		end
		controlState(newState)
		if props.onStateChanged ~= nil then
			props.onStateChanged(newState)
		end
	end

	local stateLayer = props.stateLayer
	local mode = function(): StateLayerMode?
		return if stateLayer then Value.read(stateLayer.mode) else nil
	end
	local affordance = function(): StateLayerAffordance?
		return if stateLayer then Value.read(stateLayer.affordance) else nil
	end

	local background = Vide.derive(function(): ColorStyleValue
		local state = controlState()
		local backgroundStyle: ColorStyleValue = {
			Color3 = Value.read(props.BackgroundColor3),
			Transparency = Value.read(props.BackgroundTransparency),
		}
		if
			state == ControlState.Initialize
			or state == ControlState.Default
			or state == ControlState.Disabled
			or affordance() == StateLayerAffordance.None
		then
			return backgroundStyle
		end

		local finalBackgroundStyle: ColorStyleValue = {
			Color3 = backgroundStyle.Color3,
			Transparency = backgroundStyle.Transparency,
		}
		if finalBackgroundStyle.Color3 == nil and realBackgroundStyle then
			finalBackgroundStyle.Color3 = realBackgroundStyle.Color3
		end
		if finalBackgroundStyle.Transparency == nil and realBackgroundStyle then
			finalBackgroundStyle.Transparency = realBackgroundStyle.Transparency
		end

		return blendColors(finalBackgroundStyle, getStateLayerStyle(tokens(), mode(), state))
	end)

	local function isDisabled(): boolean
		return Value.read(props.isDisabled) == true
	end

	properties.BackgroundColor3 = nil
	properties.BackgroundTransparency = nil
	table.insert(
		properties,
		Value.bindProperty("BackgroundColor3", function()
			return background().Color3
		end)
	)
	table.insert(
		properties,
		Value.bindProperty("BackgroundTransparency", function()
			return background().Transparency
		end)
	)

	properties.Active = function()
		return not isDisabled()
	end
	properties.Interactable = function()
		return not isDisabled()
	end

	local onActivated = props.onActivated
	if onActivated then
		properties.Activated = function(inputObject: InputObject, clickCount: number)
			if not Vide.untrack(isDisabled) and instance then
				onActivated(instance, inputObject, clickCount)
			end
		end
	end
	local onSecondaryActivated = props.onSecondaryActivated
	if onSecondaryActivated then
		properties.SecondaryActivated = function(inputObject: InputObject)
			if not Vide.untrack(isDisabled) and instance then
				onSecondaryActivated(instance, inputObject)
			end
		end
	end

	properties.SelectionImageObject = props.SelectionImageObject or cursor

	table.insert(
		properties,
		Vide.action(function(created: Instance)
			instance = created :: GuiObject
			useGuiControlState(created :: GuiObject, onStateChanged)
		end)
	)

	return properties
end

return withInteractable
