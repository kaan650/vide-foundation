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
local isScrollingFrameOverflowingY = require("../../../Utility/isScrollingFrameOverflowingY")
local useTokens = require("../../../Providers/Style/useTokens")

type Value<T> = Types.Value<T>

export type SheetContentProps = {
	isContentFullBleed: Value<boolean?>?,
	-- Receives the inner ScrollingFrame.
	scrollingFrameRef: ((frame: ScrollingFrame) -> ())?,
	-- Receives the content's root instance.
	ref: ((instance: GuiObject) -> ())?,
	children: Types.Children?,
} & Types.SelectionProps

local ZERO = UDim.new(0, 0)

local function noop() end

--- The sheet's scrolling body. On bottom sheets it scrolls only once the sheet is at its highest snap point.
local function SheetContent(props: SheetContentProps): GuiObject
	local tokens = useTokens()
	local sheet = SheetContext()
	local testId = sheet.testId
	assert(testId, "SheetContent must be used within a Sheet")

	local hasOverflowY = Vide.source(false)
	local viewSizeY = Vide.source(0)
	local sheetContentHeight = sheet.sheetContentHeight
	local isBottomSheet = sheet.sheetType == SheetType.Bottom

	local function updateScrollState(rbx: ScrollingFrame)
		sheet.setInnerScrollY(rbx.CanvasPosition.Y)
		local isOverflowing = isScrollingFrameOverflowingY(rbx, 1)
		sheet.setHasActionsDivider(isOverflowing)
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
			}
		end,
		children = {
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

	local content = ScrollView({
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
			sheet.setInnerScrollY(rbx.CanvasPosition.Y)
		end,
		onAbsoluteCanvasSizeChanged = updateScrollState,
		onAbsoluteWindowSizeChanged = updateScrollState,
		testId = `{testId}--content`,
		tag = "fill size-full-0 auto-y",
		children = view,
	})
	if props.ref then
		props.ref(content)
	end
	return content
end

return SheetContent
