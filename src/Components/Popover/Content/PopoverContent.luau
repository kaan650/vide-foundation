local Vide = require("../../../Packages/Vide")

local Constants = require("../../../Constants")
local ElevationLayer = require("../../../Enums/ElevationLayer")
local ElevationProvider = require("../../../Providers/Elevation/ElevationProvider")
local Image = require("../../Image")
local PopoverAlign = require("../../../Enums/PopoverAlign")
local PopoverContext = require("../PopoverContext")
local PopoverSide = require("../../../Enums/PopoverSide")
local Radius = require("../../../Enums/Radius")
local StateLayerAffordance = require("../../../Enums/StateLayerAffordance")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local isPointInGuiObjectBounds = require("../../../Utility/isPointInGuiObjectBounds")
local useElevation = require("../../../Providers/Elevation/useElevation")
local useFloating = require("../useFloating")
local useOverlay = require("../../../Providers/Overlay/useOverlay")
local usePointerPosition = require("../../../Utility/usePointerPosition")
local useTokens = require("../../../Providers/Style/useTokens")
local withDefaults = require("../../../Utility/withDefaults")

type ColorStyleValue = Types.ColorStyleValue
type Radius = Radius.Radius
type SideConfig = useFloating.SideConfig
type AlignConfig = useFloating.AlignConfig
type Value<T> = Types.Value<T>

export type PopoverContentProps = {
	-- The side the popover should be anchored to.
	side: Value<SideConfig>?,
	-- The alignment of the popover relative to the anchor.
	align: Value<AlignConfig>?,
	-- Whether the popover should have an arrow.
	hasArrow: Value<boolean>?,
	-- Whether a plugin popover can receive keyboard focus. Unused: the elevated-plugin path is not ported.
	isFocusable: Value<boolean>?,
	-- Temporary opt-in for flagged input sinking. This will be removed when the behavior is finalized.
	DO_NOT_USE_hasContentInputSink: boolean?,
	-- Callback for when the backdrop is pressed. Does not swallow the press event.
	onPressedOutside: (() -> ())?,
	-- Selection behavior
	selection: Types.Selection?,
	selectionGroup: (Value<boolean> | Types.SelectionGroup)?,
	backgroundStyle: Types.ColorStyle?,
	radius: Value<typeof(Radius.Small) | typeof(Radius.Medium) | typeof(Radius.Circle)>?,
	-- Receives the content frame when the popover opens, and nil when it closes.
	ref: ((content: GuiObject?) -> ())?,
	-- Builds the content each time the popover opens; nested popovers made here stack above this one.
	children: (() -> any)?,
	-- The React key the content renders under, which names its container. Defaults to "Content".
	name: string?,
}

local defaultProps = {
	side = PopoverSide.Bottom,
	align = PopoverAlign.Center,
	hasArrow = true,
	selection = Constants.MODAL.DISABLE_SELECTION,
	selectionGroup = Constants.MODAL.TRAP_FOCUS,
	radius = Radius.Medium,
}

local radiusToTag: { [Radius]: string } = {
	[Radius.Small] = "radius-small",
	[Radius.Medium] = "radius-medium",
	[Radius.Circle] = "radius-circle",
}

local SHADOW_IMAGE = Constants.SHADOW_IMAGE
local SHADOW_SIZE = Constants.SHADOW_SIZE
local SHADOW_VERTICAL_OFFSET = 2

local function noop() end

--- The popover's floating panel. While open it renders into the overlay (or in place when there is none), next to
--- the anchor. Returns the in-place content as a source, nil while it is in the overlay.
local function PopoverContent(contentProps: PopoverContentProps): () -> any
	local props = withDefaults(contentProps, defaultProps)
	local popoverContext = PopoverContext()
	local overlay = useOverlay()
	local tokens = useTokens()
	local elevation = useElevation(ElevationLayer.Popover, { stackAboveOwner = true })
	local testId = popoverContext.testId
	local onPressedOutside = props.onPressedOutside

	local function hasArrow(): boolean
		return typeof(popoverContext.anchor()) == "Instance" and Value.read(props.hasArrow) == true
	end
	local function arrowSide(): number
		return tokens().Size.Size_200
	end
	local function arrowHeight(): number
		local arrowWidth = arrowSide() * math.sqrt(2)
		return arrowWidth / 2
	end
	local function backgroundStyle(): ColorStyleValue
		local style: ColorStyleValue? = Value.read(props.backgroundStyle)
		return style or tokens().Color.Surface.Surface_100 :: ColorStyleValue
	end

	local content = Vide.source(nil :: GuiObject?)
	local getContent: () -> GuiObject? = content :: any

	local floating = useFloating(popoverContext.isOpen, popoverContext.anchor, getContent, overlay, function()
		return Value.read(props.side)
	end, function()
		return Value.read(props.align)
	end, function()
		return if hasArrow() then arrowHeight() else 0
	end)

	local function offsetPosition(source: () -> Vector2): () -> UDim2
		return function()
			local value = source()
			return UDim2.fromOffset(value.X, value.Y)
		end
	end

	local function Backdrop(pressedOutside: () -> ()): GuiObject
		local backdrop = View({
			ZIndex = 1,
			stateLayer = {
				affordance = StateLayerAffordance.None,
			},
			Size = UDim2.fromScale(2, 2),
			tag = "position-center-center anchor-center-center",
			testId = `{testId}--backdrop`,
		})
		backdrop.Name = "Backdrop"

		local pointerPosition = usePointerPosition(backdrop)
		Vide.cleanup(backdrop:GetPropertyChangedSignal("GuiState"):Connect(function()
			if backdrop.GuiState ~= Enum.GuiState.Press then
				return
			end
			local anchor = Vide.untrack(popoverContext.anchor)
			if anchor and typeof(anchor) == "Instance" then
				local guiAnchor = anchor :: GuiObject
				if isPointInGuiObjectBounds(guiAnchor, Vide.untrack(pointerPosition)) then
					return
				end
				if guiAnchor.GuiState ~= Enum.GuiState.Idle then
					return
				end
			end
			pressedOutside()
		end))

		return backdrop
	end

	local function Shadow(): GuiObject
		local shadow = Image({
			AnchorPoint = floating.anchorPoint,
			Image = SHADOW_IMAGE,
			Size = function()
				return floating.contentSize() + UDim2.fromOffset(SHADOW_SIZE, SHADOW_SIZE)
			end,
			Position = function()
				local position, anchorPoint = floating.position(), floating.anchorPoint()
				local xShift = if anchorPoint.X == 0 then -1 else 1
				local yShift = if anchorPoint.Y == 0 then -1 else 1
				return UDim2.fromOffset(
					position.X + SHADOW_SIZE / 2 * xShift,
					position.Y + SHADOW_SIZE / 2 * yShift + SHADOW_VERTICAL_OFFSET
				)
			end,
			ZIndex = 2,
			slice = {
				center = Rect.new(SHADOW_SIZE, SHADOW_SIZE, SHADOW_SIZE + 1, SHADOW_SIZE + 1),
			},
			imageStyle = function()
				return tokens().Color.Extended.Black.Black_20 :: ColorStyleValue
			end,
			testId = `{testId}--shadow`,
		})
		shadow.Name = "Shadow"
		return shadow
	end

	local function Arrow(): GuiObject
		local arrow = View({
			Size = function()
				return UDim2.fromOffset(arrowSide(), arrowSide())
			end,
			Position = offsetPosition(floating.arrowPosition),
			Rotation = 45,
			ZIndex = 3,
			backgroundStyle = backgroundStyle,
			tag = "anchor-center-center",
			testId = `{testId}--arrow`,
		})
		arrow.Name = "Arrow"
		return arrow
	end

	local function Content(): GuiObject
		local contentView = View({
			AnchorPoint = floating.anchorPoint,
			Position = offsetPosition(floating.position),
			selection = props.selection,
			selectionGroup = props.selectionGroup,
			sizeConstraint = {
				MaxSize = floating.screenSize,
			},
			stateLayer = {
				affordance = StateLayerAffordance.None,
			},
			ZIndex = 4,
			--* Keeps content presses from reaching the backdrop or the UI below.
			onActivated = if onPressedOutside or props.DO_NOT_USE_hasContentInputSink then noop else nil,
			backgroundStyle = backgroundStyle,
			tag = function()
				return `auto-xy {radiusToTag[Value.read(props.radius)]}`
			end,
			testId = `{testId}--content`,
			children = ElevationProvider.ElevationOwnerScope({
				owner = elevation,
				children = function()
					return if props.children then props.children() else nil
				end,
			}),
		})
		contentView.Name = "Content"
		return contentView
	end

	local function Container(): GuiObject
		local contentView = Content()
		local container = View({
			ZIndex = elevation.zIndex,
			tag = "size-full",
			Visible = floating.isVisible,
			testId = `{testId}--container`,
			children = {
				if onPressedOutside then Backdrop(onPressedOutside) else nil,
				Shadow(),
				Vide.show(hasArrow, Arrow),
				contentView,
			},
		})
		container.Name = props.name or "Content"
		Vide.cleanup(container)

		content(contentView)
		local ref = props.ref
		if ref then
			ref(contentView)
			Vide.cleanup(function()
				ref(nil)
			end)
		end
		return container
	end

	Vide.show(function()
		return if popoverContext.isOpen() then overlay() else nil
	end, function(target: () -> GuiBase2d)
		local container = Container()
		Vide.effect(function()
			container.Parent = target()
		end)
		return container
	end)

	return Vide.show(function()
		return popoverContext.isOpen() and overlay() == nil
	end, Container)
end

return PopoverContent
