local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local StatusIndicatorShape = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/StatusIndicatorShape")
local StatusIndicatorSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/StatusIndicatorSize")
local StatusIndicatorVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/StatusIndicatorVariant")
local Tokens = require("@game/ReplicatedStorage/Packages/VideFoundation/Providers/Style/Tokens")

type ColorStyleValue = VideFoundation.ColorStyleValue
type StatusIndicatorShape = StatusIndicatorShape.StatusIndicatorShape
type StatusIndicatorSize = StatusIndicatorSize.StatusIndicatorSize
type StatusIndicatorVariant = StatusIndicatorVariant.StatusIndicatorVariant

local NO_MASK = "None"
local surfaceColorKeys: { string } =
	Dash.joinArrays({ NO_MASK } :: { any }, Dash.keys(Tokens.defaultTokens.Color.Surface :: any))

--* Foundation's ValidNumericVariants with FoundationStatusIndicatorVariantExperiment off live.
local NUMERIC_VARIANTS: { [StatusIndicatorVariant]: boolean } = {
	[StatusIndicatorVariant.Emphasis] = true,
	[StatusIndicatorVariant.Standard] = true,
}

local function getVariants(): { StatusIndicatorVariant }
	local variants: { StatusIndicatorVariant } = {}
	for _, variant: StatusIndicatorVariant in StatusIndicatorVariant :: any do
		if variant == StatusIndicatorVariant.Contrast_Experiment then
			continue
		end
		table.insert(variants, variant)
	end
	return variants
end

local shapes: { StatusIndicatorShape } =
	{ StatusIndicatorShape.Circle, StatusIndicatorShape.Ring, StatusIndicatorShape.Square }

local function PlaygroundStory(controls: { [string]: any })
	local tokens = VF.Hooks.useTokens()
	return VF.View({
		tag = "col gap-large size-full-0 auto-y",
		--* Whether a mask is set decides the indicator's stroke, so a mask from or to None builds it again.
		children = foundation.rebuildOn(controls.mask, function(mask: string)
			return VF.StatusIndicator({
				variant = controls.variant,
				shape = controls.shape,
				size = controls.size,
				value = function(): number?
					local value: number = controls.value()
					return if value > 0 then value else nil
				end,
				max = controls.max,
				mask = if mask == NO_MASK
					then nil
					else function(): ColorStyleValue
						return (tokens().Color.Surface :: any)[mask]
					end,
			})
		end),
	})
end

local function AllVariantsStory()
	local order = 0
	local children = {}

	for _, variant in getVariants() do
		order += 1
		table.insert(
			children,
			VF.Text({
				Text = variant,
				tag = "auto-xy text-label-medium content-muted",
				LayoutOrder = order,
			})
		)

		local indicators = {}
		for index, shape in shapes do
			indicators[index] = VF.StatusIndicator({
				variant = variant,
				shape = shape,
				LayoutOrder = index,
			})
		end
		if NUMERIC_VARIANTS[variant] then
			table.insert(
				indicators,
				VF.StatusIndicator({
					variant = variant,
					value = 5,
					LayoutOrder = #indicators + 1,
				})
			)
		end

		order += 1
		table.insert(
			children,
			VF.View({
				tag = "row align-y-center gap-medium auto-xy",
				LayoutOrder = order,
				children = indicators,
			})
		)
	end

	return VF.View({
		tag = "col gap-small size-full-0 auto-y",
		children = children,
	})
end

local SIZES: { StatusIndicatorSize } = {
	StatusIndicatorSize.XSmall,
	StatusIndicatorSize.Small,
	StatusIndicatorSize.Medium,
	StatusIndicatorSize.Large,
}

local function SizesStory()
	local rows = {}
	for index, size in SIZES do
		rows[index] = VF.View({
			tag = "row align-y-center gap-medium auto-xy",
			LayoutOrder = index,
			children = {
				VF.Text({
					Text = size,
					tag = "auto-y text-label-medium text-align-x-left content-muted",
					Size = UDim2.fromOffset(64, 0),
					LayoutOrder = 1,
				}),
				VF.StatusIndicator({ size = size, shape = StatusIndicatorShape.Circle, LayoutOrder = 2 }),
				VF.StatusIndicator({ size = size, shape = StatusIndicatorShape.Ring, LayoutOrder = 3 }),
				VF.StatusIndicator({
					size = size,
					variant = StatusIndicatorVariant.Emphasis,
					value = 5,
					LayoutOrder = 4,
				}),
				VF.StatusIndicator({ size = size, value = 120, max = 99, LayoutOrder = 5 }),
			},
		})
	end
	return VF.View({
		tag = "col gap-medium size-full-0 auto-y",
		children = rows,
	})
end

local function IndicatorRow(props: { masked: boolean, LayoutOrder: number })
	local tokens = VF.Hooks.useTokens()
	local function backdrop(): ColorStyleValue
		return tokens().Color.Extended.Red.Red_800 :: ColorStyleValue
	end

	local tiles = {}
	for index, shape in shapes do
		tiles[index] = VF.View({
			tag = "align-x-center align-y-center radius-small",
			Size = UDim2.fromOffset(48, 48),
			backgroundStyle = function(): ColorStyleValue
				return tokens().Color.Surface.Surface_100 :: ColorStyleValue
			end,
			LayoutOrder = index,
			children = VF.StatusIndicator({
				variant = StatusIndicatorVariant.Success,
				shape = shape,
				mask = if props.masked then backdrop else nil,
			}),
		})
	end

	return VF.View({
		tag = "row align-y-center gap-large auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = tiles,
	})
end

local function CustomBackgroundStory()
	local tokens = VF.Hooks.useTokens()
	return VF.View({
		tag = "col gap-large auto-xy padding-large",
		backgroundStyle = function(): ColorStyleValue
			return tokens().Color.Extended.Red.Red_800 :: ColorStyleValue
		end,
		children = {
			IndicatorRow({ masked = false, LayoutOrder = 1 }),
			IndicatorRow({ masked = true, LayoutOrder = 2 }),
		},
	})
end

return foundation.sections({
	summary = "StatusIndicator",
	controls = {
		variant = UILabs.Choose(Dash.values(StatusIndicatorVariant :: any)),
		shape = UILabs.Choose(shapes),
		size = UILabs.Choose(Dash.values(VF.Enums.StatusIndicatorSize :: any)),
		value = 0,
		max = 99,
		mask = UILabs.Choose(surfaceColorKeys),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "All Variants",
			summary = "All variant × shape permutations, plus numeric where supported",
			story = AllVariantsStory,
		},
		{
			name = "Sizes",
			summary = "Dots, rings and counts at each size; Large counts use LabelMedium",
			story = SizesStory,
		},
		{
			name = "On custom background",
			summary = "Mask against a non-system red background; bottom row applies the mask, top row does not",
			story = CustomBackgroundStory,
		},
	},
})
