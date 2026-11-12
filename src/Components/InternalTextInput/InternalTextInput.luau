local Vide = require("../../Packages/Vide")

local Constants = require("../../Constants")
local CornerRadius = require("../CornerRadius")
local Icon = require("../Icon")
local InputFocusBehavior = require("../../Enums/InputFocusBehavior")
local InputSize = require("../../Enums/InputSize")
local InputVariant = require("../../Enums/InputVariant")
local Padding = require("../Padding")
local Radius = require("../../Enums/Radius")
local ScrollView = require("../ScrollView")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local blendTransparencies = require("../../Utility/blendTransparencies")
local create = require("../../Utility/create")
local getDisabledStyle = require("../../Utility/getDisabledStyle")
local getMultiLineTextHeight = require("../../Utility/getMultiLineTextHeight")
local isPluginSecurity = require("../../Utility/isPluginSecurity")
local named = require("../../Utility/named")
local normalizeFontFace = require("../../Utility/normalizeFontFace")
local rebuildOn = require("../../Utility/rebuildOn")
local tags = require("../../Utility/tags")
local truncateTextToCursor = require("./truncateTextToCursor")
local usePreferredInput = require("../../Utility/usePreferredInput")
local useTextInputVariants = require("../TextInput/useTextInputVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InputFocusBehavior = InputFocusBehavior.InputFocusBehavior
type InputSize = InputSize.InputSize
type InputVariant = InputVariant.InputVariant
type Radius = Radius.Radius
type ColorStyleValue = Types.ColorStyleValue
type FontStyle = Types.FontStyle
type InternalTextInputRef = Types.InternalTextInputRef
type PaddingTable = Types.PaddingTable
type Value<T> = Types.Value<T>

export type HorizontalPadding = {
	-- Outer container left padding
	left: Value<UDim>?,
	-- Outer container right padding
	right: Value<UDim>?,
	-- Internal text box padding (between text and adjacent elements)
	innerLeft: Value<UDim?>?,
	innerRight: Value<UDim?>?,
}

--- Receives the UIDragDetector and the pointer position, as React passes them.
export type DragCallback = (detector: UIDragDetector, position: Vector2) -> ()

export type InternalTextInputProps = {
	-- Input text value
	text: Value<string>,
	-- Type of text input. Only available for use in descendants of `CoreGui`.
	textInputType: Enum.TextInputType?,
	-- Size of the text input
	size: Value<InputSize>?,
	-- Style variant of the text input
	variant: Value<InputVariant>?,
	-- Radius of the input container's corners
	radius: Value<Radius?>?,
	-- Horizontal-only padding around the text input
	horizontalPadding: HorizontalPadding?,
	-- Whether the input is in an error state
	hasError: Value<boolean?>?,
	-- Whether the input is disabled
	isDisabled: Value<boolean?>?,
	-- The number of lines to render at once
	numLines: Value<number>?,
	-- Behavior of the input when focused. Mobile does not yet support Highlight behavior.
	focusBehavior: InputFocusBehavior?,
	-- Whether the input has a clear button
	hasClearButton: Value<boolean?>?,
	-- On input text change
	onChanged: (text: string) -> (),
	onFocus: (() -> ())?,
	-- Called when focus is lost. The InputObject that caused focus to be lost is passed if available.
	onFocusLost: ((inputObject: InputObject?) -> ())?,
	onReturnPressed: (() -> ())?,
	onDragStarted: DragCallback?,
	onDrag: DragCallback?,
	onDragEnded: DragCallback?,
	-- Receives a handle to the TextBox.
	textBoxRef: ((InternalTextInputRef) -> ())?,
	-- Receives the outermost container, again whenever it is rebuilt.
	inputRef: ((GuiObject) -> ())?,
	-- Placeholder text for input
	placeholder: Value<string?>?,
	-- Background gradient for the input
	backgroundGradient: Types.Children?,
	-- Shown before the text. A source shows its slot only while it yields something.
	leadingElement: Types.Children?,
	-- Shown after the text. A source shows its slot only while it yields something.
	trailingElement: Types.Children?,
} & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	size = InputSize.Large,
	variant = InputVariant.Standard,
	numLines = 1,
	testId = "--foundation-internal-text-input",
	Selectable = true,
}

type TextBoxProps = {
	Size: Value<UDim2>?,
	Interactable: Value<boolean>?,
	text: Value<string>?,
	fontStyle: () -> FontStyle,
	textStyle: () -> ColorStyleValue,
	padding: PaddingTable?,
	isBoundsChecker: boolean?,
	automaticSize: (() -> Enum.AutomaticSize?)?,
	isDisabled: boolean?,
	placeholder: Value<string?>?,
	textInputType: Enum.TextInputType?,
	isMultiLine: boolean?,
	tag: Value<string>?,
	onTextChanged: ((TextBox) -> ())?,
	onCursorPositionChanged: ((TextBox) -> ())?,
	onFocusGained: (() -> ())?,
	onFocusLost: ((enterPressed: boolean, inputObject: InputObject) -> ())?,
	onInputChanged: ((InputObject) -> ())?,
	onInputEnded: ((InputObject) -> ())?,
	children: Types.Children?,
}

local function TextBox(props: TextBoxProps): TextBox
	local isBoundsChecker = props.isBoundsChecker == true
	local isMultiLine = props.isMultiLine == true or isBoundsChecker
	local fontStyle = props.fontStyle
	local textStyle = props.textStyle

	local properties: { [any]: any } = {
		ClearTextOnFocus = false,
		Selectable = false,
		Active = if isBoundsChecker then false else nil,
		Visible = if isBoundsChecker then false else nil,
		Value.bindProperty("FontFace", function(): Font?
			return Value.read(normalizeFontFace(fontStyle().Font))
		end),
		TextSize = function()
			return fontStyle().FontSize
		end,
		LineHeight = function()
			return fontStyle().LineHeight
		end,
		TextColor3 = function()
			return textStyle().Color3
		end,
		TextTransparency = function()
			return textStyle().Transparency
		end,
		MultiLine = isMultiLine,
		TextWrapped = isMultiLine,
		TextYAlignment = if isMultiLine then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center,
		TextEditable = if isBoundsChecker then false else not props.isDisabled,
		Interactable = props.Interactable,
		TextInputType = if props.textInputType and isPluginSecurity() then props.textInputType else nil,
		Size = props.Size or UDim2.fromScale(1, 1),
		Text = if isBoundsChecker then nil else props.text,
		if props.tag then tags(props.tag) else nil,
		if props.placeholder ~= nil then Value.bindProperty("PlaceholderText", props.placeholder) else nil,
		if props.automaticSize then Value.bindProperty("AutomaticSize", props.automaticSize) else nil,
		if props.padding then named("Padding", Padding({ value = props.padding })) else nil,
		props.children,
		Vide.action(function(instance: Instance)
			local textBox = instance :: TextBox
			--* With immediate signals a handler can run inside the Text binding's effect; it must not subscribe it.
			local function connect(signal: RBXScriptSignal, handler: (...any) -> ())
				Vide.cleanup(signal:Connect(function(...)
					local args = table.pack(...)
					Vide.untrack(function()
						handler(table.unpack(args, 1, args.n))
					end)
				end))
			end
			local onTextChanged = props.onTextChanged
			if onTextChanged then
				connect(textBox:GetPropertyChangedSignal("Text"), function()
					onTextChanged(textBox)
				end)
			end
			local onCursorPositionChanged = props.onCursorPositionChanged
			if onCursorPositionChanged then
				connect(textBox:GetPropertyChangedSignal("CursorPosition"), function()
					onCursorPositionChanged(textBox)
				end)
			end
			if props.onFocusGained then
				connect(textBox.Focused, props.onFocusGained)
			end
			if props.onFocusLost then
				connect(textBox.FocusLost, props.onFocusLost)
			end
			if props.onInputChanged then
				connect(textBox.InputChanged, props.onInputChanged)
			end
			if props.onInputEnded then
				connect(textBox.InputEnded, props.onInputEnded)
			end
		end),
	}

	return (create :: any)("TextBox")(properties)
end

local function optionalUDim(value: Value<UDim?>?): Value<UDim>?
	if type(value) == "function" then
		return function()
			return value() or UDim.new(0, 0)
		end
	end
	return value :: UDim?
end

--- The text field every Foundation text input is built on: a bordered container with the TextBox and optional
--- leading, clear and trailing elements. A source `isDisabled` returns a source of the instance: an enabled
--- container is an ImageButton that focuses the TextBox, a disabled one a Frame. A source `numLines` rebuilds the
--- TextBox when the input switches between one line and a scrolling area.
local function InternalTextInput(textInputProps: InternalTextInputProps): GuiObject | () -> GuiObject
	local props = withDefaults(textInputProps, defaultProps)
	local tokens = useTokens()
	local preferredInput = usePreferredInput()
	local testId: string = props.testId
	local horizontalPadding: HorizontalPadding = props.horizontalPadding or {}

	local function lineCount(): number
		return math.max(1, Value.read(props.numLines))
	end
	local isScrollable = Vide.derive(function(): boolean
		return lineCount() > 1
	end)
	local function isDisabled(): boolean
		return Value.read(props.isDisabled) == true
	end
	local function isMobileDevice(): boolean
		return preferredInput() == Enum.PreferredInput.Touch
	end

	local focus = Vide.source(false)
	local isTouchFocused = Vide.source(false)

	local variantProps = Vide.derive(function()
		return useTextInputVariants(
			tokens(),
			Value.read(props.size),
			Value.read(props.variant),
			Value.read(props.radius),
			focus(),
			Value.read(props.hasError)
		)
	end)

	local function outerBorderThickness(): number
		return tokens().Stroke.Standard
	end
	local function outerBorderOffset(): number
		return math.ceil(outerBorderThickness()) * 2
	end
	local function fontStyle(): FontStyle
		return variantProps().textBox.fontStyle
	end
	local function textBoxViewportHeight(): number
		local style = fontStyle()
		return getMultiLineTextHeight(style.FontSize :: number, lineCount(), style.LineHeight :: number)
	end
	--* Kept in steps of 0.5 for the +-1 split between top and bottom padding; rounded, the container would not
	--* line up with the size tokens to the pixel (see NumberInput).
	local function containerPaddingY(): number
		local style = fontStyle()
		local singleLineHeight = getMultiLineTextHeight(style.FontSize :: number, 1, style.LineHeight :: number)
		return math.round((variantProps().container.minHeight - outerBorderOffset() - singleLineHeight) * 2) / 2
	end
	local function paddingTop(): number
		return math.floor(containerPaddingY() / 2)
	end
	local function paddingBottom(): number
		return math.ceil(containerPaddingY() / 2)
	end
	local function borderFrameHeight(): number
		return textBoxViewportHeight() + math.round(containerPaddingY()) + outerBorderOffset()
	end
	local function textBoxSizeFullHeight(): UDim2
		return UDim2.new(1, 0, 0, textBoxViewportHeight() + paddingTop() + paddingBottom())
	end
	local textBoxWrapperPadding: PaddingTable = {
		top = function()
			return UDim.new(0, paddingTop())
		end,
		bottom = function()
			return UDim.new(0, paddingBottom())
		end,
		left = UDim.new(0, 0),
		right = UDim.new(0, 0),
	}
	local textBoxWrapperInsetPadding: PaddingTable = {
		left = optionalUDim(horizontalPadding.innerLeft),
		right = optionalUDim(horizontalPadding.innerRight),
	}

	local textBox: TextBox? = nil
	local mobileTextBox: TextBox? = nil
	local boundsChecker: TextBox? = nil
	local scrollingFrame: ScrollingFrame? = nil
	local mobileTextBoxText = ""
	local lastDispatchedText: string = Vide.untrack(function(): string
		return Value.read(props.text)
	end)
	local dragStartPosition: Vector2? = nil
	local lastScrollingFrameCanvasPosition = Vector2.zero
	local shouldHighlight = false

	local function setSelectionStart(position: number)
		if textBox then
			textBox.SelectionStart = position
		end
		if mobileTextBox then
			mobileTextBox.SelectionStart = position
		end
	end

	local function setCursorPosition(position: number)
		if textBox then
			textBox.CursorPosition = position
		end
		if mobileTextBox then
			mobileTextBox.CursorPosition = position
		end
	end

	local function highlightAllText()
		local current = textBox or mobileTextBox
		if current == nil or current.Parent == nil then
			return
		end
		local inputLength = utf8.len(current.Text)
		if inputLength then
			setSelectionStart(0)
			setCursorPosition(inputLength + 1)
		end
	end

	local function focusTextBox()
		if textBox == nil then
			return
		end
		textBox:CaptureFocus()
		if props.focusBehavior == InputFocusBehavior.Highlight then
			--! Highlighting in the same frame selects every character except the last one (engine bug).
			task.spawn(highlightAllText)
		end
	end

	local function releaseTextBoxFocus()
		if textBox then
			textBox:ReleaseFocus()
		end
	end

	local handle: InternalTextInputRef = {
		getIsFocused = function(): boolean
			return if textBox then textBox:IsFocused() else nil :: any
		end,
		focus = focusTextBox,
		releaseFocus = releaseTextBoxFocus,
		getSelectionStart = function(): number
			return if textBox then textBox.SelectionStart else nil :: any
		end,
		getCursorPosition = function(): number
			return if textBox then textBox.CursorPosition else nil :: any
		end,
		setCursorPosition = setCursorPosition,
		setSelectionStart = setSelectionStart,
	}

	local function clearText()
		if textBox then
			textBox.Text = ""
		end
	end

	local function onTextChange(current: TextBox)
		--* Keeps text from being cleared while the mobile TextBox takes over.
		if current.Parent == nil or mobileTextBoxText ~= "" then
			return
		end
		local newText = current.Text
		if newText == lastDispatchedText then
			return
		end
		lastDispatchedText = newText
		if Vide.untrack(isScrollable) and boundsChecker then
			boundsChecker.Text = newText
		end
		props.onChanged(newText)
	end

	local function onFocusGained()
		if isDisabled() then
			return
		end

		local becomesTouchFocused = Vide.untrack(isScrollable) and isMobileDevice()
		if becomesTouchFocused and textBox and textBox.Parent then
			mobileTextBoxText = textBox.Text
		end

		focus(true)
		if props.onFocus then
			props.onFocus()
		end
		local focusBehavior = props.focusBehavior
		if focusBehavior == InputFocusBehavior.Clear then
			mobileTextBoxText = ""
			if textBox then
				textBox.Text = ""
			end
			if mobileTextBox then
				mobileTextBox.Text = ""
			end
		elseif focusBehavior == InputFocusBehavior.Highlight then
			shouldHighlight = true
		end

		--* Last, as React applies the state after the handler: the mobile TextBox replaces this one.
		if becomesTouchFocused then
			isTouchFocused(true)
		end
	end

	local function onInputChanged(inputObject: InputObject)
		--* Highlighting on input is only implemented for mouse clicks.
		if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
			shouldHighlight = false
		end
	end

	local function onInputEnded(inputObject: InputObject)
		if not shouldHighlight then
			return
		end
		shouldHighlight = false
		if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		highlightAllText()
	end

	local function onFocusLost(enterPressed: boolean, inputThatCausedFocusLoss: InputObject)
		focus(false)
		shouldHighlight = false

		if props.onFocusLost then
			props.onFocusLost(inputThatCausedFocusLoss)
		end
		if enterPressed and props.onReturnPressed then
			props.onReturnPressed()
		end

		if Vide.untrack(isScrollable) then
			isTouchFocused(false)
		end
	end

	local function onDragStarted(detector: UIDragDetector, position: Vector2)
		dragStartPosition = position
		if props.onDragStarted then
			props.onDragStarted(detector, position)
		end
	end

	local function onDrag(detector: UIDragDetector, position: Vector2)
		if props.onDrag then
			props.onDrag(detector, position)
		end
	end

	local function onDragEnded(detector: UIDragDetector, position: Vector2)
		if dragStartPosition == position then
			focusTextBox()
		else
			releaseTextBoxFocus()
			focus(false)
		end
		dragStartPosition = nil
		if props.onDragEnded then
			props.onDragEnded(detector, position)
		end
	end

	local function onCursorPositionChanged(current: TextBox)
		local frame = scrollingFrame
		local checker = boundsChecker
		if frame == nil or checker == nil then
			return
		end

		local textHeight = current.TextSize * current.LineHeight
		local canvasPositionY = frame.CanvasPosition.Y

		checker.Text = truncateTextToCursor(current)
		local truncatedTextHeight = checker.TextBounds.Y

		local top, bottom = paddingTop(), paddingBottom()
		local viewportTopEdge = canvasPositionY - top + bottom
		local viewportBottomEdge = canvasPositionY + frame.AbsoluteSize.Y - top - bottom

		--* The truncated text ends at the bottom of the cursor's line; scrolling up shows the line's top.
		if truncatedTextHeight - textHeight < viewportTopEdge then
			frame.CanvasPosition += Vector2.new(0, truncatedTextHeight - textHeight - viewportTopEdge)
		end
		if truncatedTextHeight > viewportBottomEdge then
			frame.CanvasPosition += Vector2.new(0, truncatedTextHeight - viewportBottomEdge)
		end
	end

	local hasDragDetector = props.onDragStarted ~= nil or props.onDrag ~= nil or props.onDragEnded ~= nil

	local function textBoxTag(suffix: string): () -> string
		return function()
			return `{variantProps().textBox.tag} data-testid={testId}--{suffix}`
		end
	end

	local function textBoxWrapper(scrollable: boolean, disabled: boolean): GuiObject
		local function textStyle(): ColorStyleValue
			return getDisabledStyle(tokens().Color.Content.Emphasis :: any, disabled)
		end
		local interactable = if hasDragDetector then focus else nil

		local function mainTextBox(): TextBox
			local checker = if scrollable
				then TextBox({
					isBoundsChecker = true,
					fontStyle = fontStyle,
					textStyle = textStyle,
					--! The padding goes in Size, not a UIPadding, or TextBounds comes out wrong.
					Size = function()
						return UDim2.new(1, 0, 1, paddingTop() + paddingBottom())
					end,
				})
				else nil
			local instance = TextBox({
				text = props.text,
				placeholder = props.placeholder,
				textInputType = props.textInputType,
				fontStyle = fontStyle,
				textStyle = textStyle,
				isMultiLine = scrollable,
				isDisabled = disabled,
				tag = textBoxTag("textbox"),
				Interactable = interactable,
				Size = if scrollable then textBoxSizeFullHeight else nil,
				automaticSize = function(): Enum.AutomaticSize?
					return if scrollable
							and not isTouchFocused()
							and Value.read(props.text) ~= ""
						then Enum.AutomaticSize.Y
						else nil
				end,
				padding = textBoxWrapperPadding,
				onFocusGained = onFocusGained,
				onFocusLost = function(enterPressed: boolean, inputObject: InputObject)
					--* On touch devices the mobile TextBox reports focus loss.
					if not (scrollable and isMobileDevice()) then
						onFocusLost(enterPressed, inputObject)
					end
				end,
				onTextChanged = onTextChange,
				onCursorPositionChanged = if scrollable then onCursorPositionChanged else nil,
				onInputChanged = onInputChanged,
				onInputEnded = onInputEnded,
				children = if checker then named("BoundsChecker", checker) else nil,
			})
			instance.Name = "TextBox"
			textBox = instance
			boundsChecker = checker
			Vide.cleanup(function()
				if textBox == instance then
					textBox = nil
				end
				if boundsChecker == checker then
					boundsChecker = nil
				end
			end)
			return instance
		end

		--* AutomaticSize does not work with native mobile TextBoxes, so touch input gets a fixed-size one.
		local function touchTextBox(): TextBox
			local instance = TextBox({
				text = props.text,
				placeholder = props.placeholder,
				textInputType = props.textInputType,
				fontStyle = fontStyle,
				textStyle = textStyle,
				isMultiLine = true,
				isDisabled = disabled,
				padding = textBoxWrapperPadding,
				tag = textBoxTag("mobile-textbox"),
				Interactable = interactable,
				Size = textBoxSizeFullHeight,
				onFocusLost = function(enterPressed: boolean, inputObject: InputObject)
					if isMobileDevice() then
						onFocusLost(enterPressed, inputObject)
					end
				end,
				onTextChanged = onTextChange,
				onCursorPositionChanged = onCursorPositionChanged,
			})
			instance.Name = "MobileTextBox"
			mobileTextBox = instance
			Vide.cleanup(function()
				if mobileTextBox == instance then
					mobileTextBox = nil
				end
			end)
			instance.Text = mobileTextBoxText
			mobileTextBoxText = ""
			task.delay(0, function()
				if instance.Parent ~= nil then
					instance:CaptureFocus()
				end
			end)
			return instance
		end

		if not scrollable then
			return View({
				LayoutOrder = 2,
				selection = { Selectable = false },
				padding = textBoxWrapperInsetPadding,
				tag = "fill size-full clip",
				testId = `{testId}--textbox-wrapper`,
				children = mainTextBox(),
			})
		end

		Vide.cleanup(function()
			scrollingFrame = nil
		end)
		return ScrollView({
			LayoutOrder = 2,
			selection = { Selectable = false },
			scroll = {
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.fromOffset(0, 0),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				VerticalScrollBarInset = Enum.ScrollBarInset.Always,
			},
			layout = {
				FillDirection = Enum.FillDirection.Vertical,
				ItemLineAlignment = Enum.ItemLineAlignment.Center,
			},
			onCanvasPositionChanged = function(frame: ScrollingFrame)
				lastScrollingFrameCanvasPosition = frame.CanvasPosition
			end,
			scrollingFrameRef = function(frame: ScrollingFrame)
				scrollingFrame = frame
				frame.ClipsDescendants = true
				frame.CanvasPosition = lastScrollingFrameCanvasPosition
			end,
			padding = textBoxWrapperInsetPadding,
			tag = "fill size-full clip",
			testId = `{testId}--textbox-wrapper`,
			children = {
				Vide.show(function()
					return not isTouchFocused()
				end, mainTextBox),
				Vide.show(isTouchFocused, touchTextBox),
			},
		})
	end

	local function slot(element: Types.Children?, name: string, layoutOrder: number, disabled: boolean): any
		if element == nil then
			return nil
		end
		local function wrapper(): GuiObject
			return named(
				name,
				View({
					GroupTransparency = if disabled then Constants.DISABLED_TRANSPARENCY else nil,
					LayoutOrder = layoutOrder,
					tag = "size-0-full auto-x",
					testId = `{testId}--{string.lower(name)}`,
					children = named("Children", element),
				})
			)
		end
		if type(element) == "function" then
			local source = element :: () -> any
			return Vide.show(function()
				return source() ~= nil
			end, wrapper)
		end
		return wrapper()
	end

	local function hasTrailingElement(): boolean
		local element = props.trailingElement
		if type(element) == "function" then
			return (element :: () -> any)() ~= nil
		end
		return element ~= nil
	end

	local function build(disabled: boolean): GuiObject
		local children = {
			if hasDragDetector
				then create("UIDragDetector")({
					Name = "DragDetector",
					DragStyle = Enum.UIDragDetectorDragStyle.Scriptable,
					Enabled = function()
						return not focus() and not disabled
					end,
					Vide.action(function(instance: Instance)
						local detector = instance :: UIDragDetector
						Vide.cleanup(detector.DragStart:Connect(function(position: Vector2)
							onDragStarted(detector, position)
						end))
						Vide.cleanup(detector.DragContinue:Connect(function(position: Vector2)
							onDrag(detector, position)
						end))
						Vide.cleanup(detector.DragEnd:Connect(function(position: Vector2)
							onDragEnded(detector, position)
						end))
					end),
				})
				else nil,
			if props.backgroundGradient ~= nil then named("Background", props.backgroundGradient) else nil,
			slot(props.leadingElement, "Leading", 1, disabled),
			named(
				"TextBoxWrapper",
				rebuildOn(isScrollable, function(scrollable: boolean)
					return textBoxWrapper(scrollable, disabled)
				end)
			),
			Vide.show(function()
				return Value.read(props.hasClearButton) == true
			end, function()
				return named(
					"Clear",
					View({
						isDisabled = disabled,
						GroupTransparency = if disabled then Constants.DISABLED_TRANSPARENCY else nil,
						LayoutOrder = 3,
						Visible = function()
							return Value.read(props.text) ~= ""
						end,
						tag = function()
							return variantProps().clearButton.tag
						end,
						children = named(
							"ClearButton",
							View({
								onActivated = clearText,
								padding = function()
									return UDim.new(0, variantProps().clearButton.padding)
								end,
								--* Centered on the single-line height, which engine layouts cannot express.
								Position = function()
									return UDim2.fromOffset(
										0,
										(variantProps().container.minHeight - tokens().Stroke.Standard) / 2
									)
								end,
								stateLayer = { affordance = StateLayerAffordance.None },
								tag = "anchor-center-left auto-xy",
								testId = `{testId}--clear-button`,
								children = named(
									"Icon",
									Icon({
										name = function(): string
											return variantProps().clearButton.icon
										end,
									})
								),
							})
						),
					})
				)
			end),
			slot(props.trailingElement, "Trailing", 4, disabled),
			--* Circle radius is half the single-line height, so a multi-line input is not a capsule.
			Vide.show(function()
				return Value.read(props.radius) == Radius.Circle
			end, function()
				return named(
					"CornerRadius",
					CornerRadius({
						value = function()
							return UDim.new(0, math.ceil(variantProps().container.minHeight / 2))
						end,
						testId = `{testId}--corner-radius`,
					})
				)
			end),
		}

		local root = View(withCommonProps(props, {
			Size = function()
				return UDim2.new(1, 0, 0, borderFrameHeight())
			end,
			selection = {
				Selectable = if disabled then false else props.Selectable,
				NextSelectionUp = props.NextSelectionUp,
				NextSelectionDown = props.NextSelectionDown,
				NextSelectionLeft = props.NextSelectionLeft,
				NextSelectionRight = props.NextSelectionRight,
			},
			cursor = function(): Types.Cursor
				return {
					radius = UDim.new(0, variantProps().container.radius),
					offset = tokens().Stroke.Thick,
					borderWidth = tokens().Stroke.Thick,
				}
			end,
			stroke = function(): Types.Stroke?
				local container = variantProps().container
				local strokeStyle = container.strokeStyle
				if not (strokeStyle and container.strokeThickness) then
					return nil
				end
				return {
					Color = strokeStyle.Color3,
					Transparency = if disabled
						then blendTransparencies(strokeStyle.Transparency, Constants.DISABLED_TRANSPARENCY)
						else strokeStyle.Transparency,
					Thickness = container.strokeThickness,
					BorderStrokePosition = if focus()
						then Enum.BorderStrokePosition.Center
						else Enum.BorderStrokePosition.Inner,
				}
			end,
			padding = {
				left = function()
					return UDim.new(0, outerBorderThickness()) + (Value.read(horizontalPadding.left) or UDim.new(0, 0))
				end,
				--* Clear has padding of its own, so only the border is accounted for.
				right = function()
					if not hasTrailingElement() and Value.read(props.hasClearButton) then
						return UDim.new(0, outerBorderThickness())
					end
					return UDim.new(0, outerBorderThickness()) + (Value.read(horizontalPadding.right) or UDim.new(0, 0))
				end,
				top = function()
					return UDim.new(0, outerBorderThickness())
				end,
				bottom = function()
					return UDim.new(0, outerBorderThickness())
				end,
			},
			onActivated = if not disabled
				then function()
					focusTextBox()
				end
				else nil,
			isDisabled = disabled,
			backgroundStyle = function(): ColorStyleValue?
				if props.backgroundGradient ~= nil then
					return getDisabledStyle({ Color3 = Color3.new(1, 1, 1), Transparency = 0.001 }, disabled)
				end
				local bgStyle = variantProps().container.bgStyle
				if not bgStyle then
					return nil
				end
				return getDisabledStyle({ Color3 = bgStyle.Color3, Transparency = bgStyle.Transparency }, disabled)
			end,
			stateLayer = { affordance = StateLayerAffordance.None },
			tag = function()
				return variantProps().container.tag
			end,
			children = children,
		}) :: any)

		if props.inputRef then
			props.inputRef(root)
		end
		return root
	end

	if props.textBoxRef then
		props.textBoxRef(handle)
	end

	local isDisabledProp = props.isDisabled
	return rebuildOn(if type(isDisabledProp) == "function" then isDisabled else isDisabledProp == true, build)
end

return InternalTextInput
