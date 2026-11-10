local Vide = require("../../Packages/Vide")

local Constants = require("../../Constants")
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
local Wrappers = require("../../Utility/Wrappers")
local create = require("../../Utility/create")
local createSheetContextValue = require("./createSheetContextValue")
local useElevation = require("../../Providers/Elevation/useElevation")
local useHardwareInsets = require("./useHardwareInsets")
local useOverlay = require("../../Providers/Overlay/useOverlay")
local usePreferences = require("../../Providers/Preferences/usePreferences")
local useScreenHeight = require("./useScreenHeight")
local useTokens = require("../../Providers/Style/useTokens")
local withDefaults = require("../../Utility/withDefaults")

local RunService = Wrappers.Services.RunService
local UserInputService = Wrappers.Services.UserInputService

type ColorStyleValue = Types.ColorStyleValue
type SheetProps = SheetTypes.SheetProps

export type BottomSheetProps = {
	-- Receives the sheet's close function, for Sheet's `sheetRef`.
	setClose: (close: () -> ()) -> (),
} & SheetProps

local SPRING_FREQUENCY_HZ = 4
local SPRING_OMEGA = 2 * math.pi * SPRING_FREQUENCY_HZ
local VELOCITY_THRESHOLD = 1
local POSITION_THRESHOLD = 0.5
local SCROLL_AT_MAX_TOLERANCE = 1e-2
local ENGINE_INERTIA_FRICTION = 2.35
local BOTTOM_PADDING = 200

local defaultProps = {
	defaultSnapPointIndex = 1,
	testId = "--foundation-sheet",
}

local SHADOW_IMAGE = Constants.SHADOW_IMAGE
local SHADOW_SIZE = Constants.SHADOW_SIZE

local function noop() end

--- Closed form of a critically damped spring (fastest return without overshoot), so the step is frame-rate
--- independent.
local function advanceCriticalDampedSpring(
	position: number,
	velocity: number,
	target: number,
	delta: number
): (number, number)
	local displacement = position - target
	local normalizedTime = SPRING_OMEGA * delta
	local decay = math.exp(-normalizedTime)
	local springTerm = velocity + SPRING_OMEGA * displacement

	local newDisplacement = (displacement + springTerm * delta) * decay
	local newVelocity = (velocity - springTerm * normalizedTime) * decay

	return target + newDisplacement, newVelocity
end

--- A sheet that rises from the bottom of the screen and rests on snap points. The sheet is the canvas of a
--- full-screen ScrollingFrame: dragging scrolls it, and a spring settles it on the nearest snap point.
local function BottomSheet(bottomSheetProps: BottomSheetProps)
	local props = withDefaults(bottomSheetProps, defaultProps)
	local testId: string = props.testId
	local overlay = useOverlay()
	local tokens = useTokens()
	local elevation = useElevation(ElevationLayer.Sheet, { stackAboveOwner = false })
	local preferences = usePreferences()

	local function reducedMotion(): boolean
		return preferences().reducedMotion == true
	end
	local function defaultSnapPointIndex(): number
		return Value.read(props.defaultSnapPointIndex) :: number
	end
	local function snapPointsProp(): { number }?
		return Value.read(props.snapPoints)
	end

	local screenHeight = useScreenHeight()
	local overlayAvailableHeight = Vide.source(Vide.untrack(function(): number
		local current = overlay()
		return if current then current.AbsoluteSize.Y else 0
	end))
	local sheetHeight = Vide.source(0)
	local snapPoints = Vide.derive(function(): { number }
		return snapPointsProp() or { sheetHeight() }
	end)

	local function snapValueToPixels(value: number): number
		if value > 1 then
			return value
		end
		return value * screenHeight()
	end

	local maxSheetHeight = Vide.derive(function(): number
		local height = 0
		for _, snap in snapPoints() do
			local pixels = snapValueToPixels(snap)
			if pixels > height then
				height = pixels
			end
		end
		height = math.min(height, screenHeight())
		local available = overlayAvailableHeight()
		if available > 0 then
			height = math.min(height, available)
		end
		return height
	end)

	local hardwareInsets = useHardwareInsets(overlay)
	local safeAreaPadding = Vide.derive(function(): number
		return hardwareInsets().bottom
	end)

	local currentSnapIndex = 0
	local isClosing = false

	local backdropTransparency, setBackdropTransparencyGoal = Motion.useAnimatedBinding(1, function()
		if isClosing then
			props.onClose()
		end
	end)
	local sheetHeightAvailable = Vide.source(-Vide.untrack(safeAreaPadding))
	local actionsHeight = Vide.source(0)
	local innerScrollingEnabled = Vide.source(false)
	local isVerticalSheetGesture = Vide.source(false)

	local outerScrollY = 0
	local outerScrollingFrame: ScrollingFrame? = nil
	local innerScrollingFrame: ScrollingFrame? = nil

	local inputActive = false
	local scrollVelocity = 0
	local springConnection: RBXScriptConnection? = nil
	local springActive = false
	local springVelocity = 0

	local function setIsVerticalSheetGesture(value: boolean)
		if Vide.untrack(isVerticalSheetGesture) ~= value then
			isVerticalSheetGesture(value)
		end
	end

	local function stopSpringSimulation()
		if springConnection then
			springConnection:Disconnect()
			springConnection = nil
		end
		scrollVelocity = 0
		springActive = false
	end
	Vide.cleanup(stopSpringSimulation)

	local function startSpringSimulation(targetPosition: number)
		stopSpringSimulation()
		springActive = true

		if outerScrollingFrame then
			outerScrollingFrame:ResetScrollVelocity()
		end

		springConnection = RunService.Heartbeat:Connect(function(delta: number)
			local frame = outerScrollingFrame
			if not frame or not springActive then
				stopSpringSimulation()
				return
			end

			local newCanvasY, newVelocity =
				advanceCriticalDampedSpring(frame.CanvasPosition.Y, springVelocity, targetPosition, delta)

			springVelocity = newVelocity
			frame.CanvasPosition = Vector2.new(0, newCanvasY)
			local displacement = targetPosition - frame.CanvasPosition.Y

			if math.abs(displacement) < POSITION_THRESHOLD and math.abs(springVelocity) < VELOCITY_THRESHOLD then
				frame.CanvasPosition = Vector2.new(0, targetPosition)
				stopSpringSimulation()
			end
		end)
	end

	local function snapValueToPosition(value: number): number
		return math.min(snapValueToPixels(value), maxSheetHeight()) + safeAreaPadding()
	end

	local function notifySnapPointChanged(index: number)
		local onSnapPointChanged = props.onSnapPointChanged
		if onSnapPointChanged then
			onSnapPointChanged(Vide.untrack(snapPoints)[index], index)
		end
	end

	local function springToSnapIndex(index: number)
		currentSnapIndex = index
		startSpringSimulation(Vide.untrack(function()
			return snapValueToPosition(snapPoints()[index])
		end))
		notifySnapPointChanged(index)
	end

	local function jumpToSnapIndex(index: number)
		stopSpringSimulation()
		currentSnapIndex = index
		if outerScrollingFrame then
			outerScrollingFrame.CanvasPosition = Vector2.new(0, Vide.untrack(function()
				return snapValueToPosition(snapPoints()[index])
			end))
		end
		notifySnapPointChanged(index)
	end

	local function closeSheet(forceAnimate: boolean?)
		if isClosing then
			return
		end
		if Vide.untrack(reducedMotion) and not forceAnimate then
			isClosing = true
			stopSpringSimulation()
			if outerScrollingFrame then
				outerScrollingFrame.CanvasPosition = Vector2.new(0, 0)
			end
			setBackdropTransparencyGoal(Motion.instant(1))
		else
			springVelocity = -scrollVelocity
			startSpringSimulation(0)
			setBackdropTransparencyGoal(Motion.ease(1, {
				duration = Vide.untrack(tokens).Time.Time_100,
			}))
			isClosing = true
		end
	end
	props.setClose(function()
		closeSheet()
	end)

	local function isOuterScrollAtMax(): boolean
		local target = math.floor(Vide.untrack(maxSheetHeight) + Vide.untrack(safeAreaPadding))
		return outerScrollY >= target - SCROLL_AT_MAX_TOLERANCE
	end

	local innerScrollY = Vide.source(0)

	local function updateInnerScrolling()
		local isAtTopOfInnerScroll = Vide.untrack(innerScrollY) <= 0
		local isAtMaxOfOuterScroll = isOuterScrollAtMax()
		local isCollapsing = not isAtMaxOfOuterScroll and scrollVelocity < 0

		if isCollapsing or (scrollVelocity > 0 and isAtTopOfInnerScroll and inputActive) then
			innerScrollingEnabled(false)
		elseif scrollVelocity <= 0 and isAtMaxOfOuterScroll then
			innerScrollingEnabled(true)
		end
	end

	local function snapToClosestSwipeSnapPoint()
		local velocity = scrollVelocity
		local finalPosition = outerScrollY - velocity / ENGINE_INERTIA_FRICTION

		type Snap = { index: number, position: number }
		local snaps: { Snap } = { { index = 0, position = 0 } }
		Vide.untrack(function()
			for index, snap in snapPoints() do
				table.insert(snaps, { index = index, position = snapValueToPosition(snap) })
			end
		end)
		table.sort(snaps, function(a: Snap, b: Snap)
			return math.abs(a.position - finalPosition) < math.abs(b.position - finalPosition)
		end)
		local target = snaps[1]

		if not inputActive then
			springVelocity = -velocity
			if target.index == 0 then
				closeSheet(true)
			else
				springToSnapIndex(target.index)
			end
		end
	end

	Vide.effect(function()
		local current = overlay()
		if not current then
			return
		end
		Vide.untrack(function()
			overlayAvailableHeight(current.AbsoluteSize.Y)
		end)
		Vide.cleanup(current:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			overlayAvailableHeight(current.AbsoluteSize.Y)
		end))
	end)

	--! Any input (a key press too) counts as a gesture start and stops the spring, as in Foundation.
	Vide.cleanup(UserInputService.TouchPan:Connect(function(_, totalTranslation: Vector2?, velocity: Vector2)
		scrollVelocity = velocity.Y
		if inputActive and totalTranslation then
			if math.abs(totalTranslation.Y) > math.abs(totalTranslation.X) then
				setIsVerticalSheetGesture(true)
			end
		end
		updateInnerScrolling()
	end))
	Vide.cleanup(UserInputService.InputBegan:Connect(function()
		inputActive = true
		scrollVelocity = 0
		setIsVerticalSheetGesture(false)
		stopSpringSimulation()
	end))
	Vide.cleanup(UserInputService.InputEnded:Connect(function()
		if not inputActive then
			return
		end

		inputActive = false
		setIsVerticalSheetGesture(false)
		scrollVelocity = if outerScrollingFrame then outerScrollingFrame:GetScrollVelocity().Y else 0

		--* Outer scrolling at its maximum hands the gesture to the inner content.
		if isOuterScrollAtMax() or isClosing then
			innerScrollingEnabled(true)
			return
		end

		snapToClosestSwipeSnapPoint()
	end))
	Vide.cleanup(function()
		setIsVerticalSheetGesture(false)
	end)

	local innerSurface = Vide.source(nil :: GuiObject?)
	local getInnerSurface: () -> GuiObject? = innerSurface :: any

	local context = createSheetContextValue(SheetType.Bottom, testId, function()
		closeSheet()
	end)
	context.sheetHeightAvailable = function()
		return sheetHeightAvailable()
	end
	context.actionsHeight = function()
		return actionsHeight()
	end
	context.setActionsHeight = function(value: number)
		actionsHeight(value)
	end
	context.safeAreaPadding = function()
		return safeAreaPadding()
	end
	context.bottomPadding = BOTTOM_PADDING
	context.innerScrollingEnabled = function()
		return innerScrollingEnabled()
	end
	context.innerScrollY = function()
		return innerScrollY()
	end
	context.setInnerScrollY = function(value: number)
		innerScrollY(value)
		updateInnerScrolling()
	end
	context.setInnerScrollingFrame = function(frame: ScrollingFrame?)
		innerScrollingFrame = frame
	end
	context.innerSurface = getInnerSurface
	context.isVerticalSheetGesture = function()
		return isVerticalSheetGesture()
	end

	local function onGripperActivated()
		--* Cancels the input-ended snap for this press.
		inputActive = false
		if innerScrollingFrame then
			innerScrollY(0)
			innerScrollingFrame.CanvasPosition = Vector2.new(0, 0)
			innerScrollingFrame:ResetScrollVelocity()
		end
		local points = Vide.untrack(snapPoints)
		if #points > 1 then
			local nextIndex = currentSnapIndex % #points + 1
			if Vide.untrack(reducedMotion) then
				jumpToSnapIndex(nextIndex)
			else
				springToSnapIndex(nextIndex)
			end
			innerScrollingEnabled(Vide.untrack(function()
				return snapValueToPixels(points[nextIndex]) >= maxSheetHeight()
			end))
		else
			closeSheet()
		end
	end

	local function Gripper(): GuiObject
		local touchTarget = View({
			tag = "size-1000-600",
			stateLayer = {
				affordance = StateLayerAffordance.None,
			},
			onActivated = onGripperActivated,
		})
		touchTarget.Name = "TouchTarget"

		local gripper = View({
			ZIndex = 5,
			backgroundStyle = function()
				return tokens().Color.Content.Muted :: ColorStyleValue
			end,
			Position = function()
				local current = tokens()
				return UDim2.new(
					0.5,
					0,
					0,
					if context.hasFullBleed() then current.Padding.Small else -current.Padding.XSmall
				)
			end,
			AnchorPoint = Vector2.new(0.5, 0),
			tag = "align-y-center size-1000-100 padding-y-small radius-small",
			testId = `{testId}--gripper`,
			children = touchTarget,
		})
		gripper.Name = "Gripper"
		return gripper
	end

	local function Surface(): GuiObject
		local gripperContainer = create("Folder")({
			Name = "GripperContainer",
			Gripper(),
		})

		local sheet = View({
			Size = function()
				return if snapPointsProp() == nil
					then UDim2.fromScale(1, 0)
					else UDim2.new(1, 0, 0, maxSheetHeight() + BOTTOM_PADDING)
			end,
			stateLayer = {
				affordance = StateLayerAffordance.None,
			},
			--* Sinks presses so they do not reach the backdrop.
			onActivated = noop,
			onAbsoluteSizeChanged = function(rbx: GuiObject)
				if Vide.untrack(snapPointsProp) == nil then
					sheetHeight(rbx.AbsoluteSize.Y - BOTTOM_PADDING)
				end
			end,
			testId = testId,
			tag = function()
				return {
					["col items-center radius-large clip bg-surface-100"] = true,
					["padding-top-medium"] = not context.hasFullBleed(),
				}
			end,
			children = {
				Value.bindProperty("AutomaticSize", function()
					return if snapPointsProp() == nil then Enum.AutomaticSize.Y else nil
				end),
				gripperContainer,
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
		sheet.Name = "Sheet"

		local sheetContainer = View({
			Size = function()
				return UDim2.new(1, 0, 1, BOTTOM_PADDING - maxSheetHeight() - safeAreaPadding())
			end,
			Position = function()
				return UDim2.new(0, 0, 1, -maxSheetHeight())
			end,
			ZIndex = 3,
			children = sheet,
		})
		sheetContainer.Name = "SheetContainer"

		local shadow = Image({
			Image = SHADOW_IMAGE,
			Size = function()
				return UDim2.new(1, SHADOW_SIZE * 2, 0, maxSheetHeight() + BOTTOM_PADDING + SHADOW_SIZE * 2)
			end,
			Position = function()
				return UDim2.new(-SHADOW_SIZE, 0, 1, -maxSheetHeight() - SHADOW_SIZE)
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
			Size = UDim2.fromScale(1, 2),
			Position = UDim2.fromScale(0, -0.5),
			ZIndex = 1,
			stateLayer = {
				affordance = StateLayerAffordance.None,
			},
			backgroundStyle = function(): ColorStyleValue
				local style = tokens().Color.Common.Backdrop
				return {
					Color3 = style.Color3,
					Transparency = math.lerp(style.Transparency, 1, backdropTransparency()),
				}
			end,
			onActivated = function()
				closeSheet()
			end,
			testId = `{testId}--backdrop`,
		})
		backdrop.Name = "Backdrop"

		local scrollingFrame = create("ScrollingFrame")({
			Name = "Children",
			Size = UDim2.fromScale(1, 1),
			CanvasSize = function()
				return UDim2.new(1, 0, 1, maxSheetHeight() + safeAreaPadding())
			end,
			ClipsDescendants = false,
			BackgroundTransparency = 1,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 0,
			sheetContainer,
			shadow,
			backdrop,
		}) :: ScrollingFrame
		outerScrollingFrame = scrollingFrame
		Vide.cleanup(function()
			if outerScrollingFrame == scrollingFrame then
				outerScrollingFrame = nil
			end
		end)
		Vide.cleanup(scrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			outerScrollY = scrollingFrame.CanvasPosition.Y
			sheetHeightAvailable(outerScrollY - Vide.untrack(safeAreaPadding) - Vide.untrack(tokens).Margin.Small)
			updateInnerScrolling()
			if outerScrollY <= 0 then
				closeSheet()
			end
		end))

		local surface = View({
			ZIndex = elevation.zIndex,
			selection = SheetTypes.nonSelectable,
			selectionGroup = SheetTypes.isolatedSelectionGroup,
			tag = "size-full",
			testId = `{testId}--surface`,
			children = scrollingFrame,
		})
		surface.Name = "Sheet"
		innerSurface(surface)
		if props.ref then
			props.ref(surface)
		end
		--* Unparented, not destroyed: Sheet.Actions lives in the surface and moves to the next one.
		Vide.cleanup(function()
			surface.Parent = nil
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

	--* After the surface exists, as React runs it after mount. Reruns whenever a snap position can move, snapping
	--* back to the default point, as Foundation's effect does.
	Vide.effect(function()
		local current = overlay()
		local points = snapPoints()
		local index = defaultSnapPointIndex()
		local reduced = reducedMotion()
		screenHeight()
		maxSheetHeight()
		safeAreaPadding()
		if current then
			Vide.untrack(function()
				if reduced then
					jumpToSnapIndex(index)
					setBackdropTransparencyGoal(Motion.instant(0))
				else
					springToSnapIndex(index)
					setBackdropTransparencyGoal(Motion.ease(0, {
						duration = tokens().Time.Time_100,
					}))
				end
				innerScrollingEnabled(snapValueToPixels(points[index]) >= maxSheetHeight())
			end)
		end
		Vide.cleanup(stopSpringSimulation)
	end)
end

return BottomSheet
