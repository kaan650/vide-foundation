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

local Chip = require("../Chip")
local OverflowScrollContainer = require("../OverflowScrollContainer")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local useChipGroupVariants = require("./useChipGroupVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type Value<T> = Types.Value<T>

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

--- Chips in one row that scrolls under scrims at its overflowing ends, or wrapped onto several rows. A source
--- `variant` returns a source of the instance: Row and Wrap are different components, so switching between them
--- builds the group again, as React remounts it.
local function ChipGroup(chipGroupProps: ChipGroupProps): GuiObject | () -> GuiObject
	local props = withDefaults(chipGroupProps, defaultProps)
	local tokens = useTokens()
	local testId = props.testId

	local function size(): ChipGroupSize
		return Value.read(props.size)
	end

	local variant = Vide.derive(function()
		return useChipGroupVariants(tokens(), Value.read(props.variant), size())
	end)

	local function chipItems(): { ChipGroupItem }
		return Value.read(props.chips :: Value<{ ChipGroupItem }>)
	end

	local function chipContainer(isWrapped: boolean): GuiObject
		--* Keyed by position like Foundation's `Chip{i}` keys: a chip keeps its instance and takes the item now at its index.
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

		return named(
			"ChipContainer",
			View({
				tag = "auto-xy",
				layout = {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = function()
						return UDim.new(0, variant().gap)
					end,
					Wraps = isWrapped,
				},
				children = chips,
			})
		)
	end

	local function build(isWrapped: boolean): GuiObject
		if isWrapped then
			return View(withCommonProps(props, {
				tag = "size-full-0 auto-y",
				children = chipContainer(true),
			}) :: any)
		end
		return OverflowScrollContainer(withCommonProps(props, {
			--* ChipGroupSize values are InputSize values too; Foundation passes the chip size straight through.
			size = size :: any,
			children = chipContainer(false),
		}) :: any)
	end

	local variantProp = props.variant
	local isWrapped: Value<boolean> = if type(variantProp) == "function"
		then Vide.derive(function()
			return variant().isWrapped
		end)
		else Vide.untrack(variant).isWrapped
	return rebuildOn(isWrapped, build)
end

return ChipGroup
