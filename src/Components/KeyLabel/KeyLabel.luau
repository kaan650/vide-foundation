local Vide = require("../../Packages/Vide")

local UserInputService = require("../../Utility/Wrappers").Services.UserInputService

local CircularProgressBar = require("../CircularProgressBar")
local Image = require("../Image")
local Motion = require("../../Utility/Motion")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local create = require("../../Utility/create")
local getVisualForKey = require("./getVisualForKey")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

export type HoldBehavior = {
	-- Seconds the key has to be held to activate.
	holdTime: number?,
	-- Seconds the indicator takes to empty when the key is released before activating.
	resetTime: number?,
	-- Called when the key is released early (false) or has been held for `holdTime` (true).
	onEndHold: (didActivate: boolean) -> (),
	-- Called when the key starts being held.
	onBeginHold: (() -> ())?,
}

export type KeyLabelProps = {
	keyCode: Value<Enum.KeyCode>,
	holdBehavior: HoldBehavior?,
	Size: Value<UDim2>?,
} & Types.CommonProps

local defaultHoldBehavior = {
	holdTime = 1,
	resetTime = 0.5,
}

local defaultProps = {
	testId = "--foundation-key-label",
}

local SLICE_CENTER = Rect.new(Vector2.new(10, 9), Vector2.new(25, 25))
local KEY_TAG = "position-center-center anchor-center-center"

--- A keyboard or gamepad key. With `holdBehavior`, holding the key fills a ring around it.
local function KeyLabel(keyLabelProps: KeyLabelProps): GuiObject
	local props = withDefaults(keyLabelProps, defaultProps)
	local holdBehavior = if props.holdBehavior then withDefaults(props.holdBehavior, defaultHoldBehavior) else nil
	local tokens = useTokens()

	-- The last InputObject for the key while it is held.
	local inputObject = Vide.source(nil :: InputObject?)
	local getInputObject: () -> InputObject? = inputObject :: any

	local setProgress: (goal: Motion.Goal) -> ()
	local progress: () -> number
	progress, setProgress = Motion.useAnimatedBinding(0, function(value: number)
		if holdBehavior and value == 1 and getInputObject() then
			setProgress(Motion.ease(0, {
				duration = holdBehavior.resetTime,
				easingStyle = Enum.EasingStyle.Linear,
			}))
			inputObject(nil)
			holdBehavior.onEndHold(true)
		end
	end)

	local keyVisual = Vide.derive(function()
		return getVisualForKey(Value.read(props.keyCode))
	end)

	local function contentStyle(): ColorStyleValue
		local color = tokens().Color.Content
		return (if getInputObject() then color.Emphasis else color.Muted) :: ColorStyleValue
	end
	local function keySize(): UDim2
		return keyVisual().size
	end
	local function key(): string
		return keyVisual().key
	end

	local keyImage = Vide.switch(function()
		return keyVisual().keyVisualType
	end)({
		Image = function()
			local image = Image({
				Image = key,
				Size = keySize,
				imageStyle = contentStyle,
				tag = KEY_TAG,
			})
			image.Name = "Image"
			return image
		end,
		String = function()
			local label = Text({
				Text = key,
				textStyle = contentStyle,
				tag = "size-full-full auto-xy text-body-medium text-align-x-center",
			})
			label.Name = "Text"

			local image = Image({
				Image = "icons/controls/keys/key_single",
				Size = keySize,
				ScaleType = Enum.ScaleType.Slice,
				imageStyle = contentStyle,
				slice = { center = SLICE_CENTER },
				tag = KEY_TAG,
				children = {
					create("UIPadding")({
						Name = "CustomPadding",
						PaddingBottom = UDim.new(0, 3),
					}),
					label,
				},
			})
			image.Name = "Image"
			return image
		end,
	})

	local indicator: GuiObject? = nil
	if holdBehavior then
		if (holdBehavior.holdTime :: number) > 0 then
			indicator = CircularProgressBar({
				progress = progress,
				testId = `{props.testId}--indicator`,
			})
			indicator.Name = "Indicator"
		end

		Vide.cleanup(UserInputService.InputBegan:Connect(function(input: InputObject)
			if getInputObject() or input.KeyCode ~= Value.read(props.keyCode) then
				return
			end
			if holdBehavior.onBeginHold then
				holdBehavior.onBeginHold()
			end
			if holdBehavior.holdTime == 0 then
				holdBehavior.onEndHold(true)
				return
			end
			inputObject(input)
			setProgress(Motion.ease(1, {
				duration = (1 - progress()) * (holdBehavior.holdTime :: number),
				easingStyle = Enum.EasingStyle.Linear,
			}))
		end))

		Vide.cleanup(UserInputService.InputEnded:Connect(function(input: InputObject)
			if input ~= getInputObject() then
				return
			end
			holdBehavior.onEndHold(false)
			inputObject(nil)
			setProgress(Motion.ease(0, {
				duration = progress() * (holdBehavior.resetTime :: number),
				easingStyle = Enum.EasingStyle.Linear,
			}))
		end))
	end

	return View(withCommonProps(props, {
		Size = props.Size,
		children = { keyImage, indicator },
	}) :: any)
end

return KeyLabel
