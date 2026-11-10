local BuilderIcons = require("../Packages/BuilderIcons")
type IconVariant = BuilderIcons.IconVariant

local BadgeVariant = require("../Enums/BadgeVariant")
type BadgeVariant = BadgeVariant.BadgeVariant

local StateLayerAffordance = require("../Enums/StateLayerAffordance")
type StateLayerAffordance = StateLayerAffordance.StateLayerAffordance

local StateLayerMode = require("../Enums/StateLayerMode")
type StateLayerMode = StateLayerMode.StateLayerMode

local CursorType = require("../Enums/CursorType")
type CursorType = CursorType.CursorType

local ControlState = require("../Enums/ControlState")
type ControlState = ControlState.ControlState
export type StateChangedCallback = (newState: ControlState) -> ()

local ButtonVariant = require("../Enums/ButtonVariant")
type ButtonVariant = ButtonVariant.ButtonVariant

local InputFocusBehavior = require("../Enums/InputFocusBehavior")
type InputFocusBehavior = InputFocusBehavior.InputFocusBehavior

local InputSize = require("../Enums/InputSize")
type InputSize = InputSize.InputSize

local InputPlacement = require("../Enums/InputPlacement")
type InputPlacement = InputPlacement.InputPlacement

export type InputGroupSize = typeof(InputSize.XSmall) | typeof(InputSize.Small) | typeof(InputSize.Medium)

local InputVariant = require("../Enums/InputVariant")
type InputVariant = InputVariant.InputVariant

--- A prop that takes a plain value or a Vide source (any function returning the value).
export type Value<T> = T | () -> T

--- Foundation's name for `Value`.
export type Bindable<T> = Value<T>

--- What Vide accepts as children: instances, arrays of them, or functions returning them.
export type Children = Instance | { [any]: any } | () -> any

export type IconAccessoryConfig = {
	type: nil,
	iconName: string,
	iconVariant: IconVariant?,
}

export type AvatarAccessoryConfig = {
	type: "Avatar",
	userId: number,
}

export type HintAccessoryConfig = {
	type: "Hint",
	text: string,
}

export type BadgeAccessoryConfig = {
	type: "Badge",
	text: string?,
	icon: string?,
	variant: BadgeVariant?,
}

export type ActionProps = {
	onActivated: () -> (),
	variant: ButtonVariant?,
	text: string,
}

export type ResponsiveValue<T> = {
	xs: T,
	sm: T,
	md: T,
	lg: T,
	xl: T,
	xxl: T?,
}

export type NativeCommonProps = {
	AnchorPoint: Value<Vector2>?,
	LayoutOrder: Value<number>?,
	Position: Value<UDim2>?,
	Visible: Value<boolean>?,
	ZIndex: Value<number>?,
}

export type NativeCallbackProps = {
	onAbsoluteSizeChanged: ((instance: GuiObject) -> ())?,
	onAbsolutePositionChanged: ((instance: GuiObject) -> ())?,
}

export type CommonProps = {
	testId: string?,
} & NativeCallbackProps & NativeCommonProps

export type FlexItem = {
	FlexMode: Value<Enum.UIFlexMode>?,
	GrowRatio: Value<number>?,
	ShrinkRatio: Value<number>?,
	ItemLineAlignment: Value<Enum.ItemLineAlignment>?,
}

export type SizeConstraint = {
	MinSize: Value<Vector2>?,
	MaxSize: Value<Vector2>?,
}

export type Slice = {
	center: Rect?,
	scale: number?,
}

export type Stroke = {
	Color: Value<Color3>?,
	Thickness: Value<number>?,
	Transparency: Value<number>?,
	LineJoinMode: Value<Enum.LineJoinMode>?,
	BorderStrokePosition: Value<Enum.BorderStrokePosition>?,
}

export type ColorStyleValue = {
	-- Both values are optional because of token types, but should be set.
	Color3: Color3?,
	Transparency: number?,
}

export type ColorStyle = Value<ColorStyleValue>

-- Partial HSV for the color picker: H is required (0-360), S and V are optional (0-100).
export type PartialColorHSV = { H: number, S: number?, V: number? }

export type ItemId = string | number
export type OnItemActivated = (id: ItemId) -> ()

export type StateLayer = {
	inset: boolean?,
	mode: Value<StateLayerMode>?,
	affordance: Value<StateLayerAffordance>?,
}

export type SelectionProps = {
	Selectable: Value<boolean>?,
	NextSelectionUp: Value<GuiObject?>?,
	NextSelectionDown: Value<GuiObject?>?,
	NextSelectionLeft: Value<GuiObject?>?,
	NextSelectionRight: Value<GuiObject?>?,
}

export type Selection = {
	Selectable: Value<boolean>?,
	NextSelectionUp: Value<GuiObject?>?,
	NextSelectionDown: Value<GuiObject?>?,
	NextSelectionLeft: Value<GuiObject?>?,
	NextSelectionRight: Value<GuiObject?>?,
	SelectionImageObject: Value<GuiObject?>?,
	SelectionOrder: Value<number>?,
}

export type SelectionGroup = {
	SelectionBehaviorUp: Value<Enum.SelectionBehavior>?,
	SelectionBehaviorDown: Value<Enum.SelectionBehavior>?,
	SelectionBehaviorLeft: Value<Enum.SelectionBehavior>?,
	SelectionBehaviorRight: Value<Enum.SelectionBehavior>?,
}

export type Tags = string | { [string]: boolean }

export type BaseInteractableProps = {
	-- The state layer configuration for the element.
	stateLayer: StateLayer?,
	-- Called when the element is activated with the primary input.
	onActivated: ((self: GuiObject, inputObject: InputObject, clickCount: number) -> ())?,
	-- Called when the element is activated with the secondary input.
	onSecondaryActivated: ((self: GuiObject, inputObject: InputObject) -> ())?,
	-- Called when the control state of the element changes.
	onStateChanged: StateChangedCallback?,
	-- Whether the element is disabled.
	isDisabled: Value<boolean>?,
}

export type AspectRatioTable = {
	AspectRatio: Value<number>,
	AspectType: Value<Enum.AspectType>?,
	DominantAxis: Value<Enum.DominantAxis>?,
}

export type AspectRatio = Value<number> | AspectRatioTable

export type CornerRadiusValue = Value<number | UDim>

export type CornerRadiusTable = {
	topLeft: CornerRadiusValue?,
	topRight: CornerRadiusValue?,
	bottomRight: CornerRadiusValue?,
	bottomLeft: CornerRadiusValue?,
}

export type CornerRadius = Value<UDim> | number | CornerRadiusTable

export type PaddingTable = {
	top: Value<UDim>?,
	bottom: Value<UDim>?,
	left: Value<UDim>?,
	right: Value<UDim>?,
}

export type Padding = Value<UDim> | number | Vector2 | UDim2 | PaddingTable

export type ListLayout = {
	FillDirection: Value<Enum.FillDirection>?,
	ItemLineAlignment: Value<Enum.ItemLineAlignment>?,
	HorizontalAlignment: Value<Enum.HorizontalAlignment>?,
	HorizontalFlex: Value<Enum.UIFlexAlignment>?,
	VerticalAlignment: Value<Enum.VerticalAlignment>?,
	VerticalFlex: Value<Enum.UIFlexAlignment>?,
	Padding: Value<UDim>?,
	SortOrder: Value<Enum.SortOrder>?,
	Wraps: Value<boolean>?,
}

export type CursorConfig = {
	radius: UDim?,
	offset: number?,
	borderWidth: number?,
}

export type Cursor = CursorType | CursorConfig

export type BaseGuiObjectProps = {
	aspectRatio: AspectRatio?,
	cornerRadius: CornerRadius?,
	-- The table props below may also be sources of a table or nil, which add and remove the component.
	flexItem: Value<FlexItem?>?,
	layout: Value<ListLayout?>?,
	padding: Padding?,
	scale: Value<number>?,
	sizeConstraint: Value<SizeConstraint?>?,
	stroke: Value<Stroke?>?,

	backgroundStyle: ColorStyle?,
	selection: Selection?,
	cursor: Value<Cursor?>?,
	selectionGroup: (Value<boolean> | SelectionGroup)?,

	AutoLocalize: Value<boolean>?,
	AutomaticSize: Value<Enum.AutomaticSize>?,
	BorderSizePixel: Value<number>?,
	BorderColor3: Value<Color3>?,
	BorderMode: Value<Enum.BorderMode>?,
	ClipsDescendants: Value<boolean>?,
	InputSink: Value<Enum.InputSink>?,
	Rotation: Value<number>?,
	Size: Value<UDim2>?,
	SizeConstraint: Value<Enum.SizeConstraint>?,

	tag: Value<Tags?>?,
	children: Children?,
}

export type GuiObjectProps = BaseGuiObjectProps & BaseInteractableProps

export type FontFaceTable = {
	Family: string,
	Weight: Enum.FontWeight,
	Style: Enum.FontStyle,
}

export type FontFace = FontFaceTable | Value<Font> | Enum.Font

export type FontStyle = {
	Font: FontFace?,
	FontSize: number?,
	LineHeight: number?,
}

export type TextInputRef = {
	getIsFocused: () -> boolean,
	focus: () -> (),
	releaseFocus: () -> (),
	getSelectionStart: () -> number,
	getCursorPosition: () -> number,
	setSelectionStart: (position: number) -> (),
	setCursorPosition: (position: number) -> (),
}

export type InternalTextInputRef = TextInputRef

export type TextInputCommonProps = {
	-- Input text value.
	text: Value<string>,
	-- Called when the input text changes.
	onChanged: (text: string) -> (),
	-- The label shown alongside the text input.
	label: Value<string>,
	-- Subcaption shown below the text input, red on error.
	hint: Value<string?>?,
	-- The size of the text input.
	size: Value<InputSize>?,
	-- Style variant of the text input.
	variant: Value<InputVariant>?,
	-- Width of the text input.
	width: Value<UDim>?,
	-- Text shown when the input is empty.
	placeholder: Value<string?>?,
	-- Whether the text input is disabled.
	isDisabled: Value<boolean>?,
	-- true shows "*", false shows " (optional)", nil shows nothing.
	isRequired: Value<boolean?>?,
	-- Whether to show the text input as erroneous.
	hasError: Value<boolean>?,
	-- Whether the input has a clear button.
	hasClearButton: Value<boolean>?,
	-- Behavior of the text input when focused. Mobile does not support Highlight.
	focusBehavior: InputFocusBehavior?,
	-- Receives a handle to the inner TextBox.
	textBoxRef: ((TextInputRef) -> ())?,
	-- Called when the TextBox gains focus.
	onFocusGained: (() -> ())?,
	-- Called when the TextBox loses focus, with the InputObject that caused it when available.
	onFocusLost: ((inputObject: InputObject?) -> ())?,
	-- Receives the outermost container of the internal text input.
	inputRef: ((GuiObject) -> ())?,
}

export type InternalInputGroupProps = {
	-- Optional label above the grouped inputs.
	legend: Value<string?>?,
	-- Size applied to the group and inherited by its inputs.
	size: InputGroupSize?,
	-- Where the input sits relative to its label.
	placement: InputPlacement?,
	children: Children?,
} & CommonProps

export type PopoverAnchor = GuiObject | MeasurableObject

type MeasurableObjectImpl = {
	__index: MeasurableObjectImpl,
	GetPropertyChangedSignal: (self: MeasurableObject, propertyName: string) -> MeasurableObjectSignal<any>,
	SetPosition: (self: MeasurableObject, position: Vector2) -> (),
	SetSize: (self: MeasurableObject, size: Vector2) -> (),
}

type MeasurableObjectSignalConnection = {
	Disconnect: (self: MeasurableObjectSignalConnection) -> (),
}

export type MeasurableObjectSignal<T> = {
	Connect: (self: MeasurableObjectSignal<T>, callback: (value: T) -> ()) -> MeasurableObjectSignalConnection,
}

export type MeasurableObject = typeof(setmetatable(
	{} :: { AbsolutePosition: Vector2, AbsoluteSize: Vector2 },
	{} :: MeasurableObjectImpl
))

export type OverlayConfig = {
	DisplayOrder: number?,
	gui: nil,
}

return {}
