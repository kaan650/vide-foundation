local Vide = require("../../Packages/Vide")

local ColorNamespace = require("../../Enums/ColorNamespace")
local Constants = require("../../Constants")
local ControlState = require("../../Enums/ControlState")
local CursorComponent = require("../../Providers/Cursor/CursorComponent")
local CursorType = require("../../Enums/CursorType")
local InputMode = require("../../Utility/Input/InputMode")
local InputSize = require("../../Enums/InputSize")
local Knob = require("../Knob")
local Orientation = require("../../Enums/Orientation")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local Services = require("../../Utility/Wrappers/Services")
local SliderThumb = require("./SliderThumb")
local SliderType = require("../../Enums/SliderType")
local SliderVariant = require("../../Enums/SliderVariant")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local Visibility = require("../../Enums/Visibility")
local blendTransparencies = require("../../Utility/blendTransparencies")
local calculateSliderFraction = require("./calculateSliderFraction")
local calculateSliderStepValue = require("./calculateSliderStepValue")
local create = require("../../Utility/create")
local getGuiInputPosition = require("./getGuiInputPosition")
local getKnobSize = require("../Knob/getKnobSize")
local getSelectionEntryDirection = require("./getSelectionEntryDirection")
local useLastInputMode = require("../../Utility/Input/useLastInputMode")
local useSliderCaptureKeys = require("./useSliderCaptureKeys")
local useSliderDirectionalInput = require("./useSliderDirectionalInput")
local useSliderVariants = require("./useSliderVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ControlState = ControlState.ControlState
type InputSize = InputSize.InputSize
type Orientation = Orientation.Orientation
type SliderType = SliderType.SliderType
type SliderVariant = SliderVariant.SliderVariant
type Visibility = Visibility.Visibility
type ColorStyleValue = Types.ColorStyleValue
type Stroke = Types.Stroke
type Value<T> = Types.Value<T>

local GuiService = Services.GuiService

--* The largest DragUDim2 jump seen from real dragging; a bigger one comes from directional input snapping the drag
--* origin back to the center. UIDragDetector's speed properties can change this.
local MAX_DIRECTIONAL_INPUT_DRAG_DELTA = 0.01

type CommonSliderProps = {
	-- Minimum and maximum values. Defaults to 0 to 1.
	range: Value<NumberRange>?,
	size: Value<InputSize>?,
	-- Length of the track: its width, or its height when vertical.
	width: Value<UDim>?,
	-- A vertical slider fills upward from the bottom.
	orientation: Value<Orientation>?,
	variant: Value<SliderVariant>?,
	isDisabled: Value<boolean>?,
	isContained: Value<boolean>?,
	knobVisibility: Value<Visibility>?,
	-- Replaces the default knob. A range slider has two, so it takes a function that builds one, called per thumb.
	knob: Types.Children?,
	step: Value<number?>?,

	onDragStarted: (() -> ())?,
	onDragEnded: (() -> ())?,
} & Types.CommonProps

export type SingleSliderProps = {
	type: typeof(SliderType.Single)?,
	value: Value<number>,
	onValueChanged: ((newValue: number) -> ())?,
} & CommonSliderProps

export type RangeSliderProps = {
	-- Fixed for the life of the slider.
	type: typeof(SliderType.Range),
	value: Value<NumberRange>,
	onValueChanged: ((newValue: NumberRange) -> ())?,
} & CommonSliderProps

--* One table type rather than `SingleSliderProps | RangeSliderProps`: the solver cannot check a table literal against
--* a union of intersections. Both narrower types are subtypes of it.
export type SliderProps = {
	-- `SliderType.Range` picks an interval with two thumbs. Fixed for the life of the slider.
	type: SliderType?,
	-- A number, or a NumberRange for a range slider.
	value: Value<number> | Value<NumberRange>,
	onValueChanged: ((newValue: any) -> ())?,
} & CommonSliderProps

local defaultProps = {
	range = NumberRange.new(0, 1),
	size = InputSize.Medium,
	width = UDim.new(1, 0),
	orientation = Orientation.Horizontal,
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

--* The capture cursor is its own selection group, so directional input while captured cannot move off the knob onto
--* another selectable inside the slider: the root group's Stop only blocks leaving the group.
local CAPTURE_CURSOR_SELECTION_GROUP: Types.SelectionGroup = {
	SelectionBehaviorLeft = Enum.SelectionBehavior.Stop,
	SelectionBehaviorRight = Enum.SelectionBehavior.Stop,
	SelectionBehaviorUp = Enum.SelectionBehavior.Stop,
	SelectionBehaviorDown = Enum.SelectionBehavior.Stop,
}

--- A track whose knob is dragged, pressed or (once captured with Enter or A) stepped with directional input to pick a
--- value in `range`; `SliderType.Range` picks an interval with two thumbs.
local function Slider(sliderProps: SliderProps): GuiObject
	local props = withDefaults(sliderProps, defaultProps)
	local isRange = props.type == SliderType.Range
	local tokens = useTokens()
	local colorNamespace = PresentationContext.usePresentationContext().colorNamespace
	local lastInputMode = useLastInputMode()

	local controlState = Vide.source(ControlState.Initialize :: ControlState)
	local isDragging = Vide.source(false)
	local isCaptured = Vide.source(false)
	local isMaxThumbActive = Vide.source(false)
	local rangeDragIsMaxKnob = Vide.source(false)
	local customKnobSize = Vide.source(Vector2.zero)
	local minDragTranslation = Vide.source(UDim2.new())
	local maxDragTranslation = Vide.source(UDim2.new())

	local root: GuiObject? = nil
	local focusTarget: GuiObject? = nil
	local captureTarget: GuiObject? = nil

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
	local function isVertical(): boolean
		return Value.read(props.orientation) == Orientation.Vertical
	end
	local function isContained(): boolean
		return Value.read(props.isContained) == true
	end

	local function toFraction(rawValue: number): number
		local current = range()
		return math.clamp((rawValue - current.Min) / (current.Max - current.Min), 0, 1)
	end
	local function rawValueFromFraction(fraction: number): number
		local current = range()
		return current.Min + fraction * (current.Max - current.Min)
	end
	local function steppedValue(rawValue: number): number
		local currentStep = step()
		return if currentStep then calculateSliderStepValue(rawValue, currentStep, range()) else rawValue
	end

	local function value(): number
		local current = range()
		return math.clamp(Value.read(props.value) :: number, current.Min, current.Max)
	end
	local function fraction(): number
		return toFraction(value())
	end
	local function rangeValue(): NumberRange
		return Value.read(props.value) :: NumberRange
	end
	local function minFraction(): number
		return toFraction(rangeValue().Min)
	end
	local function maxFraction(): number
		return toFraction(rangeValue().Max)
	end

	local variant = Vide.derive(function()
		return useSliderVariants(tokens(), size(), Value.read(props.variant))
	end)

	local function isSelected(): boolean
		local state = controlState()
		return state == ControlState.Selected or state == ControlState.SelectedPressed or isCaptured()
	end
	local function isDirectionalInput(): boolean
		return lastInputMode() == InputMode.Directional and isSelected()
	end

	local isKnobVisible = Vide.derive(function(): boolean
		if isDisabled() then
			return false
		end
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
		elseif isDragging() and not isRange then
			return knob.dragStyle
		end
		return knob.style
	end

	local function knobStroke(): Stroke?
		local stroke = variant().knob.stroke
		if stroke == nil then
			return nil
		end
		local transparency = stroke.Transparency
		return {
			Color = stroke.Color,
			Thickness = stroke.Thickness,
			Transparency = blendTransparencies(
				if typeof(transparency) == "number" then transparency else nil,
				if isKnobVisible() then 0 else 1
			),
		}
	end

	local function updateValue(newValue: number)
		if newValue ~= Vide.untrack(value) and props.onValueChanged then
			props.onValueChanged(newValue)
		end
	end

	local function updateRange(newRange: NumberRange)
		local current = Vide.untrack(rangeValue)
		if
			props.onValueChanged
			and (typeof(current) ~= "NumberRange" or newRange.Min ~= current.Min or newRange.Max ~= current.Max)
		then
			props.onValueChanged(newRange)
		end
	end

	useSliderCaptureKeys(function()
		return isSelected() and not isDisabled()
	end, function()
		if Vide.untrack(isCaptured) then
			if isRange then
				isMaxThumbActive(not Vide.untrack(isMaxThumbActive))
			end
		else
			isCaptured(true)
		end
	end)

	Vide.effect(function()
		if isDisabled() then
			Vide.untrack(function()
				isCaptured(false)
			end)
		end
	end)

	--* Dragging can select the slider's root or one of its parts; selection belongs on the focus target.
	Vide.cleanup(GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		local selectedObject = GuiService.SelectedObject
		if root == nil or selectedObject == nil then
			return
		end
		local isUnexpectedSliderSelection = selectedObject == root
			or (
				selectedObject:IsDescendantOf(root)
				and selectedObject ~= focusTarget
				and selectedObject ~= captureTarget
			)
		if isUnexpectedSliderSelection then
			GuiService.SelectedObject = focusTarget
		end
	end))

	Vide.effect(function()
		if not isCaptured() then
			return
		end
		Vide.untrack(function()
			local connection: RBXScriptConnection? = nil
			--* React selects the capture cursor after commit. Here the cursor is parented only once the current
			--* update finishes, and selecting an unparented object does nothing.
			local thread = task.defer(function()
				local target = captureTarget
				GuiService.SelectedObject = target
				connection = GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
					if GuiService.SelectedObject ~= target then
						isCaptured(false)
					end
				end)
			end)
			Vide.cleanup(function()
				if coroutine.status(thread) == "suspended" then
					task.cancel(thread)
				end
				if connection then
					connection:Disconnect()
				end
			end)
		end)
	end)

	local function onKnobDragStarted(isMaxKnob: boolean)
		rangeDragIsMaxKnob(isMaxKnob)
		isMaxThumbActive(isMaxKnob)
		isDragging(true)
		if props.onDragStarted then
			props.onDragStarted()
		end
	end

	local function onKnobDragEnded()
		isDragging(false)
		if props.onDragEnded then
			props.onDragEnded()
		end
	end

	--* With a step, a thumb stops on the last grid position before the other thumb.
	local function snapFractionToStep(boundFraction: number): number
		local currentStep = step()
		if currentStep and currentStep > 0 then
			local current = range()
			local stepCount = math.floor((rawValueFromFraction(boundFraction) - current.Min) / currentStep + 0.5)
			return toFraction(current.Min + stepCount * currentStep)
		end
		return boundFraction
	end
	local function getMinBounds(): (number, number)
		return 0, snapFractionToStep(toFraction(rangeValue().Max))
	end
	local function getMaxBounds(): (number, number)
		return snapFractionToStep(toFraction(rangeValue().Min)), 1
	end

	local function onSeekMin(seekFraction: number)
		local current = rangeValue()
		updateRange(
			NumberRange.new(math.min(steppedValue(rawValueFromFraction(seekFraction)), current.Max), current.Max)
		)
	end
	local function onSeekMax(seekFraction: number)
		local current = rangeValue()
		updateRange(
			NumberRange.new(current.Min, math.max(steppedValue(rawValueFromFraction(seekFraction)), current.Min))
		)
	end

	local function seekRangeKnob(seekFraction: number, isMaxKnob: boolean)
		if isMaxKnob then
			local minBound, maxBound = getMaxBounds()
			onSeekMax(math.clamp(seekFraction, minBound, maxBound))
		else
			local minBound, maxBound = getMinBounds()
			onSeekMin(math.clamp(seekFraction, minBound, maxBound))
		end
	end

	local rangeTrackIsMax = false

	local function onRangeTrackDragStarted(inputPosition: Vector2)
		local track = root
		if lastInputMode() == InputMode.Directional or not track then
			return
		end

		local pressFraction = calculateSliderFraction(getGuiInputPosition(inputPosition, track), track, isVertical())
		local current = rangeValue()
		local currentMinFraction = toFraction(current.Min)
		local currentMaxFraction = toFraction(current.Max)
		local isMaxKnob = math.abs(currentMaxFraction - pressFraction) < math.abs(pressFraction - currentMinFraction)
			or (currentMinFraction == currentMaxFraction and pressFraction > currentMaxFraction)

		rangeTrackIsMax = isMaxKnob
		onKnobDragStarted(isMaxKnob)
		seekRangeKnob(pressFraction, isMaxKnob)
	end

	local function onRangeTrackDrag(inputPosition: Vector2)
		local track = root
		if lastInputMode() == InputMode.Directional or not track then
			return
		end
		seekRangeKnob(
			calculateSliderFraction(getGuiInputPosition(inputPosition, track), track, isVertical()),
			rangeTrackIsMax
		)
	end

	local function exitCapture()
		isCaptured(false)
		GuiService.SelectedObject = focusTarget
	end

	useSliderDirectionalInput(
		function()
			return isSelected() and not isDisabled() and isCaptured()
		end,
		isVertical,
		{
			getValue = function()
				if isRange then
					local current = rangeValue()
					return if isMaxThumbActive() then current.Max else current.Min
				end
				return value()
			end,
			getStep = step,
			getRange = range,
			onStep = function(newValue: number)
				if isRange then
					local current = rangeValue()
					if isMaxThumbActive() then
						updateRange(NumberRange.new(current.Min, math.max(newValue, current.Min)))
					else
						updateRange(NumberRange.new(math.min(newValue, current.Max), current.Max))
					end
				else
					updateValue(newValue)
				end
			end,
			onExit = exitCapture,
		}
	)

	-- The fraction seeked to on DragStart; DragUDim2 deltas are relative to it.
	local dragStartFraction = 0
	-- The previous DragUDim2 scale, to spot the engine resetting the drag origin when directional input turns.
	local lastDragUDim2 = 0
	local singleDragDetector: UIDragDetector? = nil

	--* Keeps the seeked fraction plus the drag delta within [0, 1], so the knob stops at the ends.
	local function updateDragTranslationBounds(base: number)
		if isVertical() then
			minDragTranslation(UDim2.fromScale(0, base - 1))
			maxDragTranslation(UDim2.fromScale(0, base))
		else
			minDragTranslation(UDim2.fromScale(-base, 0))
			maxDragTranslation(UDim2.fromScale(1 - base, 0))
		end
	end

	local function onDragStarted(inputPosition: Vector2)
		isDragging(true)
		if props.onDragStarted then
			props.onDragStarted()
		end

		lastDragUDim2 = 0
		local current = range()
		local rangeSpan = current.Max - current.Min

		if lastInputMode() == InputMode.Directional then
			--* Directional input has no press position, so drags start from the current value.
			dragStartFraction = (value() - current.Min) / rangeSpan
			updateDragTranslationBounds(dragStartFraction)
			return
		end

		--* DragUDim2 only reports movement after the grab, so seek to the press point now.
		local track = root
		local pressValue = if track
			then current.Min
				+ calculateSliderFraction(getGuiInputPosition(inputPosition, track), track, isVertical())
					* rangeSpan
			else current.Min
		dragStartFraction = (pressValue - current.Min) / rangeSpan
		updateValue(steppedValue(pressValue))
		updateDragTranslationBounds(dragStartFraction)
	end

	local function onDrag()
		local detector = singleDragDetector
		if not detector then
			return
		end
		local current = range()
		local rangeSpan = current.Max - current.Min
		local delta = if isVertical() then -detector.DragUDim2.Y.Scale else detector.DragUDim2.X.Scale

		if
			lastInputMode() == InputMode.Directional
			and math.abs(delta - lastDragUDim2) > MAX_DIRECTIONAL_INPUT_DRAG_DELTA
		then
			--* Re-anchor to the current value so the knob stays put instead of snapping back.
			dragStartFraction = (value() - current.Min) / rangeSpan - delta
			lastDragUDim2 = delta
			updateDragTranslationBounds(dragStartFraction)
			return
		end
		lastDragUDim2 = delta

		local newFraction = math.clamp(dragStartFraction + delta, 0, 1)
		updateValue(steppedValue(current.Min + newFraction * rangeSpan))
	end

	local wasSelected = false
	local function onStateChanged(state: ControlState)
		controlState(state)
		local isNowSelected = state == ControlState.Selected or state == ControlState.SelectedPressed
		if isRange and isNowSelected and not wasSelected then
			--* Capturing activates the thumb nearest the side focus entered from.
			isMaxThumbActive(getSelectionEntryDirection(Vide.untrack(isVertical)) < 0)
		end
		wasSelected = isNowSelected
	end

	local function isEnabled(): boolean
		return not isDisabled()
	end

	local dragDetector = Vide.show(function()
		return not isDirectionalInput()
	end, function()
		if isRange then
			return create("UIDragDetector")({
				Name = "DragDetector",
				DragStyle = Enum.UIDragDetectorDragStyle.Scriptable,
				DragStart = onRangeTrackDragStarted,
				DragContinue = onRangeTrackDrag,
				DragEnd = onKnobDragEnded,
				SelectionModeDragSpeed = UDim2.new(),
				Enabled = isEnabled,
			})
		end
		local detector = create("UIDragDetector")({
			Name = "DragDetector",
			DragStyle = Enum.UIDragDetectorDragStyle.TranslateLine,
			DragAxis = function()
				return if isVertical() then Vector2.new(0, 1) else Vector2.new(1, 0)
			end,
			ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomScale,
			DragRelativity = Enum.UIDragDetectorDragRelativity.Absolute,
			MinDragTranslation = minDragTranslation,
			MaxDragTranslation = maxDragTranslation,
			DragStart = onDragStarted,
			DragContinue = onDrag,
			DragEnd = onKnobDragEnded,
			SelectionModeDragSpeed = UDim2.new(),
			Enabled = isEnabled,
		})
		if root then
			detector.ReferenceUIInstance = root
		end
		singleDragDetector = detector
		return detector
	end)

	local function customKnobSizeUDim2(): UDim2
		if props.knob then
			local knobSize = customKnobSize()
			return UDim2.fromOffset(knobSize.X, knobSize.Y)
		end
		return getKnobSize(tokens(), size())
	end
	local function onCustomKnobSizeChanged(instance: GuiObject)
		customKnobSize(instance.AbsoluteSize)
	end

	local function selectionCursor(anchorPoint: () -> Vector2, position: () -> UDim2, zIndex: number?)
		return Vide.show(function()
			return isSelected() and isCaptured()
		end, function()
			local cursor = CursorComponent({
				cornerRadius = UDim.new(0.5, 0),
				offset = Vide.untrack(tokens).Padding.XSmall,
				borderWidth = Vide.untrack(tokens).Stroke.Thicker,
				colorNamespace = colorNamespace,
			})
			cursor.Name = "Cursor"
			local view = View({
				Size = customKnobSizeUDim2,
				AnchorPoint = anchorPoint,
				Position = position,
				ZIndex = zIndex,
				selection = { Selectable = true },
				selectionGroup = CAPTURE_CURSOR_SELECTION_GROUP,
				cursor = CursorType.Invisible,
				onStateChanged = function() end,
				testId = `{props.testId}--selection-cursor`,
				children = cursor,
			})
			view.Name = "SelectionCursor"
			captureTarget = view
			Vide.cleanup(function()
				if captureTarget == view then
					captureTarget = nil
				end
			end)
			return view
		end)
	end

	local function customKnob(): Types.Children
		local knob = props.knob
		local built = if isRange and type(knob) == "function" then Vide.untrack(knob :: () -> any) else knob
		if typeof(built) == "Instance" then
			--* React keys a lone child element this way.
			built.Name = "Children"
		end
		return built
	end

	local barChildren: { any }
	if isRange then
		local fill = View({
			tag = function()
				return variant().fill.tag
			end,
			AnchorPoint = Vector2.zero,
			Position = function()
				return if isVertical() then UDim2.fromScale(0, 1 - maxFraction()) else UDim2.fromScale(minFraction(), 0)
			end,
			Size = function()
				local extent = maxFraction() - minFraction()
				return if isVertical() then UDim2.fromScale(1, extent) else UDim2.fromScale(extent, 1)
			end,
			testId = `{props.testId}--fill`,
		})
		fill.Name = "Fill"

		local function thumb(isMaxKnob: boolean): GuiObject
			local view = SliderThumb({
				track = function()
					return root
				end,
				fraction = if isMaxKnob then maxFraction else minFraction,
				isVertical = isVertical,
				isDisabled = isDisabled,
				isDragEnabled = function()
					return not isDirectionalInput()
				end,
				knobAppearance = function()
					local knob = variant().knob
					return {
						size = size(),
						style = if isKnobVisible()
								and isDragging()
								and rangeDragIsMaxKnob() == isMaxKnob
							then knob.dragStyle
							else knobStyle(),
						stroke = knobStroke(),
						hasShadow = knob.hasShadow,
					}
				end,
				knob = if props.knob ~= nil then customKnob() else nil,
				isContained = isContained,
				onSeek = if isMaxKnob then onSeekMax else onSeekMin,
				getBounds = if isMaxKnob then getMaxBounds else getMinBounds,
				onDragStarted = function()
					onKnobDragStarted(isMaxKnob)
				end,
				onDragEnded = onKnobDragEnded,
				Visible = isKnobVisible,
				onAbsoluteSizeChanged = onCustomKnobSizeChanged,
				LayoutOrder = if isMaxKnob then 2 else 1,
				testId = `{props.testId}--{if isMaxKnob then "max" else "min"}`,
			})
			view.Name = if isMaxKnob then "MaxKnob" else "MinKnob"
			return view
		end

		local function activeRangeFraction(): number
			return if isMaxThumbActive() then maxFraction() else minFraction()
		end

		barChildren = {
			fill,
			thumb(false),
			thumb(true),
			selectionCursor(function()
				if not isContained() then
					return Vector2.new(0.5, 0.5)
				end
				local active = activeRangeFraction()
				return if isVertical() then Vector2.new(0.5, 1 - active) else Vector2.new(active, 0.5)
			end, function()
				local active = activeRangeFraction()
				return if isVertical() then UDim2.fromScale(0.5, 1 - active) else UDim2.fromScale(active, 0.5)
			end, 3),
		}
	else
		local function knobAnchorPoint(): Vector2
			if not isContained() then
				return Vector2.new(0.5, 0.5)
			end
			local current = fraction()
			return if isVertical() then Vector2.new(0.5, 1 - current) else Vector2.new(current, 0.5)
		end
		local function knobPosition(): UDim2
			return if isVertical() then UDim2.fromScale(0.5, 0) else UDim2.fromScale(1, 0.5)
		end

		local knob: GuiObject
		if props.knob ~= nil then
			knob = View({
				tag = "size-0-0 auto-xy",
				AnchorPoint = knobAnchorPoint,
				Position = knobPosition,
				Visible = isKnobVisible,
				onAbsoluteSizeChanged = onCustomKnobSizeChanged,
				testId = `{props.testId}--custom-knob`,
				children = customKnob(),
			})
		else
			knob = PresentationContext.context(IS_INVERSE, function()
				return Knob({
					AnchorPoint = knobAnchorPoint,
					Position = knobPosition,
					size = size,
					style = knobStyle,
					stroke = knobStroke,
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
				local current = fraction()
				return if isVertical() then UDim2.fromScale(1, current) else UDim2.fromScale(current, 1)
			end,
			testId = `{props.testId}--fill`,
			children = {
				Value.bindProperty("AnchorPoint", function(): Vector2?
					return if isVertical() then Vector2.new(0, 1) else nil
				end),
				Value.bindProperty("Position", function(): UDim2?
					return if isVertical() then UDim2.fromScale(0, 1) else nil
				end),
				selectionCursor(knobAnchorPoint, knobPosition),
				knob,
			},
		})
		fill.Name = "Fill"
		barChildren = { fill }
	end

	local bar = View({
		tag = function()
			return variant().bar.tag
		end,
		Size = function()
			local height = variant().bar.height
			return if isVertical() then UDim2.new(0, height, 1, 0) else UDim2.new(1, 0, 0, height)
		end,
		testId = `{props.testId}--bar`,
		children = barChildren,
	})
	bar.Name = "Bar"

	local focus = View({
		Size = UDim2.fromScale(1, 1),
		stateLayer = {
			affordance = StateLayerAffordance.None,
		},
		cursor = function()
			return if isCaptured() then CursorType.Invisible else nil
		end,
		onStateChanged = onStateChanged,
		isDisabled = props.isDisabled,
		ZIndex = 0,
		testId = `{props.testId}--focus-target`,
		children = dragDetector,
	})
	focus.Name = "FocusTarget"
	focusTarget = focus

	local function captureBehavior(): Enum.SelectionBehavior
		return if isCaptured() then Enum.SelectionBehavior.Stop else Enum.SelectionBehavior.Escape
	end

	--* Foundation makes a disabled slider a CanvasGroup. A source can enable it later, and the root cannot change
	--* class, so a reactive isDisabled always gets a CanvasGroup.
	local groupTransparency: Value<number>? = if type(props.isDisabled) == "function"
		then function()
			return if isDisabled() then Constants.DISABLED_TRANSPARENCY else 0
		end
		elseif props.isDisabled == true then Constants.DISABLED_TRANSPARENCY
		else nil

	local view = View(withCommonProps(props, {
		Size = function()
			local thickness = UDim.new(0, getKnobSize(tokens(), size()).X.Offset)
			local width: UDim = Value.read(props.width)
			return if isVertical() then UDim2.new(thickness, width) else UDim2.new(width, thickness)
		end,
		GroupTransparency = groupTransparency,
		selectionGroup = {
			SelectionBehaviorLeft = captureBehavior,
			SelectionBehaviorRight = captureBehavior,
			SelectionBehaviorUp = captureBehavior,
			SelectionBehaviorDown = captureBehavior,
		},
		children = { focus, bar },
	}) :: any)
	root = view
	if singleDragDetector then
		singleDragDetector.ReferenceUIInstance = view
	end

	return view
end

return Slider
