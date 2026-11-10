local Vide = require("../../Packages/Vide")

local ChipGroupVariant = require("../../Enums/ChipGroupVariant")
type ChipGroupVariant = ChipGroupVariant.ChipGroupVariant

local ChipSize = require("../../Enums/ChipSize")
type ChipSize = ChipSize.ChipSize

-- Large is left out: it does not look right in a large group of chips. Consumers use ChipSize directly.
export type ChipGroupSize = typeof(ChipSize.Small) | typeof(ChipSize.Medium)

local ChipVariant = require("../../Enums/ChipVariant")
type ChipVariant = ChipVariant.ChipVariant

local Accessory = require("../Chip/Accessory")
type Accessory = Accessory.Accessory

local Visibility = require("../../Enums/Visibility")

local BackgroundStyleContext = require("../../Providers/Style/BackgroundStyleContext")
local Chip = require("../Chip")
local ScrollView = require("../ScrollView")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local create = require("../../Utility/create")
local named = require("../../Utility/named")
local useChipGroupVariants = require("./useChipGroupVariants")
local useClippingRect = require("../OverflowScrollContainer/useClippingRect")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type Value<T> = Types.Value<T>

local START_GRADIENT = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 1),
})

local END_GRADIENT = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 0),
})

export type ChipGroupItem = {
	text: Value<string?>?,
	leading: Value<(string | Accessory)?>?,
	trailing: Value<(string | Accessory)?>?,
	onActivated: () -> (),
	isChecked: Value<boolean?>?,
	variant: Value<ChipVariant?>?,
}

export type ChipGroupProps = {
	-- The chips to render in the group.
	chips: Value<{ ChipGroupItem }>,
	-- Size applied to every Chip in the group. Overrides each Chip's own
	-- `size`.
	size: Value<ChipGroupSize>?,
	-- Controls how chips are laid out. Row renders chips in a single
	-- scrollable row with edge scrims that spills outside the group bounds.
	-- Wrap flows chips onto multiple rows and clips to the group bounds.
	variant: Value<ChipGroupVariant>?,
} & Types.CommonProps

local defaultProps = {
	size = ChipSize.Medium,
	variant = ChipGroupVariant.Row :: ChipGroupVariant,
	testId = "--foundation-chip-group",
}

type ScrimProps = {
	gradient: NumberSequence,
	width: () -> number,
	testId: string,
	LayoutOrder: number,
}

local function Scrim(props: ScrimProps): GuiObject
	local backgroundStyle = BackgroundStyleContext.useBackgroundStyle()

	return View({
		LayoutOrder = props.LayoutOrder,
		Size = function()
			return UDim2.new(0, props.width(), 1, 0)
		end,
		backgroundStyle = backgroundStyle,
		testId = props.testId,
		children = create("UIGradient")({
			Name = "UIGradient",
			Transparency = props.gradient,
		}),
	})
end

--- Chips in one scrollable row with scrims at both ends, or wrapped onto several rows.
local function ChipGroup(chipGroupProps: ChipGroupProps): GuiObject
	local props = withDefaults(chipGroupProps, defaultProps)
	local tokens = useTokens()
	local testId = props.testId

	local function size(): ChipGroupSize
		return Value.read(props.size)
	end

	local variant = Vide.derive(function()
		return useChipGroupVariants(tokens(), Value.read(props.variant), size())
	end)
	local function isWrapped(): boolean
		return variant().isWrapped
	end

	local scrollingFrame = Vide.source(nil :: ScrollingFrame?)
	local getScrollingFrame: () -> ScrollingFrame? = scrollingFrame :: any
	local viewportRect = useClippingRect(getScrollingFrame :: () -> GuiObject?)

	--* Keyed by position like Foundation's `Chip{i}` keys: a chip keeps its instance and takes the item now at its index.
	local function chipItems(): { ChipGroupItem }
		return Value.read(props.chips :: Value<{ ChipGroupItem }>)
	end
	local chips = Vide.indexes(chipItems, function(item: () -> ChipGroupItem, index: number)
		local function field(key: string): () -> any
			return function()
				return Value.read((item() :: any)[key])
			end
		end
		return named(
			`Chip{index}`,
			Chip({
				text = field("text"),
				leading = field("leading"),
				trailing = field("trailing"),
				onActivated = function()
					Vide.untrack(item).onActivated()
				end,
				isChecked = field("isChecked"),
				variant = field("variant"),
				size = size,
				LayoutOrder = index,
				testId = `{testId}--chip-{index}`,
			})
		)
	end)

	local scrollView = ScrollView({
		tag = "size-full-0 auto-y",
		scroll = {
			AutomaticSize = Enum.AutomaticSize.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			CanvasSize = UDim2.fromScale(0, 1),
			ScrollingDirection = Enum.ScrollingDirection.X,
			ScrollingEnabled = function()
				return not isWrapped()
			end,
			scrollBarVisibility = Visibility.None,
		},
		layout = {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = function()
				return UDim.new(0, variant().gap)
			end,
			Wraps = isWrapped,
		},
		ClipsDescendants = isWrapped,
		scrollingFrameRef = function(frame: ScrollingFrame)
			scrollingFrame(frame)
		end,
		children = chips,
	})
	scrollView.Name = "ScrollView"

	local function scrimWidth(): number
		return variant().scrimWidth
	end

	--* Foundation renders both scrims whether or not the row overflows: it tests the visibility bindings themselves,
	--* which are always truthy, instead of their values.
	local scrimWrapper = Vide.show(function()
		return variant().hasScrim
	end, function()
		local wrapper = View({
			tag = "row flex-between",
			Size = function()
				local rect = viewportRect()
				return UDim2.fromOffset(rect.Max.X - rect.Min.X, scrimWidth())
			end,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			ZIndex = 2,
			children = {
				named(
					"ScrimStart",
					Scrim({
						LayoutOrder = 1,
						gradient = START_GRADIENT,
						width = scrimWidth,
						testId = `{testId}--scrim-start`,
					})
				),
				named(
					"ScrimEnd",
					Scrim({
						LayoutOrder = 2,
						gradient = END_GRADIENT,
						width = scrimWidth,
						testId = `{testId}--scrim-end`,
					})
				),
			},
		})
		wrapper.Name = "ScrimWrapper"
		return wrapper
	end)

	return View(withCommonProps(props, {
		tag = "size-full-0 auto-y",
		children = { scrollView, scrimWrapper },
	}) :: any)
end

return ChipGroup
