local Vide = require("../../Packages/Vide")

local ColorNamespace = require("../../Enums/ColorNamespace")
local Constants = require("../../Constants")
local ControlState = require("../../Enums/ControlState")
local CursorComponent = require("../../Providers/Cursor/CursorComponent")
local CursorType = require("../../Enums/CursorType")
local InputMode = require("../../Utility/Input/InputMode")
local InputSize = require("../../Enums/InputSize")
local Knob = require("../Knob")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local SliderVariant = require("../../Enums/SliderVariant")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local Visibility = require("../../Enums/Visibility")
local calculateSliderStepValue = require("./calculateSliderStepValue")
local calculateSliderValueFromPosition = require("./calculateSliderValueFromPosition")
local create = require("../../Utility/create")
local getKnobSize = require("../Knob/getKnobSize")
local useLastInputMode = require("../../Utility/Input/useLastInputMode")
local useSliderDirectionalInput = require("./useSliderDirectionalInput")
local useSliderVariants = require("./useSliderVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ControlState = ControlState.ControlState
type InputSize = InputSize.InputSize
type SliderVariant = SliderVariant.SliderVariant
type Visibility = Visibility.Visibility
type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

--* The largest DragUDim2 jump seen from real dragging; a bigger one comes from directional input snapping the drag
--* origin back to the center. UIDragDetector's speed properties can change this.
local MAX_DIRECTIONAL_INPUT_DRAG_DELTA = 0.01

export type SliderProps = {
	value: Value<number>,
	range: Value<NumberRange>?,

	size: Value<InputSize>?,
	width: Value<UDim>?,
	variant: Value<SliderVariant>?,
	isDisabled: Value<boolean>?,
	isContained: Value<boolean>?,
	knobVisibility: Value<Visibility>?,
	-- Replaces the default knob.
	knob: Types.Children?,
	step: Value<number?>?,

	onValueChanged: ((newValue: number) -> ())?,
	onDragStarted: (() -> ())?,
	onDragEnded: (() -> ())?,
} & Types.CommonProps

local defaultProps = {
	range = NumberRange.new(0, 1),
	size = InputSize.Medium,
	width = UDim.new(1, 0),
	variant = SliderVariant.Standard,
	isDisabled = false,
	isContained = false,
	knobVisibility = Visibility.Auto,
	testId = "--foundation-slider",
}

local IS_INVERSE: PresentationContext.PresentationContextValue = {
	isIconSize = false,
	colorNamespace = ColorNamespace.Inverse,
}

local DIRECTIONAL_SELECTION_GROUP: Types.SelectionGroup = {
	SelectionBehaviorLeft = Enum.SelectionBehavior.Stop,
	SelectionBehaviorRight = Enum.SelectionBehavior.Stop,
	SelectionBehaviorUp = Enum.SelectionBehavior.Escape,
	SelectionBehaviorDown = Enum.SelectionBehavior.Escape,
}

local KNOB_POSITION = UDim2.fromScale(1, 0.5)

--- A horizontal track whose knob is dragged, pressed or stepped with directional input to pick a value in `range`.
local function Slider(sliderProps: SliderProps): GuiObject
	local props = withDefaults(sliderProps, defaultProps)
	local tokens = useTokens()
	local colorNamespace = PresentationContext.usePresentationContext().colorNamespace
	local lastInputMode = useLastInputMode()

	local controlState = Vide.source(ControlState.Initialize :: ControlState)
	local isDragging = Vide.source(false)
	local customKnobSize = Vide.source(Vector2.zero)

	local function range(): NumberRange
		return Value.read(props.range)
	end
	local function step(): number?
		return Value.read(props.step)
	end
	local function size(): InputSize
		return Value.read(props.size)
	end
	local function isDisabled(): boolean
		return Value.read(props.isDisabled) == true
	end
	local function value(): number
		local current = range()
		return math.clamp(Value.read(props.value), current.Min, current.Max)
	end
	local function fraction(): number
		local current = range()
		return (value() - current.Min) / (current.Max - current.Min)
	end

	local variant = Vide.derive(function()
		return useSliderVariants(tokens(), size(), Value.read(props.variant))
	end)

	local function isSelected(): boolean
		local state = controlState()
		return state == ControlState.Selected or state == ControlState.SelectedPressed
	end

	local isKnobVisible = Vide.derive(function(): boolean
		local visibility: Visibility = Value.read(props.knobVisibility)
		if visibility == Visibility.None then
			return isSelected()
		elseif visibility == Visibility.Always then
			return true
		end
		local state = controlState()
		return isDragging()
			or state == ControlState.Hover
			or state == ControlState.Selected
			or state == ControlState.Pressed
	end)

	local function knobStyle(): ColorStyleValue
		local knob = variant().knob
		if not isKnobVisible() then
			return { Color3 = knob.style.Color3, Transparency = 1 }
		end
		return if isDragging() then knob.dragStyle else knob.style
	end

	local function steppedValue(newValue: number): number
		local currentStep = step()
		return if currentStep then calculateSliderStepValue(newValue, currentStep, range()) else newValue
	end

	local function updateValue(newValue: number)
		if newValue ~= value() and props.onValueChanged then
			props.onValueChanged(newValue)
		end
	end

	useSliderDirectionalInput(function()
		return isSelected() and not isDisabled()
	end, {
		getValue = value,
		getStep = step,
		getRange = range,
		onStep = function(newValue: number)
			updateValue(steppedValue(newValue))
		end,
	})

	local root: GuiObject? = nil
	-- The fraction seeked to on DragStart; DragUDim2 deltas are relative to it.
	local dragStartFraction = 0
	-- The previous DragUDim2 scale, to spot the engine resetting the drag origin when directional input turns.
	local lastDragUDim2 = 0

	local function onDragStarted(inputPosition: Vector2)
		isDragging(true)
		if props.onDragStarted then
			props.onDragStarted()
		end

		lastDragUDim2 = 0
		local currentRange = range()
		local rangeSpan = currentRange.Max - currentRange.Min

		if lastInputMode() == InputMode.Directional then
			--* Directional input has no press position, so drags start from the current value.
			dragStartFraction = (value() - currentRange.Min) / rangeSpan
			return
		end

		--* DragUDim2 only reports movement after the grab, so seek to the press point now.
		local pressValue = if root
			then calculateSliderValueFromPosition(inputPosition, root, currentRange)
			else currentRange.Min
		dragStartFraction = (pressValue - currentRange.Min) / rangeSpan
		updateValue(steppedValue(pressValue))
	end

	local dragDetector: UIDragDetector

	local function onDrag()
		local currentRange = range()
		local rangeSpan = currentRange.Max - currentRange.Min
		local delta = dragDetector.DragUDim2.X.Scale

		if
			lastInputMode() == InputMode.Directional
			and math.abs(delta - lastDragUDim2) > MAX_DIRECTIONAL_INPUT_DRAG_DELTA
		then
			--* Re-anchor to the current value so the knob stays put instead of snapping back.
			dragStartFraction = (value() - currentRange.Min) / rangeSpan - delta
			lastDragUDim2 = delta
			return
		end
		lastDragUDim2 = delta

		local newFraction = math.clamp(dragStartFraction + delta, 0, 1)
		updateValue(steppedValue(currentRange.Min + newFraction * rangeSpan))
	end

	local function onDragEnded()
		isDragging(false)
		if props.onDragEnded then
			props.onDragEnded()
		end
	end

	dragDetector = create("UIDragDetector")({
		Name = "DragDetector",
		DragStyle = Enum.UIDragDetectorDragStyle.TranslateLine,
		DragAxis = Vector2.new(1, 0),
		ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomScale,
		DragRelativity = Enum.UIDragDetectorDragRelativity.Absolute,
		SelectionModeDragSpeed = UDim2.new(),
		Enabled = function()
			return not isDisabled()
		end,
		DragStart = onDragStarted,
		DragContinue = onDrag,
		DragEnd = onDragEnded,
	})
	--* Keeps the seeked fraction plus the drag delta within [0, 1], so the knob stops at the ends.
	local constraint = dragDetector:AddConstraintFunction(1, function(proposedPosition: UDim2, proposedRotation: number)
		local clampedDelta = math.clamp(proposedPosition.X.Scale, -dragStartFraction, 1 - dragStartFraction)
		return UDim2.fromScale(clampedDelta, 0), proposedRotation
	end)
	Vide.cleanup(constraint)

	local function knobAnchorPoint(): Vector2
		return if Value.read(props.isContained) then Vector2.new(fraction(), 0.5) else Vector2.new(0.5, 0.5)
	end

	local selectionCursor = Vide.show(isSelected, function()
		local cursor = CursorComponent({
			cornerRadius = UDim.new(0.5, 0),
			offset = Vide.untrack(tokens).Padding.XSmall,
			borderWidth = Vide.untrack(tokens).Stroke.Thicker,
			colorNamespace = colorNamespace,
		})
		cursor.Name = "Cursor"
		local view = View({
			Size = function()
				if props.knob then
					local knobSize = customKnobSize()
					return UDim2.fromOffset(knobSize.X, knobSize.Y)
				end
				return getKnobSize(tokens(), size())
			end,
			AnchorPoint = knobAnchorPoint,
			Position = KNOB_POSITION,
			testId = `{props.testId}--selection-cursor`,
			children = cursor,
		})
		view.Name = "SelectionCursor"
		return view
	end)

	local knob: GuiObject
	local customKnob = props.knob
	if customKnob ~= nil then
		if typeof(customKnob) == "Instance" then
			customKnob.Name = "Children"
		end
		knob = View({
			tag = "size-0-0 auto-xy",
			AnchorPoint = knobAnchorPoint,
			Position = KNOB_POSITION,
			Visible = isKnobVisible,
			onAbsoluteSizeChanged = function(instance: GuiObject)
				customKnobSize(instance.AbsoluteSize)
			end,
			testId = `{props.testId}--custom-knob`,
			children = customKnob,
		})
	else
		knob = PresentationContext.context(IS_INVERSE, function()
			return Knob({
				AnchorPoint = knobAnchorPoint,
				Position = KNOB_POSITION,
				size = size,
				style = knobStyle,
				stroke = function()
					return variant().knob.stroke
				end,
				hasShadow = function()
					return variant().knob.hasShadow ~= false
				end,
				testId = `{props.testId}--knob`,
			})
		end)
	end
	knob.Name = "Knob"

	local fill = View({
		tag = function()
			return variant().fill.tag
		end,
		Size = function()
			return UDim2.fromScale(fraction(), 1)
		end,
		testId = `{props.testId}--fill`,
		children = { selectionCursor, knob },
	})
	fill.Name = "Fill"

	local bar = View({
		tag = function()
			return variant().bar.tag
		end,
		testId = `{props.testId}--bar`,
		children = fill,
	})
	bar.Name = "Bar"

	--* Foundation makes a disabled slider a CanvasGroup. A source can enable it later, and the root cannot change
	--* class, so a reactive isDisabled always gets a CanvasGroup, selectable only while enabled.
	local isDisabledReactive = type(props.isDisabled) == "function"
	local groupTransparency: Value<number>? = if isDisabledReactive
		then function()
			return if isDisabled() then Constants.DISABLED_TRANSPARENCY else 0
		end
		elseif props.isDisabled == true then Constants.DISABLED_TRANSPARENCY
		else nil

	root = View(withCommonProps(props, {
		Size = function()
			return UDim2.new(Value.read(props.width), UDim.new(0, variant().hitbox.height))
		end,
		GroupTransparency = groupTransparency,
		stateLayer = {
			affordance = StateLayerAffordance.None,
		},
		selectionGroup = DIRECTIONAL_SELECTION_GROUP,
		selection = if isDisabledReactive
			then {
				Selectable = function()
					return not isDisabled()
				end,
			}
			else nil,
		cursor = CursorType.Invisible,
		onStateChanged = function(state: ControlState)
			controlState(state)
		end,
		isDisabled = props.isDisabled,
		children = { dragDetector, bar },
	}) :: any)
	dragDetector.ReferenceUIInstance = root

	return root :: GuiObject
end

return Slider
