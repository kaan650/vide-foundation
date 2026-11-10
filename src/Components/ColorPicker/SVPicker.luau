local Vide = require("../../Packages/Vide")

local InputSize = require("../../Enums/InputSize")
local Knob = require("../Knob")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local colorUtils = require("./colorUtils")
local create = require("../../Utility/create")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")

type Value<T> = Types.Value<T>

export type SVPickerProps = {
	hue: () -> number,
	saturation: () -> number,
	value: () -> number,
	onChanged: (saturation: number, value: number) -> (),
	onDragStarted: (() -> ())?,
	onDragEnded: (() -> ())?,
	-- When false, the selection knob on the S/V gradient is hidden.
	showSelectionKnob: Value<boolean>?,
} & Types.CommonProps

local FADE_IN = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0),
})

--- The saturation/value square: saturation left to right, value bottom to top, dragged to pick both.
local function SVPicker(props: SVPickerProps): GuiObject
	local tokens = useTokens()
	local hue, saturation, value = props.hue, props.saturation, props.value

	local picker: GuiObject? = nil

	local function calculatePositionFromDrag(dragPosition: Vector2)
		local current = picker
		if not current then
			return
		end
		local newS, newV =
			colorUtils.calculateSVFromPosition(dragPosition, current.AbsolutePosition, current.AbsoluteSize)
		props.onChanged(newS, newV)
	end

	local onDragEnded = props.onDragEnded
	local dragDetector = create("UIDragDetector")({
		Name = "DragDetector",
		DragStyle = Enum.UIDragDetectorDragStyle.Scriptable,
		DragStart = function(inputPosition: Vector2)
			if props.onDragStarted then
				props.onDragStarted()
			end
			calculatePositionFromDrag(inputPosition)
		end,
		DragContinue = calculatePositionFromDrag,
		DragEnd = if onDragEnded
			then function()
				onDragEnded()
			end
			else nil,
	})

	local base = create("Frame")({
		Name = "Base",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = function()
			return tokens().Color.Extended.White.White_100.Color3 :: Color3
		end,
		ZIndex = 1,
		BorderSizePixel = 0,
	})

	local saturationLayer = create("Frame")({
		Name = "Saturation",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = function()
			return Color3.fromHSV(hue(), 1, 1)
		end,
		ZIndex = 2,
		BorderSizePixel = 0,
		create("UIGradient")({
			Name = "Gradient",
			Transparency = FADE_IN,
		}),
	})

	local valueLayer = create("Frame")({
		Name = "Value",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = function()
			return tokens().Color.Extended.Black.Black_100.Color3 :: Color3
		end,
		ZIndex = 3,
		BorderSizePixel = 0,
		create("UIGradient")({
			Name = "Gradient",
			Rotation = 90,
			Transparency = FADE_IN,
		}),
	})

	local knob = Vide.show(function()
		return Value.read(props.showSelectionKnob) ~= false
	end, function()
		local instance = Knob({
			size = InputSize.Medium,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = function()
				return UDim2.fromScale(saturation(), 1 - value())
			end,
			style = function()
				return {
					Color3 = Color3.fromHSV(hue(), saturation(), value()),
					Transparency = 0,
				}
			end,
			stroke = function(): Types.Stroke
				local current = tokens()
				return {
					Color = current.Color.System.Contrast.Color3,
					Thickness = current.Stroke.Thicker,
					Transparency = current.Color.System.Contrast.Transparency,
				}
			end,
			hasShadow = true,
			isStyleBinding = true,
			ZIndex = 4,
		})
		instance.Name = "Knob"
		return instance
	end)

	local root = View(withCommonProps(props, {
		tag = "size-full radius-small",
		ClipsDescendants = true,
		children = { dragDetector, base, saturationLayer, valueLayer, knob },
	}) :: any)
	picker = root
	return root
end

return SVPicker
