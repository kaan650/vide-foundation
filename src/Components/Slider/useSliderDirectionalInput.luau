local Vide = require("../../Packages/Vide")

local Services = require("../../Utility/Wrappers/Services")

local SliderStepDirection = require("./SliderStepDirection")
local SliderStepSize = require("./SliderStepSize")
type SliderStepSize = SliderStepSize.SliderStepSize

local calculateDirectionalStepValue = require("./calculateDirectionalStepValue")

-- Matches the CoreScripts Settings Slider deadzone.
local THUMBSTICK_DEADZONE = 0.8
--* Platform conventions for held navigation input: about the OS typematic delay, then a steady ~100 ms. L1/R1 page
--* steps cover fast traversal, so the fine step does not accelerate.
local INITIAL_REPEAT_DELAY = 0.4
local REPEAT_INTERVAL = 0.1

--* Page Up/Down are left out: the engine claims them to scroll an ancestor ScrollingFrame while the slider is
--* selected, and that core keybind cannot be sunk.
local function getStepForKeyCode(keyCode: Enum.KeyCode): { sign: number, size: SliderStepSize }?
	if keyCode == Enum.KeyCode.Right or keyCode == Enum.KeyCode.DPadRight then
		return { sign = 1, size = SliderStepSize.Step }
	elseif keyCode == Enum.KeyCode.Left or keyCode == Enum.KeyCode.DPadLeft then
		return { sign = -1, size = SliderStepSize.Step }
	elseif keyCode == Enum.KeyCode.ButtonR1 then
		return { sign = 1, size = SliderStepSize.Page }
	elseif keyCode == Enum.KeyCode.ButtonL1 then
		return { sign = -1, size = SliderStepSize.Page }
	end
	return nil
end

export type Handlers = {
	getValue: () -> number,
	getStep: () -> number?,
	getRange: () -> NumberRange,
	onStep: (newValue: number) -> (),
}

--- Steps the slider with arrow keys, the D-pad, the thumbstick and the bumpers while `isActive` is true, repeating
--- while the input is held. Call it while the component is being created.
local function useSliderDirectionalInput(isActive: () -> boolean, handlers: Handlers)
	Vide.effect(function()
		if not isActive() then
			return
		end

		local currentInput: InputObject? = nil
		local currentSign = 0
		local currentSize: SliderStepSize = SliderStepSize.Step
		local repeatThread: thread? = nil

		local function performStep(sign: number, size: SliderStepSize)
			handlers.onStep(
				calculateDirectionalStepValue(
					handlers.getValue(),
					if sign > 0 then SliderStepDirection.Increment else SliderStepDirection.Decrement,
					handlers.getRange(),
					handlers.getStep(),
					size
				)
			)
		end

		local function stopStepping(input: InputObject?)
			if input ~= nil and input ~= currentInput then
				return
			end
			currentInput = nil
			currentSign = 0
			if repeatThread then
				task.cancel(repeatThread)
				repeatThread = nil
			end
		end

		local function startStepping(input: InputObject, sign: number, size: SliderStepSize)
			if input == currentInput and sign == currentSign and size == currentSize then
				return
			end

			stopStepping(nil)
			currentInput = input
			currentSign = sign
			currentSize = size

			performStep(sign, size)

			repeatThread = task.spawn(function()
				task.wait(INITIAL_REPEAT_DELAY)
				while currentInput == input and currentSign == sign and currentSize == size do
					performStep(sign, size)
					task.wait(REPEAT_INTERVAL)
				end
			end)
		end

		--* Keys, the D-pad and the bumpers arrive through InputBegan; the thumbstick only through InputChanged.
		local function evaluateInput(input: InputObject)
			local stepConfig = getStepForKeyCode(input.KeyCode)
			if stepConfig then
				startStepping(input, stepConfig.sign, stepConfig.size)
				return
			end

			if input.KeyCode == Enum.KeyCode.Thumbstick1 then
				if math.abs(input.Position.X) >= THUMBSTICK_DEADZONE then
					startStepping(input, if input.Position.X > 0 then 1 else -1, SliderStepSize.Step)
				else
					stopStepping(input)
				end
			end
		end

		Vide.untrack(function()
			Vide.cleanup(Services.UserInputService.InputBegan:Connect(evaluateInput))
			Vide.cleanup(Services.UserInputService.InputChanged:Connect(evaluateInput))
			Vide.cleanup(Services.UserInputService.InputEnded:Connect(function(input: InputObject)
				stopStepping(input)
			end))
			Vide.cleanup(function()
				stopStepping(nil)
			end)
		end)
	end)
end

return useSliderDirectionalInput
