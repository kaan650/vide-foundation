local Vide = require("../../Packages/Vide")

local Constants = require("../../Constants")
local Icon = require("../Icon")
local InputField = require("../InputField")
local InputFocusBehavior = require("../../Enums/InputFocusBehavior")
local InputSize = require("../../Enums/InputSize")
local InputVariant = require("../../Enums/InputVariant")
local InternalTextInput = require("../InternalTextInput")
local NumberInputControls = require("./NumberInputControls")
local NumberInputControlsVariant = require("../../Enums/NumberInputControlsVariant")
local OnChangeCallbackReason = require("../../Enums/OnChangeCallbackReason")
local ScrubBehavior = require("../../Enums/ScrubBehavior")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local calculateNumberInputValueFromPositions = require("./calculateNumberInputValueFromPositions")
local create = require("../../Utility/create")
local getInputTextSize = require("../../Utility/getInputTextSize")
local getMultiLineTextHeight = require("../../Utility/getMultiLineTextHeight")
local isBuilderIcon = require("../../Utility/isBuilderIcon")
local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local useIconSize = require("../../Utility/useIconSize")
local useNumberInputVariants = require("./useNumberInputVariants")
local useTextInputVariants = require("../TextInput/useTextInputVariants")
local useTextSize = require("../../Utility/useTextSize")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InputFocusBehavior = InputFocusBehavior.InputFocusBehavior
type InputSize = InputSize.InputSize
type InputVariant = InputVariant.InputVariant
type NumberInputControlsVariant = NumberInputControlsVariant.NumberInputControlsVariant
type OnChangeCallbackReason = OnChangeCallbackReason.OnChangeCallbackReason
type ScrubBehavior = ScrubBehavior.ScrubBehavior
type ColorStyleValue = Types.ColorStyleValue
type FontStyle = Types.FontStyle
type InternalTextInputRef = Types.InternalTextInputRef
type TextInputRef = Types.TextInputRef
type Value<T> = Types.Value<T>

local function round(num: number, numDecimalPlaces: number?): number
	local mult = 10 ^ (numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

local scrubBehaviorToSensitivity: { [ScrubBehavior]: number } = {
	[ScrubBehavior.On] = 1,
	[ScrubBehavior.Off] = 0,
}

export type NumberInputProps = {
	-- Input number value
	value: Value<number>?,
	-- **DEPRECATED** Variant of controls to use
	controlsVariant: NumberInputControlsVariant?,
	-- Whether the input shows an error state. Always shows while true, if false then invalid input will still render an error state.
	hasError: Value<boolean?>?,
	-- Style variant of the input
	variant: Value<InputVariant>?,
	-- Size of the number input
	size: Value<InputSize>?,
	-- Whether the input is disabled
	isDisabled: Value<boolean?>?,
	-- Whether the input is required, true for "*", false for " (optional)", nil for nothing
	isRequired: Value<boolean?>?,
	-- The callback that processes the new value
	onChanged: (number: number, reason: OnChangeCallbackReason) -> (),
	-- The callback that fires when text is inputted into the value.
	-- This is used in rare scenarios such as mathematical expressions (letting people type `1 + 2`),
	-- and `onChanged` is virtually always what you want.
	onTextChanged: ((value: string) -> ())?,
	-- Input label text. To omit, set to an empty string
	label: Value<string>,
	-- Hint text below the input, is red on error
	hint: Value<string?>?,
	-- Width of the component
	width: Value<UDim?>?,
	-- Image before the input
	leadingIcon: Value<string?>?,
	-- Icon after the input
	trailingIcon: Value<string?>?,
	-- The prefix to display before the input (e.g. $ or €)
	prefix: Value<string?>?,
	-- The suffix to display after the input (e.g. % or px)
	suffix: Value<string?>?,
	-- Value that will be added/subtracted every time you press increment/decrement controls
	step: Value<number>?,
	-- Maximum value input may reach via increment
	maximum: Value<number>?,
	-- Minimum value input may reach via decrement
	minimum: Value<number>?,
	-- Precision that will be used to display a value. Value will be rounded to the nearest value. With the precision being 3 0.0001 will be rounded to 0, 0.0006 to 0.001
	precision: Value<number>?,
	-- Callback to format the value when input is not focused
	formatAsString: ((value: number) -> string)?,
	-- Whether the input can be dragged to change the value.
	-- **DEPRECATED** Use scrubBehavior instead
	isScrubbable: Value<boolean>?,
	-- Controls scrub (drag-to-change) behavior
	scrubBehavior: Value<ScrubBehavior>?,
	-- The callback that fires when scrubbing starts
	onScrubStarted: (() -> ())?,
	-- The callback that fires when scrubbing ends
	onScrubEnded: (() -> ())?,
	-- Behavior of the text input when focused. Mobile does not yet support Highlight behavior.
	focusBehavior: InputFocusBehavior?,
	-- Called when the input gains focus
	onFocusGained: (() -> ())?,
	-- Called when focus is lost. The InputObject that caused focus to be lost is passed if available.
	onFocusLost: ((inputObject: InputObject?) -> ())?,
	-- Called when Return is pressed while the input is focused
	onReturnPressed: (() -> ())?,
	-- Receives the outermost container of the internal text input
	inputRef: ((GuiObject) -> ())?,
	-- Receives a handle to the inner TextBox
	textBoxRef: ((TextInputRef) -> ())?,
	-- Whether the input renders increment/decrement controls
	hasControls: Value<boolean>?,
} & Types.SelectionProps & Types.CommonProps

local function defaultFormatAsString(value: number): string
	return tostring(value)
end

local defaultProps = {
	variant = InputVariant.Standard,
	size = InputSize.Large,
	minimum = -math.huge,
	maximum = math.huge,
	step = 1,
	precision = 3,
	value = 0,
	formatAsString = defaultFormatAsString,
	isScrubbable = false,
	scrubBehavior = ScrubBehavior.Off,
	hasControls = false,
	testId = "--foundation-number-input",
}

--- A numeric field with optional increment and decrement controls, units and drag-to-change. The text shows
--- `formatAsString(value)` until focused, then the raw number being typed.
local function NumberInput(numberInputProps: NumberInputProps): GuiObject
	local props = withDefaults(numberInputProps, defaultProps)
	local tokens = useTokens()
	local testId: string = props.testId
	local formatAsString: (number) -> string = props.formatAsString

	local function size(): InputSize
		return Value.read(props.size)
	end
	local function value(): number
		return Value.read(props.value)
	end
	local function minimum(): number
		return Value.read(props.minimum)
	end
	local function maximum(): number
		return Value.read(props.maximum)
	end
	local function step(): number
		return Value.read(props.step)
	end
	local function precision(): number
		return Value.read(props.precision)
	end
	local function isDisabled(): boolean
		return Value.read(props.isDisabled) == true
	end

	local variantProps = Vide.derive(function()
		return useTextInputVariants(tokens(), size(), Value.read(props.variant))
	end)
	local controlsProps = Vide.derive(function()
		return useNumberInputVariants(tokens(), size()).controls
	end)

	local internalTextBox: TextInputRef? = nil
	local dragStart: { position: number, value: number }? = nil
	local hasScrubStarted = false

	local function isFocused(): boolean
		return if internalTextBox then internalTextBox.getIsFocused() == true else false
	end

	local hasInvalidInput = Vide.source(false)
	local function hasError(): boolean
		return Value.read(props.hasError) == true or hasInvalidInput()
	end

	local function scrubBehavior(): ScrubBehavior
		return if Value.read(props.isScrubbable) then ScrubBehavior.On else Value.read(props.scrubBehavior)
	end
	local function isScrubbable(): boolean
		return scrubBehavior() ~= ScrubBehavior.Off
	end

	local function clampValueToRange(current: number): number
		return math.clamp(current, minimum(), maximum())
	end
	local function snapToStep(current: number, roundFunction: (number) -> number): number
		return roundFunction(current / step()) * step()
	end
	local function upValue(): number
		local current, places = value(), precision()
		local newUpValue = round(current + step(), places)
		local snapUpValue = round(snapToStep(current, math.ceil), places)
		if round(current, places) ~= snapUpValue then
			newUpValue = snapUpValue
		end
		return clampValueToRange(newUpValue)
	end
	local function downValue(): number
		local current, places = value(), precision()
		local newDownValue = round(current - step(), places)
		local snapDownValue = round(snapToStep(current, math.floor), places)
		if round(current, places) ~= snapDownValue then
			newDownValue = snapDownValue
		end
		return clampValueToRange(newDownValue)
	end
	local function isUpDisabled(): boolean
		return isDisabled() or value() == maximum()
	end
	local function isDownDisabled(): boolean
		return isDisabled() or value() == minimum()
	end
	local function constrainValue(current: number): number
		return round(math.clamp(current, minimum(), maximum()), precision())
	end

	local textInput = Vide.source(Vide.untrack(function(): string
		return formatAsString(constrainValue(value()))
	end))

	local function incrementButtonsGap(): number
		local gap = tokens().Gap
		return if size() == InputSize.XSmall then gap.Small - (gap.XSmall / 2) else gap.Small
	end

	local function prefix(): string?
		return Value.read(props.prefix)
	end
	local function suffix(): string?
		return Value.read(props.suffix)
	end
	local function hasUnits(): boolean
		local prefixText, suffixText = prefix(), suffix()
		return (prefixText ~= nil and prefixText ~= "") or (suffixText ~= nil and suffixText ~= "")
	end

	--! The engine floors TextSize when rendering, so fractional token sizes (BodyMedium is 17.64) are floored before
	--! measuring or the prefix comes out too wide.
	local prefixTextSize = useTextSize(function(): string?
		local prefixText = prefix()
		return if prefixText then prefixText .. " " else nil
	end, function(): FontStyle
		local style = variantProps().textBox.fontStyle
		return {
			Font = style.Font,
			FontSize = math.floor(style.FontSize :: number),
			LineHeight = style.LineHeight,
		}
	end)

	local function iconSize()
		return variantProps().icon.size
	end
	local builderIconSize = useIconSize(iconSize, true)
	local imageIconSize = useIconSize(iconSize, false)
	local function iconWidth(icon: string?): number
		if not icon then
			return 0
		end
		return (if isBuilderIcon(icon) then builderIconSize() else imageIconSize()).X.Offset
	end
	local function containerGap(): number
		local gap = tokens().Gap
		local current = size()
		return if current == InputSize.XSmall then gap.Small elseif current == InputSize.Small then gap.Medium else gap.Large
	end
	local function unitsXOffsets(): (number, number)
		local horizontalPadding = variantProps().container.horizontalPadding.Offset
		local leadingIcon: string? = Value.read(props.leadingIcon)
		local trailingIcon: string? = Value.read(props.trailingIcon)
		local left = horizontalPadding + iconWidth(leadingIcon) + (if leadingIcon then containerGap() else 0)
		local right = horizontalPadding + iconWidth(trailingIcon) + (if trailingIcon then containerGap() else 0)
		return left, right
	end

	--* Mirrors InternalTextInput's text padding plus the 1px stroke inset, so the units line up with the text.
	local function unitsPaddingY(): (number, number)
		local style = variantProps().textBox.fontStyle
		local textHeight = getMultiLineTextHeight(style.FontSize :: number, 1, style.LineHeight :: number)
		local outerBorderOffset = 2
		local containerPaddingY = math.round((variantProps().container.minHeight - outerBorderOffset - textHeight) * 2)
			/ 2
		local strokeInset = 1
		return math.floor(containerPaddingY / 2) + strokeInset, math.ceil(containerPaddingY / 2) + strokeInset
	end

	local function width(): UDim
		return Value.read(props.width) or UDim.new(0, Constants.DEFAULT_NUMBER_INPUT_WIDTH)
	end

	local function onFocus()
		textInput(tostring(value()))
		if props.onFocusGained then
			props.onFocusGained()
		end
	end

	local function valueChanged(newValue: number, reason: OnChangeCallbackReason)
		newValue = constrainValue(newValue)
		textInput(if isFocused() then tostring(newValue) else formatAsString(newValue))
		props.onChanged(newValue, reason)
	end

	local function onFocusLost(inputObject: InputObject?)
		hasInvalidInput(false)
		valueChanged(value(), OnChangeCallbackReason.FocusLost)
		if props.onFocusLost then
			props.onFocusLost(inputObject)
		end
	end

	local function onTextChanged(text: string)
		textInput(text)
		if not isFocused() then
			return
		end

		local number = tonumber(text)
		if props.onTextChanged ~= nil then
			props.onTextChanged(text)
		elseif number == nil then
			hasInvalidInput(true)
			return
		end

		if number ~= nil then
			hasInvalidInput(false)
			props.onChanged(number, OnChangeCallbackReason.Keyboard)
		end
	end

	local function onIncrement()
		if isUpDisabled() then
			return
		end
		valueChanged(upValue(), OnChangeCallbackReason.Activate)
	end

	local function onDecrement()
		if isDownDisabled() then
			return
		end
		valueChanged(downValue(), OnChangeCallbackReason.Activate)
	end

	local function hasControls(): boolean
		return Value.read(props.hasControls) == true
			and props.controlsVariant ~= NumberInputControlsVariant.None
			and props.controlsVariant ~= NumberInputControlsVariant.Stacked
	end

	local function widthOffset(): UDim
		return if hasControls() then UDim.new(0, controlsProps().width + incrementButtonsGap()) else UDim.new()
	end

	local function onDragStarted(_detector: UIDragDetector, position: Vector2)
		hasScrubStarted = false
		dragStart = { position = position.X, value = value() }
	end

	local function onDrag(_detector: UIDragDetector, position: Vector2)
		local start = dragStart
		if start == nil then
			return
		end
		if props.onScrubStarted and not hasScrubStarted then
			props.onScrubStarted()
			hasScrubStarted = true
		end
		local newValue = calculateNumberInputValueFromPositions(
			start.value,
			start.position,
			position.X,
			step(),
			scrubBehaviorToSensitivity[scrubBehavior()]
		)
		valueChanged(newValue, OnChangeCallbackReason.Drag)
	end

	local function onDragEnded()
		if dragStart then
			dragStart = nil
			if props.onScrubEnded and hasScrubStarted then
				props.onScrubEnded()
			end
		end
		hasScrubStarted = false
	end

	local function scrubbableTransparencySequence(): NumberSequence
		local filledStyleTransparency = tokens().Color.Shift.Shift_300.Transparency
		local unfilledStyleTransparency = tokens().Color.Shift.Shift_100.Transparency
		local current = value()
		local min, max = minimum(), maximum()
		local percentageScrubbed = 0
		if current and max and min then
			if max == min then
				percentageScrubbed = 1
			else
				percentageScrubbed = (clampValueToRange(current) - min) / (max - min)
			end
		end

		if percentageScrubbed == 0 then
			return NumberSequence.new(unfilledStyleTransparency)
		elseif percentageScrubbed == 1 then
			return NumberSequence.new(filledStyleTransparency)
		elseif percentageScrubbed > 0 or percentageScrubbed < 1 then
			local keypoints = {
				NumberSequenceKeypoint.new(0, filledStyleTransparency),
				NumberSequenceKeypoint.new(percentageScrubbed, filledStyleTransparency),
				NumberSequenceKeypoint.new(math.min(percentageScrubbed + 0.001, 1), unfilledStyleTransparency),
			}
			if percentageScrubbed < 0.999 then
				table.insert(keypoints, NumberSequenceKeypoint.new(1, unfilledStyleTransparency))
			end
			return NumberSequence.new(keypoints)
		end
		--* An unbounded range gives NaN, which lands here.
		return NumberSequence.new(unfilledStyleTransparency)
	end

	--* A value changed from outside replaces the text, unless the user is typing.
	Vide.effect(function()
		local constrained = constrainValue(value())
		Vide.untrack(function()
			if not isFocused() then
				textInput(formatAsString(constrained))
			end
		end)
	end)

	local function iconRow(name: string): GuiObject
		return View({
			tag = "row align-y-center size-0-full auto-x",
			children = named(
				"Children",
				Icon({
					name = name,
					style = function(): ColorStyleValue
						return variantProps().icon.style :: any
					end,
					size = iconSize,
				})
			),
		})
	end
	local function iconElement(icon: Value<string?>?): any
		if type(icon) ~= "function" then
			return if icon then iconRow(icon) else nil
		end
		local builders = setmetatable({}, {
			__index = function(_, name: string)
				return function()
					return iconRow(name)
				end
			end,
		})
		return Vide.switch(icon)(builders :: any)
	end

	local function internalInput(textBoxRef: (InternalTextInputRef?) -> (), scrubbable: boolean): GuiObject
		return named(
			"Input",
			InternalTextInput({
				inputRef = props.inputRef,
				text = function(): string
					local typed = textInput()
					local current = value()
					return if isFocused() then typed else formatAsString(constrainValue(current))
				end,
				hasError = hasError,
				variant = props.variant,
				size = props.size,
				Selectable = props.Selectable,
				NextSelectionUp = props.NextSelectionUp,
				NextSelectionDown = props.NextSelectionDown,
				NextSelectionLeft = props.NextSelectionLeft,
				NextSelectionRight = props.NextSelectionRight,
				horizontalPadding = {
					left = function()
						return variantProps().container.horizontalPadding
					end,
					right = function()
						return variantProps().container.horizontalPadding
					end,
					innerLeft = function(): UDim?
						local textSize = prefixTextSize()
						return if textSize and textSize.X > 0 then UDim.new(0, textSize.X) else nil
					end,
				},
				focusBehavior = props.focusBehavior,
				onChanged = onTextChanged,
				onFocusLost = onFocusLost,
				onFocus = onFocus,
				onDragStarted = if scrubbable then onDragStarted else nil,
				onDrag = if scrubbable then onDrag else nil,
				onDragEnded = if scrubbable then onDragEnded else nil,
				onReturnPressed = props.onReturnPressed,
				textBoxRef = textBoxRef,
				backgroundGradient = if scrubbable
					then create("UIGradient")({
						Color = function()
							return ColorSequence.new(tokens().Color.Shift.Shift_300.Color3)
						end,
						Transparency = scrubbableTransparencySequence,
						Rotation = 0,
					})
					else nil,
				trailingElement = iconElement(props.trailingIcon),
				leadingElement = iconElement(props.leadingIcon),
				isDisabled = props.isDisabled,
				testId = `{testId}--field`,
			}) :: any
		)
	end

	local function unitsOverlay(): GuiObject
		return named(
			"Units",
			Text({
				tag = "text-align-x-left text-align-y-center content-muted",
				fontStyle = function()
					return variantProps().textBox.fontStyle
				end,
				Size = function()
					local left, right = unitsXOffsets()
					return UDim2.new(1, -(left + right), 1, 0)
				end,
				Position = function()
					local left = unitsXOffsets()
					return UDim2.fromOffset(left, 0)
				end,
				Text = function()
					local prefixText, suffixText = prefix(), suffix()
					return `{if prefixText then prefixText .. " " else ""}<font transparency="1">{textInput()}</font>{if suffixText
						then " " .. suffixText
						else ""}`
				end,
				RichText = true,
				ClipsDescendants = true,
				padding = {
					top = function()
						local top = unitsPaddingY()
						return UDim.new(0, top)
					end,
					bottom = function()
						local _, bottom = unitsPaddingY()
						return UDim.new(0, bottom)
					end,
					left = UDim.new(),
					right = UDim.new(),
				},
				testId = `{testId}--units`,
			})
		)
	end

	local scrubbable: Value<boolean> = if type(props.isScrubbable) == "function" or type(props.scrubBehavior) == "function"
		then isScrubbable
		else isScrubbable()

	return InputField(withCommonProps(props, {
		width = width,
		hasError = hasError,
		label = props.label,
		size = function()
			return getInputTextSize(size())
		end,
		isRequired = props.isRequired,
		isDisabled = props.isDisabled,
		hint = props.hint,
		textBoxRef = function(handle: TextInputRef)
			internalTextBox = handle
			if props.textBoxRef then
				props.textBoxRef(handle)
			end
		end,
		input = function(textBoxRef: (InternalTextInputRef?) -> ())
			return View({
				Size = function()
					local current, offset = width(), widthOffset()
					return UDim2.new(current.Scale - offset.Scale, current.Offset - offset.Offset, 0, 0)
				end,
				tag = "row align-y-center auto-y",
				layout = {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = function()
						return UDim.new(0, incrementButtonsGap())
					end,
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
				children = {
					named(
						"InputField",
						View({
							tag = "size-full-0 auto-y",
							children = {
								rebuildOn<<boolean>>(scrubbable, function(current: boolean)
									return internalInput(textBoxRef, current)
								end),
								Vide.show(hasUnits, unitsOverlay),
							},
						})
					),
					Vide.show(hasControls, function()
						return named(
							"Controls",
							NumberInputControls({
								size = props.size,
								increment = {
									isDisabled = isUpDisabled,
									onClick = onIncrement,
								},
								decrement = {
									isDisabled = isDownDisabled,
									onClick = onDecrement,
								},
								testId = testId,
							})
						)
					end),
				},
			})
		end,
	}) :: any) :: GuiObject
end

return NumberInput
