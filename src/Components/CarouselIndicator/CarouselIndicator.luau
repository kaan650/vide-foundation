local Vide = require("../../Packages/Vide")

local Dot = require("./Dot")
local Motion = require("../../Utility/Motion")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local getCarouselIndicatorDotsConfig = require("./getCarouselIndicatorDotsConfig")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type CarouselIndicatorDot = getCarouselIndicatorDotsConfig.CarouselIndicatorDot
type CarouselIndicatorDotsConfig = getCarouselIndicatorDotsConfig.CarouselIndicatorDotsConfig
type EaseOptions = Motion.EaseOptions
type Value<T> = Types.Value<T>

export type CarouselIndicatorProps = {
	page: Value<number>?,
	count: Value<number>?,
	onActivated: ((page: number) -> ())?,
	-- Receives the first dot that can take selection (nil when none), to move gamepad focus into the indicator.
	selectableDotRef: ((dot: GuiObject?) -> ())?,
} & Types.SelectionProps & Types.CommonProps

type DotEntry = {
	index: number,
	dot: CarouselIndicatorDot,
	previousSelectablePage: number?,
	nextSelectablePage: number?,
}

local MAX_VISIBLE_COUNT = 5

local defaultProps = {
	page = 1,
	count = 5,
	testId = "--foundation-carousel-indicator",
}

local function getDotCenter(dots: { CarouselIndicatorDot }, index: number, gap: number): number
	local contentWidth = math.max(#dots - 1, 0) * gap
	local center = 0

	for dotIndex, dot in dots do
		contentWidth += dot.size

		if dotIndex < index then
			center += dot.size + gap
		elseif dotIndex == index then
			center += dot.size / 2
		end
	end

	return center - contentWidth / 2
end

local function getDotEntries(config: CarouselIndicatorDotsConfig): { [number]: DotEntry }
	local dots = config.dots
	local entries: { [number]: DotEntry } = {}
	for index, dot in dots do
		local previousDot = dots[index - 1]
		local nextDot = dots[index + 1]
		local previousSelectableDot = if previousDot and previousDot.isActive then dots[index - 2] else previousDot
		local nextSelectableDot = if nextDot and nextDot.isActive then dots[index + 2] else nextDot
		entries[dot.page] = {
			index = index,
			dot = dot,
			previousSelectablePage = if previousSelectableDot then previousSelectableDot.page else nil,
			nextSelectablePage = if nextSelectableDot then nextSelectableDot.page else nil,
		}
	end
	return entries
end

--- Page dots for a carousel. With more than five pages it shows a sliding window of dots that scrolls as the page
--- changes.
local function CarouselIndicator(carouselIndicatorProps: CarouselIndicatorProps): GuiObject
	local props = withDefaults(carouselIndicatorProps, defaultProps)
	local tokens = useTokens()

	local function count(): number
		return Value.read(props.count)
	end
	local function dotGap(): number
		return tokens().Size.Size_100
	end
	local function maxDotSize(): number
		return tokens().Size.Size_200
	end

	local dotsConfig = Vide.derive(function(): CarouselIndicatorDotsConfig
		return getCarouselIndicatorDotsConfig(maxDotSize(), tokens().Size.Size_100, Value.read(props.page), count())
	end)
	local dotEntries = Vide.derive(function()
		return getDotEntries(dotsConfig())
	end)

	local function easeConfig(): EaseOptions
		return { easingStyle = tokens().Ease.StandardOut, duration = tokens().Time.Time_200 }
	end
	local function dotColorEaseConfig(): EaseOptions
		return { easingStyle = tokens().Ease.Linear, duration = tokens().Time.Time_100 }
	end
	local function dotScaleEaseConfig(): EaseOptions
		return { easingStyle = tokens().Ease.StandardOut, duration = tokens().Time.Time_300 }
	end

	local shiftOffset, setShiftOffset = Motion.useAnimatedBinding(0)
	local previousDotsConfig: CarouselIndicatorDotsConfig? = nil
	Vide.effect(function()
		local config = dotsConfig()
		local gap = dotGap()
		local ease = easeConfig()
		Vide.untrack(function()
			local previous = previousDotsConfig
			--* Studio runs effects twice; the second run must not cancel the scroll the first one started.
			if previous == config then
				return
			end
			previousDotsConfig = config

			if previous and previous.count == config.count and previous.page ~= config.page then
				local pageDelta = config.page - previous.page
				local previousSelectedIndex = math.clamp(previous.activeVisibleIndex + pageDelta, 1, #previous.dots)
				local previousCenter = getDotCenter(previous.dots, previousSelectedIndex, gap)
				local currentCenter = getDotCenter(config.dots, config.activeVisibleIndex, gap)

				--* Starts at the previous active dot's position, so the dots scroll there instead of jumping.
				setShiftOffset(Motion.instant(shiftOffset() + previousCenter - currentCenter))
				setShiftOffset(Motion.ease(0, ease))
			else
				setShiftOffset(Motion.instant(0))
			end
		end)
	end)

	local dotInstances = Vide.source({} :: { [number]: GuiObject })
	local function setDotInstance(page: number, instance: GuiObject?, previous: GuiObject?)
		local current = Vide.untrack(dotInstances)
		if instance == nil and current[page] ~= previous then
			return
		end
		local updated = table.clone(current)
		updated[page] = instance
		dotInstances(updated)
	end

	local onActivated = props.onActivated
	local selectableDotRef = props.selectableDotRef
	if selectableDotRef then
		local last: GuiObject? = nil
		Vide.effect(function()
			local first: GuiObject? = nil
			if onActivated then
				for _, dot in dotsConfig().dots do
					if not dot.isActive then
						first = dotInstances()[dot.page]
						break
					end
				end
			end
			if first ~= last then
				last = first
				Vide.untrack(function()
					selectableDotRef(first)
				end)
			end
		end)
	end

	local dots = Vide.indexes(dotEntries, function(entry: () -> DotEntry, page: number)
		return Dot({
			LayoutOrder = function()
				return entry().index
			end,
			scale = Vide.derive(function()
				return entry().dot.size / maxDotSize()
			end),
			isActive = Vide.derive(function()
				return entry().dot.isActive
			end),
			maxSize = maxDotSize,
			page = page,
			scaleEaseConfig = dotScaleEaseConfig,
			colorEaseConfig = dotColorEaseConfig,
			onActivated = onActivated,
			Selectable = function()
				return not entry().dot.isActive and onActivated ~= nil
			end,
			NextSelectionUp = props.NextSelectionUp,
			NextSelectionDown = props.NextSelectionDown,
			NextSelectionLeft = function(): GuiObject?
				local neighbor = entry().previousSelectablePage
				return if neighbor == nil then Value.read(props.NextSelectionLeft) else dotInstances()[neighbor]
			end,
			NextSelectionRight = function(): GuiObject?
				local neighbor = entry().nextSelectablePage
				return if neighbor == nil then Value.read(props.NextSelectionRight) else dotInstances()[neighbor]
			end,
			ref = function(instance: GuiObject?, previous: GuiObject?)
				setDotInstance(page, instance, previous)
			end,
			testId = `{props.testId}--page-{page}`,
		})
	end)

	local dotsView = View({
		tag = "auto-y",
		Size = function()
			local visibleDots = math.min(MAX_VISIBLE_COUNT, count())
			return UDim2.fromOffset(visibleDots * maxDotSize() + (visibleDots - 1) * dotGap(), 0)
		end,
		layout = {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = function()
				return UDim.new(0, dotGap())
			end,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		},
		Position = function()
			return UDim2.fromOffset(shiftOffset(), 0)
		end,
		testId = `{props.testId}--dots`,
		children = dots,
	})
	dotsView.Name = "Dots"

	return View(withCommonProps(props, {
		tag = "auto-xy",
		children = dotsView,
	}) :: any)
end

return CarouselIndicator
