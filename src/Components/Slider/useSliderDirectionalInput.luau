local Vide = require("../../Packages/Vide")

local Services = require("../../Utility/Wrappers/Services")

local SliderStepDirection = require("./SliderStepDirection")
type SliderStepDirection = SliderStepDirection.SliderStepDirection
local SliderStepSize = require("./SliderStepSize")
type SliderStepSize = SliderStepSize.SliderStepSize

local calculateAdjacentStepValue = require("./calculateAdjacentStepValue")
local constants = require("./constants")

local REVERSAL_SETTLE_REPORTS = 3
--* Held input repeats after about the OS typematic delay; continuous sliders then accelerate through cadence tiers,
--* while stepped sliders keep one logical step per 100 ms.
local INITIAL_REPEAT_DELAY = 0.4
local REPEAT_INTERVAL = 0.1
local MEDIUM_REPEAT_INTERVAL = 0.06
local FAST_REPEAT_INTERVAL = 0.03
local MEDIUM_REPEAT_START = 5
local FAST_REPEAT_START = 15

--* Page Up/Down are left out: the engine claims them to scroll an ancestor ScrollingFrame while the slider is
--* selected, and that core keybind cannot be sunk.
local function getStepForKeyCode(keyCode: Enum.KeyCode, isVertical: boolean): { sign: number, size: SliderStepSize }?
	local increment = if isVertical then constants.stepIncrement.vertical else constants.stepIncrement.horizontal
	local decrement = if isVertical then constants.stepDecrement.vertical else constants.stepDecrement.horizontal
	if table.find(increment, keyCode) then
		return { sign = 1, size = SliderStepSize.Step }
	elseif table.find(decrement, keyCode) then
		return { sign = -1, size = SliderStepSize.Step }
	end
	return nil
end

local function isExitKey(keyCode: Enum.KeyCode): boolean
	return table.find(constants.exit, keyCode) ~= nil
end

local function getRepeatInterval(repeatCount: number, step: number?): number
	if step ~= nil and step > 0 then
		return REPEAT_INTERVAL
	elseif repeatCount >= FAST_REPEAT_START then
		return FAST_REPEAT_INTERVAL
	elseif repeatCount >= MEDIUM_REPEAT_START then
		return MEDIUM_REPEAT_INTERVAL
	end
	return REPEAT_INTERVAL
end

export type Handlers = {
	getValue: () -> number,
	getStep: () -> number?,
	getRange: () -> NumberRange,
	onStep: (newValue: number) -> (),
	onExit: (() -> ())?,
}

--- Steps the slider along its axis with the arrow keys, the D-pad and the thumbstick while `isActive` is true,
--- repeating while the input is held; Backspace or B calls `onExit`. Call it while the component is being created.
local function useSliderDirectionalInput(isActive: () -> boolean, isVertical: () -> boolean, handlers: Handlers)
	Vide.effect(function()
		if not isActive() then
			return
		end
		local vertical = isVertical()

		local currentInput: InputObject? = nil
		local currentSign = 0
		local currentSize: SliderStepSize = SliderStepSize.Step
		local repeatThread: thread? = nil
		local thumbstickSign = 0
		local reversalReports = 0

		local function performStep(sign: number, size: SliderStepSize)
			local direction: SliderStepDirection = if sign > 0
				then SliderStepDirection.Increment
				else SliderStepDirection.Decrement
			handlers.onStep(
				calculateAdjacentStepValue(
					handlers.getValue(),
					direction,
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
				local repeatCount = 0
				while currentInput == input and currentSign == sign and currentSize == size do
					performStep(sign, size)
					repeatCount += 1
					task.wait(getRepeatInterval(repeatCount, handlers.getStep()))
				end
			end)
		end

		--* Keys and the D-pad arrive through InputBegan; the thumbstick only through InputChanged.
		local function evaluateInput(input: InputObject)
			if isExitKey(input.KeyCode) then
				if handlers.onExit then
					handlers.onExit()
				end
				return
			end

			local stepConfig = getStepForKeyCode(input.KeyCode, vertical)
			if stepConfig then
				startStepping(input, stepConfig.sign, stepConfig.size)
				return
			end

			if table.find(constants.analogStep, input.KeyCode) then
				local stepAxis = if vertical then input.Position.Y else input.Position.X
				if math.abs(stepAxis) >= constants.thumbstickDeadzone then
					local sign = if stepAxis > 0 then 1 else -1
					local isReversal = thumbstickSign ~= 0 and sign ~= thumbstickSign
					reversalReports = if isReversal then reversalReports + 1 else 0
					if isReversal and reversalReports < REVERSAL_SETTLE_REPORTS then
						stopStepping(input)
					else
						thumbstickSign = sign
						startStepping(input, sign, SliderStepSize.Step)
					end
				else
					thumbstickSign = 0
					reversalReports = 0
					stopStepping(input)
				end
			end
		end

		local function handleInputEnded(input: InputObject)
			if table.find(constants.analogStep, input.KeyCode) then
				thumbstickSign = 0
				reversalReports = 0
			end
			stopStepping(input)
		end

		Vide.untrack(function()
			Vide.cleanup(Services.UserInputService.InputBegan:Connect(evaluateInput))
			Vide.cleanup(Services.UserInputService.InputChanged:Connect(evaluateInput))
			Vide.cleanup(Services.UserInputService.InputEnded:Connect(handleInputEnded))
			Vide.cleanup(function()
				stopStepping(nil)
			end)
		end)
	end)
end

return useSliderDirectionalInput
