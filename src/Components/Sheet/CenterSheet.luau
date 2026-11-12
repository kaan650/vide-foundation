local Vide = require("../../Packages/Vide")

local CloseAffordance = require("../CloseAffordance")
local CloseAffordanceVariant = require("../../Enums/CloseAffordanceVariant")
local Constants = require("../../Constants")
local DIALOG_SIZES = require("../Dialog/useDialogVariants").DIALOG_SIZES
local DialogSize = require("../../Enums/DialogSize")
local ElevationLayer = require("../../Enums/ElevationLayer")
local ElevationProvider = require("../../Providers/Elevation/ElevationProvider")
local Image = require("../Image")
local Motion = require("../../Utility/Motion")
local SheetContext = require("./SheetContext")
local SheetType = require("./SheetType")
local SheetTypes = require("./Types")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local create = require("../../Utility/create")
local createSheetContextValue = require("./createSheetContextValue")
local rebuildOn = require("../../Utility/rebuildOn")
local useElevation = require("../../Providers/Elevation/useElevation")
local useOverlay = require("../../Providers/Overlay/useOverlay")
local usePreferences = require("../../Providers/Preferences/usePreferences")
local useTokens = require("../../Providers/Style/useTokens")
local withDefaults = require("../../Utility/withDefaults")

type DialogSize = DialogSize.DialogSize
type ColorStyleValue = Types.ColorStyleValue
type SheetProps = SheetTypes.SheetProps

export type CenterSheetProps = {
	-- Receives the sheet's close function, for Sheet's `sheetRef`.
	setClose: (close: () -> ()) -> (),
} & SheetProps

local HEIGHT = 600

local defaultProps = {
	size = DialogSize.Medium,
	testId = "--foundation-sheet",
}

local SHADOW_IMAGE = Constants.SHADOW_IMAGE
local SHADOW_SIZE = Constants.SHADOW_SIZE

local function noop() end

--- A sheet in the middle of the screen that rises and fades in, like a dialog.
local function CenterSheet(centerSheetProps: CenterSheetProps)
	local props = withDefaults(centerSheetProps, defaultProps)
	local testId: string = props.testId
	local overlay = useOverlay()
	local tokens = useTokens()
	local elevation = useElevation(ElevationLayer.Sheet, { stackAboveOwner = false })
	local preferences = usePreferences()

	local function reducedMotion(): boolean
		return preferences().reducedMotion == true
	end
	local function width(): number
		return DIALOG_SIZES[Value.read(props.size) :: DialogSize] * tokens().Config.UI.Scale
	end
	local function maxHeight(): number
		return HEIGHT * tokens().Config.UI.Scale
	end
	local function animationOffset(): number
		return tokens().Size.Size_800
	end
	local function centerSheetHeight(): number?
		return Value.read(props.centerSheetHeight)
	end

	local maxAvailableHeight = Vide.source(Vide.untrack(maxHeight))
	local function sheetContentHeight(): number?
		local value = maxAvailableHeight()
		local height = centerSheetHeight()
		if height then
			if height > 0 and height <= 1 then
				return value * height
			elseif height > 1 then
				return math.min(height, value)
			end
		end
		return nil
	end

	local animating = Vide.source(true)
	local closing = false
	local backdropTransparency, setBackdropTransparencyGoal = Motion.useAnimatedBinding(1, function()
		if closing then
			props.onClose()
		end
	end)
	local bottomPosition, setBottomPositionGoal = Motion.useAnimatedBinding(Vide.untrack(animationOffset), function()
		animating(false)
	end)

	local sheetHeight = Vide.source(0)

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

	local function closeSheet()
		if closing then
			return
		end
		local current = Vide.untrack(tokens)
		local offset = current.Size.Size_800
		if Vide.untrack(reducedMotion) then
			closing = true
			setBottomPositionGoal(Motion.instant(offset))
			setBackdropTransparencyGoal(Motion.instant(1))
		else
			setBottomPositionGoal(Motion.ease(offset, {
				easingStyle = current.Ease.StandardIn,
				duration = current.Time.Time_100,
			}))
			setBackdropTransparencyGoal(Motion.ease(1, {
				duration = current.Time.Time_100,
			}))
			animating(true)
			closing = true
		end
	end
	props.setClose(closeSheet)

	local context = createSheetContextValue(SheetType.Center, testId, closeSheet)
	context.sheetContentHeight = sheetContentHeight

	local function contentSize(): UDim2?
		if not centerSheetHeight() then
			return nil
		end
		local value = sheetContentHeight()
		return if value then UDim2.new(1, 0, 0, value) else nil
	end

	local function backdropStyle(): ColorStyleValue
		local backdrop = tokens().Color.Common.Backdrop
		return {
			Color3 = backdrop.Color3,
			Transparency = math.lerp(backdrop.Transparency, 1, backdropTransparency()),
		}
	end

	--* While animating, SheetContainer is a CanvasGroup; React remounts it as a Frame afterwards. The sheet lives in
	--* this Frame, moved between containers, so its content is not rebuilt (Foundation's stableContainer).
	local stableContainer = create("Frame")({
		Name = "Frame",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.XY,
	})
	Vide.cleanup(stableContainer)

	local function SheetNode(): GuiObject
		local content = View({
			tag = "col items-center size-full-0 auto-y clip",
			children = {
				Value.bindProperty("Size", contentSize),
				SheetContext(context, function()
					return ElevationProvider.ElevationOwnerScope({
						owner = elevation,
						children = function()
							return if props.children then props.children() else nil
						end,
					})
				end),
			},
		})
		content.Name = "Content"

		local closeAffordance = CloseAffordance({
			onActivated = closeSheet,
			NextSelectionDown = context.contentStartRef,
			variant = function()
				return if context.hasFullBleed()
					then CloseAffordanceVariant.OverMedia
					else CloseAffordanceVariant.Utility
			end,
			Position = function()
				local margin = tokens().Margin.Small
				return UDim2.new(1, -margin, 0, margin)
			end,
			AnchorPoint = Vector2.new(1, 0),
			Visible = function()
				return not context.hasHeader()
			end,
			testId = `{testId}--close-affordance`,
		}) :: GuiObject
		closeAffordance.Name = "CloseAffordance"
		context.setCloseAffordanceRef(closeAffordance)

		local sheet = View({
			ClipsDescendants = true,
			sizeConstraint = function()
				return if centerSheetHeight()
					then {
						MaxSize = Vector2.new(math.huge, maxAvailableHeight()),
					}
					else nil
			end,
			stateLayer = {
				affordance = StateLayerAffordance.None,
			},
			ZIndex = 2,
			--* Sinks presses so they do not reach the backdrop.
			onActivated = noop,
			onAbsoluteSizeChanged = function(rbx: GuiObject)
				sheetHeight(rbx.AbsoluteSize.Y)
			end,
			selection = SheetTypes.nonSelectable,
			selectionGroup = SheetTypes.isolatedSelectionGroup,
			tag = function()
				return {
					["bg-surface-100 stroke-default stroke-standard radius-large"] = true,
					["size-full-0 auto-y"] = centerSheetHeight() == nil,
				}
			end,
			testId = testId,
			children = {
				Value.bindProperty("Size", contentSize),
				content,
				closeAffordance,
			},
		})
		sheet.Name = "Sheet"
		if props.ref then
			props.ref(sheet)
		end
		return sheet
	end

	local shadow = Image({
		Image = SHADOW_IMAGE,
		Size = function()
			return UDim2.new(1, SHADOW_SIZE * 2, 0, sheetHeight() + SHADOW_SIZE * 2)
		end,
		Position = UDim2.new(0, -SHADOW_SIZE, 0.5, 0),
		ZIndex = 1,
		slice = {
			center = Rect.new(SHADOW_SIZE, SHADOW_SIZE, SHADOW_SIZE + 1, SHADOW_SIZE + 1),
			scale = 2,
		},
		imageStyle = function()
			return tokens().Color.Extended.Black.Black_10 :: ColorStyleValue
		end,
		tag = "anchor-center-left",
	})
	shadow.Name = "Shadow"

	local function SheetContainer(isAnimating: boolean): GuiObject
		local container = View({
			ZIndex = 2,
			sizeConstraint = {
				MaxSize = function()
					return Vector2.new(width(), maxHeight())
				end,
			},
			Position = function()
				return UDim2.new(0.5, 0, 0.5, bottomPosition())
			end,
			tag = "col align-y-center anchor-center-center size-full padding-medium",
			testId = `{testId}--center-sheet-container`,
			GroupTransparency = if isAnimating
				then function()
					return bottomPosition() / animationOffset()
				end
				else nil,
			onAbsoluteSizeChanged = function(rbx: GuiObject)
				local padding = Vide.untrack(tokens).Margin.Medium * 2
				maxAvailableHeight(math.min(rbx.AbsoluteSize.Y - padding, Vide.untrack(maxHeight)))
			end,
		})
		container.Name = "SheetContainer"
		stableContainer.Parent = container
		return container
	end

	local function Surface(): GuiObject
		local sheet = SheetNode()
		sheet.Parent = stableContainer
		shadow.Parent = stableContainer

		local backdrop = View({
			Size = UDim2.fromScale(2, 2),
			Position = UDim2.fromScale(-0.5, -0.5),
			ZIndex = 1,
			stateLayer = {
				affordance = StateLayerAffordance.None,
			},
			backgroundStyle = backdropStyle,
			onActivated = closeSheet,
			testId = `{testId}--backdrop`,
		})
		backdrop.Name = "Backdrop"

		local function isAnimating(): boolean
			return animating()
		end
		local surface = View({
			ZIndex = elevation.zIndex,
			tag = "size-full",
			testId = `{testId}--surface`,
			children = {
				rebuildOn(isAnimating, SheetContainer),
				backdrop,
			},
		})
		surface.Name = "OverlayPortal"
		Vide.cleanup(function()
			stableContainer.Parent = nil
			sheet:Destroy()
			surface:Destroy()
		end)
		return surface
	end

	Vide.show(overlay, function(target: () -> GuiBase2d)
		local surface = Surface()
		Vide.effect(function()
			surface.Parent = target()
		end)
		return surface
	end)
end

return CenterSheet
