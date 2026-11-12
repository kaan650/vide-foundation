local Vide = require("../../Packages/Vide")

local CloseAffordance = require("../CloseAffordance")
local Constants = require("../../Constants")
local DialogProvider = require("./DialogProvider")
local DialogSize = require("../../Enums/DialogSize")
local DialogTypes = require("./Types")
local ElevationLayer = require("../../Enums/ElevationLayer")
local ElevationProvider = require("../../Providers/Elevation/ElevationProvider")
local Image = require("../Image")
local Motion = require("../../Utility/Motion")
local OnCloseCallbackReason = require("../../Enums/OnCloseCallbackReason")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local create = require("../../Utility/create")
local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local useDialog = require("./useDialog")
local useDialogResponsiveSize = require("./useDialogResponsiveSize")
local useDialogVariants = require("./useDialogVariants").useDialogVariants
local useElevation = require("../../Providers/Elevation/useElevation")
local useOverlay = require("../../Providers/Overlay/useOverlay")
local usePreferences = require("../../Providers/Preferences/usePreferences")
local useTokens = require("../../Providers/Style/useTokens")
local withDefaults = require("../../Utility/withDefaults")

type DialogSize = DialogSize.DialogSize
type OnCloseCallbackReason = OnCloseCallbackReason.OnCloseCallbackReason
type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

export type DialogProps = {
	-- Called when the dialog asks to close: after the close animation, with "BackdropClick" when the backdrop was
	-- pressed. Without it the dialog has no close button.
	onClose: ((reason: OnCloseCallbackReason?) -> ())?,
	size: Value<DialogSize>?,
	-- Renders in place instead of into the overlay.
	disablePortal: Value<boolean>?,
	hasBackdrop: Value<boolean>?,
	-- Receives the dialog's surface.
	ref: ((instance: GuiObject) -> ())?,
	-- Builds the dialog's parts (Title, Content, Actions...), which must be created inside it.
	children: (() -> any)?,
	testId: string?,
} & Types.NativeCallbackProps

type InternalProps = {
	size: Value<DialogSize>,
	disablePortal: Value<boolean>,
	hasBackdrop: Value<boolean>,
	testId: string,
} & DialogProps

local defaultProps = {
	size = DialogSize.Medium,
	disablePortal = true,
	hasBackdrop = false,
	testId = "--foundation-dialog",
}

local SHADOW_IMAGE = Constants.SHADOW_IMAGE
local SHADOW_SIZE = Constants.SHADOW_SIZE

local function noop() end

type WrapperState = "reduced" | "animating" | "static"

local function Dialog(props: InternalProps): () -> any
	local variants = useDialogVariants()
	local tokens = useTokens()
	local preferences = usePreferences()
	local overlay = useOverlay()
	local elevation = useElevation(ElevationLayer.Dialog, { stackAboveOwner = false })
	local dialogContext = useDialog()

	useDialogResponsiveSize(dialogContext.size)

	local function maxWidth(): number
		return variants().inner.maxWidth * tokens().Config.UI.Scale
	end
	local function reducedMotion(): boolean
		return preferences().reducedMotion == true
	end
	local function animationOffset(): number
		return tokens().Size.Size_800
	end

	local dialogSize = Vide.source(Vector2.zero)
	local animating = Vide.source(true)
	local closing = false
	local closeReason: OnCloseCallbackReason? = nil

	local backdropTransparency, setBackdropTransparencyGoal = Motion.useAnimatedBinding(1)
	local bottomPosition, setBottomPositionGoal = Motion.useAnimatedBinding(Vide.untrack(animationOffset), function()
		if closing then
			--* `animating` stays true through unmount so the wrapper keeps its faded GroupTransparency until onClose
			--* tears the dialog down.
			if props.onClose then
				props.onClose(closeReason)
			end
		else
			animating(false)
		end
	end)

	Vide.untrack(function()
		local current = tokens()
		if reducedMotion() then
			setBottomPositionGoal(Motion.instant(0))
			setBackdropTransparencyGoal(Motion.instant(0))
		else
			setBottomPositionGoal(Motion.ease(0, {
				easingStyle = current.Ease.StandardOut,
				duration = current.Time.Time_300,
			}))
			setBackdropTransparencyGoal(Motion.ease(0, {
				duration = current.Time.Time_100,
			}))
		end
	end)

	local function closeDialog(reason: OnCloseCallbackReason?)
		if closing then
			return
		end
		closeReason = reason
		local current = Vide.untrack(tokens)
		local offset = current.Size.Size_800
		if Vide.untrack(reducedMotion) then
			closing = true
			setBottomPositionGoal(Motion.instant(offset))
			setBackdropTransparencyGoal(Motion.instant(1))
		else
			setBottomPositionGoal(Motion.ease(offset, {
				easingStyle = current.Ease.StandardIn,
				duration = current.Time.Time_200,
			}))
			setBackdropTransparencyGoal(Motion.ease(1, {
				duration = current.Time.Time_100,
			}))
			animating(true)
			closing = true
		end
	end

	local function requestClose(reason: OnCloseCallbackReason?)
		local onClose = props.onClose
		if not onClose then
			return
		end
		if Vide.untrack(reducedMotion) then
			onClose(reason)
		else
			closeDialog(reason)
		end
	end

	local shadow = Image({
		Image = SHADOW_IMAGE,
		Size = function()
			local size = dialogSize()
			return UDim2.fromOffset(size.X + SHADOW_SIZE * 2, size.Y + SHADOW_SIZE * 2)
		end,
		slice = {
			center = Rect.new(SHADOW_SIZE, SHADOW_SIZE, SHADOW_SIZE, SHADOW_SIZE),
			scale = 2,
		},
		imageStyle = function()
			return variants().shadow.imageStyle
		end,
		testId = `{props.testId}--shadow`,
	})
	shadow.Name = "Shadow"

	local shadowWrapper = View({
		tag = function()
			return variants().container.tag
		end,
		ZIndex = 2,
		children = shadow,
	})
	shadowWrapper.Name = "DialogShadowWrapper"

	local closeAffordance = if props.onClose
		then CloseAffordance({
			onActivated = function()
				requestClose(nil)
			end,
			NextSelectionDown = dialogContext.contentStartRef,
			Position = function()
				local offset = variants().closeAffordance.offset
				return UDim2.new(1, -offset, 0, offset)
			end,
			AnchorPoint = Vector2.new(1, 0),
			ZIndex = 2,
			testId = `{props.testId}--close-affordance`,
		}) :: GuiObject
		else nil
	if closeAffordance then
		closeAffordance.Name = "CloseAffordance"
		dialogContext.setCloseAffordanceRef(closeAffordance)
		Vide.cleanup(function()
			dialogContext.setCloseAffordanceRef(nil)
		end)
	end

	local body = View({
		tag = function()
			return variants().body.tag
		end,
		onAbsoluteSizeChanged = function(rbx: GuiObject)
			local size = rbx.AbsoluteSize
			if size.X > 0 and size.Y > 0 then
				dialogSize(size)
			end
		end,
		testId = `{props.testId}--body`,
		children = ElevationProvider.ElevationOwnerScope({
			owner = elevation,
			children = function()
				return if props.children then props.children() else nil
			end,
		}),
	})
	body.Name = "DialogBody"

	local inner = View({
		tag = function()
			return variants().inner.tag
		end,
		sizeConstraint = {
			MaxSize = function()
				return Vector2.new(maxWidth(), math.huge)
			end,
		},
		stateLayer = {
			affordance = StateLayerAffordance.None,
		},
		selection = DialogTypes.nonSelectable,
		selectionGroup = DialogTypes.isolatedSelectionGroup,
		--* Sinks presses so they do not reach the backdrop.
		onActivated = noop,
		LayoutOrder = 1,
		onAbsoluteSizeChanged = props.onAbsoluteSizeChanged,
		onAbsolutePositionChanged = props.onAbsolutePositionChanged,
		testId = props.testId,
		children = { closeAffordance, body },
	})
	inner.Name = "DialogInner"
	if props.ref then
		props.ref(inner)
	end

	local dialogNode = View({
		tag = function()
			return variants().container.tag
		end,
		ZIndex = 3,
		children = inner,
	})
	dialogNode.Name = "Dialog"

	--* While animating, the wrapper is a CanvasGroup; React remounts it as a Frame afterwards. The dialog lives in
	--* this Folder, moved between wrappers, so its content is not rebuilt (Foundation's stableContainer).
	local stableContainer = create("Folder")({ Name = "Folder" })
	local nodes: { Instance } = { stableContainer, shadowWrapper, dialogNode }
	Vide.cleanup(function()
		for _, node in nodes do
			node:Destroy()
		end
	end)

	local function Wrapper(state: WrapperState): GuiObject
		local reduced = state == "reduced"
		local wrapper = View({
			Position = if reduced
				then nil
				else function()
					return UDim2.new(0.5, 0, 0.5, bottomPosition())
				end,
			sizeConstraint = if reduced
				then nil
				else {
					MaxSize = function()
						return Vector2.new(maxWidth() + SHADOW_SIZE * 2, math.huge)
					end,
				},
			testId = `{props.testId}--content-wrapper`,
			tag = if reduced then "size-full" else "anchor-center-center size-full",
			ZIndex = 2,
			GroupTransparency = if state == "animating"
				then function()
					return bottomPosition() / animationOffset()
				end
				else nil,
		})
		if reduced then
			stableContainer.Parent = nil
			shadowWrapper.Parent = wrapper
			dialogNode.Parent = wrapper
		else
			shadowWrapper.Parent = stableContainer
			dialogNode.Parent = stableContainer
			stableContainer.Parent = wrapper
		end
		return wrapper
	end

	local function Backdrop(): GuiObject
		local backdrop = View({
			tag = "position-center-center anchor-center-center",
			Size = UDim2.fromScale(2, 2),
			stateLayer = {
				affordance = StateLayerAffordance.None,
			},
			onActivated = function()
				requestClose(OnCloseCallbackReason.BackdropClick :: OnCloseCallbackReason)
			end,
			backgroundStyle = function(): ColorStyleValue
				local style = variants().backdrop.backgroundStyle
				if reducedMotion() then
					return style
				end
				return {
					Color3 = style.Color3,
					Transparency = math.lerp(style.Transparency :: number, 1, backdropTransparency()),
				}
			end,
			ZIndex = 2,
			testId = `{props.testId}--backdrop`,
		})
		backdrop.Name = "Backdrop"
		return backdrop
	end

	local function Content(): GuiObject
		local function wrapperState(): WrapperState
			if reducedMotion() then
				return "reduced"
			end
			return if animating() then "animating" else "static"
		end
		local wrapper = rebuildOn(wrapperState, Wrapper)

		local content = View({
			ZIndex = elevation.zIndex,
			tag = "size-full padding-y-xlarge",
			testId = `{props.testId}--container`,
			children = {
				Vide.show(function()
					return Value.read(props.hasBackdrop) == true
				end, Backdrop),
				named("DialogContentWrapper", wrapper),
			},
		})
		--* React renders the content under its Fragment key "Main", or, with reduced motion, as the inner Dialog.
		Vide.effect(function()
			content.Name = if reducedMotion() then "Dialog" else "Main"
		end)
		return content
	end

	local function portalTarget(): GuiBase2d?
		return if Value.read(props.disablePortal) then nil else overlay()
	end

	Vide.show(portalTarget, function(target: () -> GuiBase2d)
		local content = Content()
		Vide.effect(function()
			content.Parent = target()
		end)
		Vide.cleanup(function()
			--* Rescues the dialog before the content goes, in case the in-place content has not taken it yet.
			for _, node in nodes do
				if node:IsDescendantOf(content) then
					node.Parent = nil
				end
			end
			content:Destroy()
		end)
		return content
	end)

	return Vide.show(function()
		return portalTarget() == nil
	end, Content)
end

--- A modal dialog: a surface with an optional close button, built from Dialog.Title, Dialog.Content, Dialog.Text,
--- Dialog.HeroMedia and Dialog.Actions. It slides and fades in when created, and out before `onClose` runs. Returns
--- the in-place content as a source, nil while it is in the overlay.
local function DialogContainer(dialogProps: DialogProps): () -> any
	local props: InternalProps = withDefaults(dialogProps, defaultProps) :: any
	local function size(): DialogSize
		return Value.read(props.size)
	end

	return DialogProvider({
		size = size,
		responsiveSize = Vide.untrack(size),
		testId = props.testId,
		children = function()
			return Dialog(props)
		end,
	})
end

return DialogContainer
