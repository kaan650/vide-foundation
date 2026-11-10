local Tokens = require("../../Providers/Style/Tokens")
local Types = require("../Types")
type Tokens = Tokens.Tokens
type StateLayer = Types.StateLayer

local ColorNamespace = require("../../Enums/ColorNamespace")
type ColorNamespace = ColorNamespace.ColorNamespace
local StateLayerMode = require("../../Enums/StateLayerMode")
type StateLayerMode = StateLayerMode.StateLayerMode
local ControlState = require("../../Enums/ControlState")
type ControlState = ControlState.ControlState

local function guiStateToStateLayer(guiState: ControlState): "Idle" | "Press" | "Hover"
	if guiState == ControlState.Pressed then
		return "Press"
	elseif guiState == ControlState.SelectedPressed then
		return "Press"
	elseif guiState == ControlState.Hover then
		return "Hover"
	end

	return "Idle"
end

local function stateLayerModeToTokenNamespace(mode: StateLayerMode?): ColorNamespace
	if mode == StateLayerMode.Default then
		return ColorNamespace.Color
	elseif mode == StateLayerMode.Inverse then
		return ColorNamespace.Inverse
	elseif mode == StateLayerMode.Light then
		return ColorNamespace.LightMode
	elseif mode == StateLayerMode.Dark then
		return ColorNamespace.DarkMode
	end
	-- Default to Color
	return ColorNamespace.Color
end

local function getStateLayerStyle(
	tokens: Tokens,
	mode: StateLayerMode?,
	guiState: ControlState
): { Color3: Color3, Transparency: number }
	local colorNamespace = stateLayerModeToTokenNamespace(mode)
	local stateLayerState = guiStateToStateLayer(guiState)

	local stateLayerStyle = ((tokens :: any)[colorNamespace] :: any).State[stateLayerState]

	return stateLayerStyle
end

return getStateLayerStyle
