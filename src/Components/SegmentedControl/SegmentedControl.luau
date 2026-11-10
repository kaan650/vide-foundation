local Vide = require("../../Packages/Vide")

local InputSize = require("../../Enums/InputSize")
local Segment = require("./Segment")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local useAnimatedHighlight = require("../../Utility/useAnimatedHighlight")
local useSegmentedControlVariants = require("./useSegmentedControlVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InputSize = InputSize.InputSize
type ItemId = Types.ItemId
export type Segment = Segment.Segment
type Value<T> = Types.Value<T>

export type SegmentedControlProps = {
	segments: Value<{ Segment }>,
	-- The selected segment's id.
	value: Value<ItemId>,
	onActivated: (id: ItemId) -> (),
	size: Value<InputSize>?,
	-- Gives the container and the segments a fully circular radius.
	isCircular: Value<boolean?>?,
} & Types.CommonProps

local defaultProps = {
	size = InputSize.Medium,
	testId = "--foundation-segmented-control",
	ZIndex = 1,
}

type Entry = { segment: Segment, index: number }

--- A row of mutually exclusive segments with a highlight that slides to the selected one.
local function SegmentedControl(segmentedControlProps: SegmentedControlProps): GuiObject
	local props = withDefaults(segmentedControlProps, defaultProps)
	local tokens = useTokens()

	local function size(): InputSize
		return Value.read(props.size)
	end
	local function isCircular(): boolean?
		return Value.read(props.isCircular)
	end
	local function activeId(): ItemId?
		return Value.read(props.value)
	end

	local variantProps = Vide.derive(function()
		return useSegmentedControlVariants(tokens(), size(), isCircular())
	end)

	local segmentInstances = Vide.source({} :: { [ItemId]: GuiObject })
	local containerInstance = Vide.source(nil :: GuiObject?)
	local getContainer: () -> GuiObject? = containerInstance :: any
	local hiddenContainerSize = Vide.source(Vector2.zero)

	--* Keyed by id like Foundation's segments, so a segment keeps its instance and test id when the list reorders.
	local entries = Vide.derive(function(): { [ItemId]: Entry }
		local byId: { [ItemId]: Entry } = {}
		local list: { Segment } = Value.read(props.segments :: Value<{ Segment }>)
		for index, segment in list do
			byId[segment.id] = { segment = segment, index = index }
		end
		return byId
	end)

	local function createSegment(entry: () -> Entry, id: ItemId): GuiObject
		local view = Segment({
			segment = function()
				return entry().segment
			end,
			onActivated = props.onActivated,
			size = size,
			isCircular = isCircular,
			LayoutOrder = function()
				return (entry().index - 1) * 2 + 1
			end,
			testId = `{props.testId}--segment-{id}`,
		})

		local instances = table.clone(Vide.untrack(segmentInstances))
		instances[id] = view
		segmentInstances(instances)
		Vide.cleanup(function()
			local remaining = table.clone(Vide.untrack(segmentInstances))
			if remaining[id] == view then
				remaining[id] = nil
				segmentInstances(remaining)
			end
		end)

		local ref = Vide.untrack(entry).segment.ref
		if ref then
			ref(view)
		end
		return view
	end
	local segments = Vide.indexes(entries :: () -> { [ItemId]: Entry }, createSegment)

	local highlight = useAnimatedHighlight(activeId, getContainer, segmentInstances)

	--* Segments sit inset in the container; the overlay is offset by the same amount.
	local function segmentYInset(): number
		local container = Vide.untrack(getContainer)
		local id = Vide.untrack(activeId)
		local activeSegment = if id ~= nil then Vide.untrack(segmentInstances)[id] else nil
		if container and activeSegment then
			return activeSegment.AbsolutePosition.Y - container.AbsolutePosition.Y
		end
		return 0
	end

	local onAbsoluteSizeChanged = props.onAbsoluteSizeChanged
	local container = View({
		tag = function()
			return variantProps().container.tag
		end,
		testId = `{props.testId}--segments-container`,
		onAbsoluteSizeChanged = function(frame: GuiObject)
			if onAbsoluteSizeChanged then
				onAbsoluteSizeChanged(frame)
			end
			hiddenContainerSize(frame.AbsoluteSize)
		end,
		children = segments,
	})
	container.Name = "SegmentsContainer"
	containerInstance(container)

	local overlay = View({
		tag = function()
			return variantProps().segment.tag
		end,
		backgroundStyle = function()
			return tokens().Color.Shift.Shift_400 :: any
		end,
		Size = function()
			return UDim2.fromOffset(highlight.highlightWidth(), highlight.activeItemHeight())
		end,
		Position = function()
			return UDim2.fromOffset(highlight.highlightPosition(), segmentYInset())
		end,
		ZIndex = function()
			return Value.read(props.ZIndex) + 1
		end,
		testId = `{props.testId}--animated-overlay`,
	})
	overlay.Name = "Overlay"

	return View(withCommonProps(props, {
		Size = function()
			local size = hiddenContainerSize()
			return UDim2.fromOffset(size.X, size.Y)
		end,
		children = { container, overlay },
	}) :: any)
end

return SegmentedControl
