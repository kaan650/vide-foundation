local Vide = require("../../../Packages/Vide")

local Constants = require("../../../Constants")
local ScrollView = require("../../ScrollView")
local SheetContext = require("../SheetContext")
local SheetType = require("../SheetType")
local StateLayerAffordance = require("../../../Enums/StateLayerAffordance")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local create = require("../../../Utility/create")
local devAssert = require("../../../Utility/devAssert")
local isScrollingFrameOverflowingY = require("../../../Utility/isScrollingFrameOverflowingY")
local named = require("../../../Utility/named")
local rebuildOn = require("../../../Utility/rebuildOn")
local useTokens = require("../../../Providers/Style/useTokens")

type Value<T> = Types.Value<T>

export type SheetContentProps = {
	isContentFullBleed: Value<boolean?>?,
	-- Anchors content to the bottom edge, like a chat log: content starts scrolled to the end and follows new content
	-- while scrolled to the end. In a bottom sheet with multiple snap points, lower snap points hide the top of the
	-- content instead of the bottom.
	isReversed: Value<boolean?>?,
	-- Receives the inner ScrollingFrame.
	scrollingFrameRef: ((frame: ScrollingFrame) -> ())?,
	-- Receives the content's ScrollView.
	ref: ((instance: GuiObject) -> ())?,
	children: Types.Children?,
} & Types.SelectionProps

local ZERO = UDim.new(0, 0)
local AT_END_TOLERANCE = 1

local function noop() end

local function getMaxCanvasPositionY(rbx: ScrollingFrame): number
	return math.max(0, rbx.AbsoluteCanvasSize.Y - rbx.AbsoluteWindowSize.Y)
end

--- The sheet's scrolling body. On bottom sheets it scrolls only once the sheet is at its highest snap point. Returns
--- a source when `isReversed` can put it in a clipping viewport (a bottom sheet with snap points).
local function SheetContent(props: SheetContentProps): GuiObject | () -> GuiObject
	local tokens = useTokens()
	local sheet = SheetContext()
	local testId = sheet.testId
	assert(testId, "SheetContent must be used within a Sheet")

	local hasOverflowY = Vide.source(false)
	local viewSizeY = Vide.source(0)
	local windowSizeY = Vide.source(0)
	local isAtEnd = true
	local sheetContentHeight = sheet.sheetContentHeight
	local isBottomSheet = sheet.sheetType == SheetType.Bottom
	local canReverse = type(props.isReversed) == "function" or props.isReversed == true

	local function isReversed(): boolean
		return Value.read(props.isReversed) == true
	end
	-- Nil unless reversed content sits in a bottom sheet with snap points.
	local function revealOffset(): number?
		return if isReversed() then sheet.contentRevealOffset() else nil
	end

	if canReverse then
		Vide.effect(function()
			devAssert(
				not (isReversed() and sheet.hasFullBleed()),
				"Sheet.Content with isReversed=true is unsupported when used with Sheet.FullBleed"
			)
		end)
		Vide.effect(function()
			if not isReversed() then
				return
			end
			Vide.untrack(function()
				sheet.setIsContentReversed(true)
			end)
			Vide.cleanup(function()
				sheet.setIsContentReversed(false)
			end)
		end)
	end

	local function updateScrollState(rbx: ScrollingFrame)
		local reversed = Vide.untrack(isReversed)
		if reversed and isAtEnd then
			rbx.CanvasPosition = Vector2.new(0, getMaxCanvasPositionY(rbx))
		end
		sheet.setInnerScrollY(rbx.CanvasPosition.Y)
		local isOverflowing = isScrollingFrameOverflowingY(rbx, 1)
		if reversed then
			windowSizeY(rbx.AbsoluteWindowSize.Y)
			sheet.setHasActionsDivider(getMaxCanvasPositionY(rbx) - rbx.CanvasPosition.Y > AT_END_TOLERANCE)
		else
			sheet.setHasActionsDivider(isOverflowing)
		end
		hasOverflowY(isOverflowing)
	end

	local function horizontalPadding(): UDim?
		return if Value.read(props.isContentFullBleed) then nil else UDim.new(0, tokens().Padding.Small)
	end

	--* An interaction sink over the content during vertical drags, so they do not press what is under the finger.
	local interactionSinkContainer = create("Folder")({
		Name = "ContentInteractionSinkContainer",
		Vide.show(sheet.isVerticalSheetGesture, function()
			local sink = View({
				Size = UDim2.fromScale(1, 1),
				selection = {
					Selectable = false,
				},
				ZIndex = 2,
				testId = `{testId}--content--interaction-sink`,
				stateLayer = {
					affordance = StateLayerAffordance.None,
				},
				onActivated = noop,
			})
			sink.Name = "ContentInteractionSink"
			return sink
		end),
	})

	local view = View({
		onAbsoluteSizeChanged = function(rbx: GuiObject)
			viewSizeY(rbx.AbsoluteSize.Y)
		end,
		tag = function()
			return {
				["col align-x-center gap-medium size-full-0 auto-y"] = true,
				["padding-x-medium"] = not Value.read(props.isContentFullBleed),
				["align-y-bottom"] = isReversed(),
			}
		end,
		children = {
			if canReverse
				then Value.bindProperty("Position", function(): UDim2?
					local offset = revealOffset()
					return if offset then UDim2.fromOffset(0, offset) else nil
				end)
				else nil,
			if canReverse
				then Value.bindProperty("Size", function(): UDim2?
					if not isReversed() then
						return nil
					end
					return UDim2.new(1, 0, 0, math.max(0, windowSizeY() - (revealOffset() or 0)))
				end)
				else nil,
			Vide.show(sheet.hasFullBleed, function()
				local spacer = View({
					Size = function()
						return UDim2.new(1, 0, 0, math.max(0, sheet.fullBleedHeight()))
					end,
					LayoutOrder = Constants.MIN_LAYOUT_ORDER,
					testId = `{testId}--content--full-bleed-spacer`,
				})
				spacer.Name = "FullBleedSpacer"
				return spacer
			end),
			props.children,
			interactionSinkContainer,
		},
	})
	view.Name = "ScrollingFrame"

	local function build(hasViewport: boolean): GuiObject
		local scrollView = ScrollView({
			scrollingFrameRef = function(frame: ScrollingFrame)
				sheet.setInnerScrollingFrame(frame)
				if props.scrollingFrameRef then
					props.scrollingFrameRef(frame)
				end
			end,
			ZIndex = 1,
			selection = {
				Selectable = function()
					return Value.read(props.Selectable) ~= false and hasOverflowY()
				end,
				NextSelectionUp = props.NextSelectionUp,
				NextSelectionDown = props.NextSelectionDown,
				NextSelectionLeft = props.NextSelectionLeft,
				NextSelectionRight = props.NextSelectionRight,
			},
			scroll = {
				ScrollingEnabled = sheet.innerScrollingEnabled,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = if sheetContentHeight
					then function()
						return UDim2.new(1, 0, 0, viewSizeY())
					end
					else UDim2.fromScale(1, 0),
				ScrollingDirection = Enum.ScrollingDirection.Y,
			},
			Size = if sheetContentHeight then UDim2.fromScale(1, 1) else nil,
			Position = if hasViewport
				then function()
					return UDim2.fromOffset(0, -(revealOffset() or 0))
				end
				else nil,
			padding = {
				top = function()
					if sheet.hasHeader() or sheet.hasFullBleed() then
						return ZERO
					end
					local current = tokens()
					return UDim.new(0, if isBottomSheet then current.Padding.Small else current.Margin.Small)
				end,
				bottom = function()
					local current = tokens()
					return if isBottomSheet
						then UDim.new(0, sheet.actionsHeight() + sheet.bottomPadding + current.Margin.Small)
						else UDim.new(0, current.Padding.Small)
				end,
				left = function()
					return horizontalPadding() or ZERO
				end,
				right = function()
					return horizontalPadding() or ZERO
				end,
			},
			ClipsDescendants = if isBottomSheet then sheet.hasHeader else true,
			onCanvasPositionChanged = function(rbx: ScrollingFrame)
				if Vide.untrack(isReversed) then
					isAtEnd = getMaxCanvasPositionY(rbx) - rbx.CanvasPosition.Y <= AT_END_TOLERANCE
					sheet.setHasActionsDivider(not isAtEnd)
				end
				sheet.setInnerScrollY(rbx.CanvasPosition.Y)
			end,
			onAbsoluteCanvasSizeChanged = updateScrollState,
			onAbsoluteWindowSizeChanged = updateScrollState,
			testId = `{testId}--content`,
			tag = if hasViewport then "size-full" else "fill size-full-0 auto-y",
			children = view,
		})
		if props.ref then
			props.ref(scrollView)
		end

		if not hasViewport then
			return scrollView
		end
		return View({
			ClipsDescendants = true,
			ZIndex = 1,
			tag = "fill size-full-0",
			testId = `{testId}--content--viewport`,
			children = named("ScrollView", scrollView),
		})
	end

	if not (canReverse and isBottomSheet) then
		return build(false)
	end
	--* React remounts the content when the viewport comes or goes; the children move to the new ScrollView.
	return rebuildOn(function(): boolean
		return revealOffset() ~= nil
	end, function(hasViewport: boolean): GuiObject
		local root = build(hasViewport)
		Vide.cleanup(function()
			view.Parent = nil
			root:Destroy()
		end)
		return root
	end)
end

return SheetContent
