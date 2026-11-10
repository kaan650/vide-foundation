local Vide = require("../../Packages/Vide")

local ControlState = require("../../Enums/ControlState")
local Types = require("../../Components/Types")

type ControlState = ControlState.ControlState
type StateChangedCallback = Types.StateChangedCallback

local guiStateMapper: { [Enum.GuiState]: ControlState } = {
	[Enum.GuiState.Idle] = ControlState.Default,
	[Enum.GuiState.Hover] = ControlState.Hover,
	[Enum.GuiState.Press] = ControlState.Pressed,
	[Enum.GuiState.NonInteractable] = ControlState.Disabled,
}

--- Reports the GuiObject's control state: its GuiState, turned into Selected/SelectedPressed while it holds gamepad
--- selection. Call it from an action; the connections end with the calling scope.
local function useGuiControlState(guiObject: GuiObject, onStateChanged: StateChangedCallback)
	local isSelected = false
	local currentControlState: ControlState = ControlState.Initialize

	local function onControlStateChanged(newState: ControlState)
		if isSelected then
			if newState == ControlState.Default or newState == ControlState.Hover then
				newState = ControlState.Selected
			elseif newState == ControlState.Pressed then
				newState = ControlState.SelectedPressed
			end
		end
		if currentControlState == newState then
			return
		end
		currentControlState = newState
		onStateChanged(newState)
	end

	onControlStateChanged(guiStateMapper[guiObject.GuiState])

	Vide.cleanup(guiObject:GetPropertyChangedSignal("GuiState"):Connect(function()
		onControlStateChanged(guiStateMapper[guiObject.GuiState])
	end))
	--* Selection is not part of GuiState.
	Vide.cleanup(guiObject.SelectionGained:Connect(function()
		isSelected = true
		onControlStateChanged(currentControlState)
	end))
	Vide.cleanup(guiObject.SelectionLost:Connect(function()
		isSelected = false
		onControlStateChanged(currentControlState)
	end))
end

return useGuiControlState
