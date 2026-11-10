local Vide = require("../../Packages/Vide")

local CloseAffordance = require("../CloseAffordance")
local CloseAffordanceVariant = require("../../Enums/CloseAffordanceVariant")
local Constants = require("../../Constants")
local DialogSize = require("../../Enums/DialogSize")
local ElevationLayer = require("../../Enums/ElevationLayer")
local ElevationProvider = require("../../Providers/Elevation/ElevationProvider")
local Image = require("../Image")
local Motion = require("../../Utility/Motion")
local Padding = require("../Padding")
local SheetContext = require("./SheetContext")
local SheetType = require("./SheetType")
local SheetTypes = require("./Types")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local createSheetContextValue = require("./createSheetContextValue")
local useElevation = require("../../Providers/Elevation/useElevation")
local useHardwareInsets = require("./useHardwareInsets")
local useOverlay = require("../../Providers/Overlay/useOverlay")
local usePreferences = require("../../Providers/Preferences/usePreferences")
local useScreenSize = require("./useScreenSize")
local useTokens = require("../../Providers/Style/useTokens")
local withDefaults = require("../../Utility/withDefaults")

type DialogSize = DialogSize.DialogSize
type ColorStyleValue = Types.ColorStyleValue
type SheetProps = SheetTypes.SheetProps

export type SideSheetProps = {
	displaySize: () -> Enum.DisplaySize,
	-- Receives the sheet's close function, for Sheet's `sheetRef`.
	setClose: (close: () -> ()) -> (),
} & SheetProps

local SIDE_SHEET_WIDTHS: { [DialogSize]: { TARGET_WIDTH: number, MIN: number, MAX: number } } = {
	[DialogSize.Medium] = {
		TARGET_WIDTH = 0.40,
		MIN = 360,
		MAX = 440,
	},
	[DialogSize.Large] = {
		TARGET_WIDTH = 0.5,
		MIN = 440,
		MAX = 640,
	},
}

local defaultProps = {
	testId = "--foundation-sheet",
	size = DialogSize.Medium,
}

local SHADOW_IMAGE = Constants.SHADOW_IMAGE
local SHADOW_SIZE = Constants.SHADOW_SIZE

local function noop() end

--- A sheet that slides in from the right edge, full height.
local function SideSheet(sideSheetProps: SideSheetProps)
	local props = withDefaults(sideSheetProps, defaultProps)
	local testId: string = props.testId
	local overlay = useOverlay()
	local tokens = useTokens()
	local elevation = useElevation(ElevationLayer.Sheet, { stackAboveOwner = false })
	local preferences = usePreferences()

	local hardwareInsets = useHardwareInsets(overlay)
	local screenSize = useScreenSize()

	local function reducedMotion(): boolean
		return preferences().reducedMotion == true
	end
	local function safeAreaPadding(): number
		return hardwareInsets().right
	end
	local function isSmallDisplay(): boolean
		return props.displaySize() == Enum.DisplaySize.Small
	end
	local function width(): number
		local spec = SIDE_SHEET_WIDTHS[Value.read(props.size) :: DialogSize]
		local scale = tokens().Config.UI.Scale
		return math.clamp(screenSize().X * spec.TARGET_WIDTH, spec.MIN * scale, spec.MAX * scale)
	end
	local function sheetPadding(): number
		return tokens().Padding.Medium
	end
	local function closedPosition(): number
		return -(safeAreaPadding() + if isSmallDisplay() then 0 else sheetPadding())
	end

	local closing = false
	local backdropTransparency, setBackdropTransparencyGoal = Motion.useAnimatedBinding(1, function()
		if closing then
			props.onClose()
		end
	end)
	local rightPosition, setRightPositionGoal = Motion.useAnimatedBinding(Vide.untrack(closedPosition))

	Vide.effect(function()
		local target = width()
		local reduced = reducedMotion()
		Vide.untrack(function()
			local current = tokens()
			if reduced then
				setRightPositionGoal(Motion.instant(target))
				setBackdropTransparencyGoal(Motion.instant(0))
			else
				setRightPositionGoal(Motion.ease(target, {
					easingStyle = current.Ease.StandardOut,
					duration = current.Time.Time_300,
				}))
				setBackdropTransparencyGoal(Motion.ease(0, {
					duration = current.Time.Time_100,
				}))
			end
		end)
	end)

	local function closeSheet()
		if closing then
			return
		end
		local target = Vide.untrack(closedPosition)
		local current = Vide.untrack(tokens)
		if Vide.untrack(reducedMotion) then
			closing = true
			setRightPositionGoal(Motion.instant(target))
			setBackdropTransparencyGoal(Motion.instant(1))
		else
			setRightPositionGoal(Motion.ease(target, {
				easingStyle = current.Ease.StandardIn,
				duration = current.Time.Time_100,
			}))
			setBackdropTransparencyGoal(Motion.ease(1, {
				duration = current.Time.Time_100,
			}))
			closing = true
		end
	end
	props.setClose(closeSheet)

	local function sheetSize(): UDim2
		local small = isSmallDisplay()
		return UDim2.new(
			0,
			width() + if small then safeAreaPadding() else 0,
			1,
			if small then 0 else -sheetPadding() * 2
		)
	end
	local function sheetPosition(): UDim2
		local small = isSmallDisplay()
		local value = rightPosition()
		return UDim2.new(1, if small then -value else -(value + sheetPadding()), 0, if small then 0 else sheetPadding())
	end

	local context = createSheetContextValue(SheetType.Side, testId, closeSheet)
	context.hasRadius = function()
		return not isSmallDisplay()
	end

	local function backdropStyle(): ColorStyleValue
		local backdrop = tokens().Color.Common.Backdrop
		return {
			Color3 = backdrop.Color3,
			Transparency = math.lerp(backdrop.Transparency, 1, backdropTransparency()),
		}
	end

	local function Surface(): GuiObject
		local content = View({
			tag = "col items-center size-full-full clip",
			children = SheetContext(context, function()
				return ElevationProvider.ElevationOwnerScope({
					owner = elevation,
					children = function()
						return if props.children then props.children() else nil
					end,
				})
			end),
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
			Size = sheetSize,
			Position = sheetPosition,
			ClipsDescendants = true,
			ZIndex = 3,
			stateLayer = {
				affordance = StateLayerAffordance.None,
			},
			--* Sinks presses so they do not reach the backdrop.
			onActivated = noop,
			selection = SheetTypes.nonSelectable,
			selectionGroup = SheetTypes.isolatedSelectionGroup,
			tag = function()
				return {
					["stroke-standard stroke-default bg-surface-100"] = true,
					["radius-large"] = not isSmallDisplay(),
				}
			end,
			testId = testId,
			children = {
				content,
				closeAffordance,
				Vide.show(function()
					return isSmallDisplay() and safeAreaPadding() > 0
				end, function()
					local padding = Padding({
						value = {
							right = function()
								return UDim.new(0, safeAreaPadding())
							end,
						},
						testId = `{testId}--padding`,
					})
					padding.Name = "Padding"
					return padding
				end),
			},
		})
		sheet.Name = "Sheet"
		if props.ref then
			props.ref(sheet)
		end

		local shadow = Image({
			Image = SHADOW_IMAGE,
			Size = function()
				return sheetSize() + UDim2.fromOffset(SHADOW_SIZE * 2, SHADOW_SIZE * 2)
			end,
			Position = function()
				return sheetPosition() + UDim2.fromOffset(-SHADOW_SIZE, -SHADOW_SIZE)
			end,
			ZIndex = 2,
			slice = {
				center = Rect.new(SHADOW_SIZE, SHADOW_SIZE, SHADOW_SIZE + 1, SHADOW_SIZE + 1),
				scale = 2,
			},
			imageStyle = function()
				return tokens().Color.Extended.Black.Black_10 :: ColorStyleValue
			end,
		})
		shadow.Name = "Shadow"

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

		local surface = View({
			ZIndex = elevation.zIndex,
			tag = "size-full",
			testId = `{testId}--surface`,
			children = { sheet, shadow, backdrop },
		})
		surface.Name = "Sheet"
		return surface
	end

	Vide.show(overlay, function(target: () -> GuiBase2d)
		local surface = Surface()
		Vide.effect(function()
			surface.Parent = target()
		end)
		Vide.cleanup(surface)
		return surface
	end)
end

return SideSheet
