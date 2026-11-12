local Vide = require("../../Packages/Vide")

local ColorNamespace = require("../../Enums/ColorNamespace")
local InputSize = require("../../Enums/InputSize")
local Knob = require("../Knob")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local Types = require("../Types")
local View = require("../View")
local calculateSliderFraction = require("./calculateSliderFraction")
local create = require("../../Utility/create")
local getGuiInputPosition = require("./getGuiInputPosition")

type InputSize = InputSize.InputSize
type ColorStyleValue = Types.ColorStyleValue

local IS_INVERSE: PresentationContext.PresentationContextValue = {
	isIconSize = false,
	colorNamespace = ColorNamespace.Inverse,
}

export type KnobAppearance = {
	size: InputSize,
	style: ColorStyleValue,
	stroke: Types.Stroke?,
	hasShadow: boolean?,
}

export type SliderThumbProps = {
	track: () -> GuiObject?,
	fraction: () -> number,
	isVertical: () -> boolean,
	isDisabled: () -> boolean,
	isDragEnabled: () -> boolean,
	-- Required unless `knob` supplies the thumb's visual.
	knobAppearance: (() -> KnobAppearance)?,
	knob: Types.Children?,
	isContained: () -> boolean,
	onSeek: (fraction: number) -> (),
	getBounds: () -> (number, number),
	testId: string,
	onDragStarted: (() -> ())?,
	onDragEnded: (() -> ())?,
	Visible: Types.Value<boolean>?,
	LayoutOrder: number?,
	onAbsoluteSizeChanged: ((GuiObject) -> ())?,
}

--- One draggable thumb of a range slider: a knob over a drag target that seeks within `getBounds()`.
local function SliderThumb(props: SliderThumbProps): GuiObject
	local lastAcceptedFraction = Vide.untrack(props.fraction)

	local function onDragStart()
		lastAcceptedFraction = props.fraction()
		if props.onDragStarted then
			props.onDragStarted()
		end
	end

	local function onDrag(position: Vector2)
		local track = props.track()
		if not track then
			return
		end
		local fraction = calculateSliderFraction(getGuiInputPosition(position, track), track, props.isVertical())
		local minBound, maxBound = props.getBounds()
		local acceptedFraction = math.clamp(fraction, minBound, maxBound)
		if acceptedFraction ~= lastAcceptedFraction then
			lastAcceptedFraction = acceptedFraction
			props.onSeek(acceptedFraction)
		end
	end

	local function onDragEnd()
		if props.onDragEnded then
			props.onDragEnded()
		end
	end

	local dragTarget = View({
		tag = "size-full",
		ZIndex = 2,
		testId = `{props.testId}--drag-target`,
		children = Vide.show(props.isDragEnabled, function()
			return create("UIDragDetector")({
				Name = "DragDetector",
				DragStyle = Enum.UIDragDetectorDragStyle.Scriptable,
				DragStart = onDragStart,
				DragContinue = onDrag,
				DragEnd = onDragEnd,
				Enabled = function()
					return not props.isDisabled()
				end,
			})
		end),
	})
	dragTarget.Name = "DragTarget"

	local knob: GuiObject
	local customKnob = props.knob
	if customKnob ~= nil then
		if typeof(customKnob) == "Instance" then
			customKnob.Name = "Children"
		end
		knob = View({
			tag = "size-0-0 auto-xy",
			testId = `{props.testId}--custom-knob`,
			children = customKnob,
		})
	else
		local appearance = props.knobAppearance :: () -> KnobAppearance
		knob = PresentationContext.context(IS_INVERSE, function()
			return Knob({
				size = function()
					return appearance().size
				end,
				style = function()
					return appearance().style
				end,
				stroke = function()
					return appearance().stroke
				end,
				hasShadow = function()
					return appearance().hasShadow ~= false
				end,
				testId = `{props.testId}--knob`,
			})
		end)
	end
	knob.Name = "Knob"

	return View({
		tag = "size-0-0 auto-xy",
		AnchorPoint = function()
			if not props.isContained() then
				return Vector2.new(0.5, 0.5)
			end
			local fraction = props.fraction()
			return if props.isVertical() then Vector2.new(0.5, 1 - fraction) else Vector2.new(fraction, 0.5)
		end,
		Position = function()
			local fraction = props.fraction()
			return if props.isVertical() then UDim2.fromScale(0.5, 1 - fraction) else UDim2.fromScale(fraction, 0.5)
		end,
		ZIndex = 2,
		Visible = props.Visible,
		LayoutOrder = props.LayoutOrder,
		onAbsoluteSizeChanged = props.onAbsoluteSizeChanged,
		testId = props.testId,
		children = { dragTarget, knob },
	})
end

return SliderThumb
