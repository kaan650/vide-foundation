local foundation = require("../foundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local FillBehavior = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/FillBehavior")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local Segment = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/SegmentedControl/Segment")
local SegmentedControlVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/SegmentedControlVariant")

type InputSize = InputSize.InputSize
type ItemId = string | number
type Segment = Segment.Segment

local IconName = VF.Enums.IconName

local segments: { Segment } = {
	{ id = "1", text = "First" },
	{ id = "2", text = "Second" },
	{ id = "3", text = "Third" },
}

local iconSegments: { Segment } = {
	{ id = "1", icon = { name = IconName.House } },
	{ id = "2", icon = { name = IconName.Gear } },
	{ id = "3", icon = { name = IconName.MagnifyingGlass } },
}

local ORDERED_SIZES: { InputSize } = { InputSize.XSmall, InputSize.Small, InputSize.Medium, InputSize.Large }
--* The order React renders its `Dash.map` over the enums in.
local VARIANTS = { SegmentedControlVariant.Stroke, SegmentedControlVariant.Filled, SegmentedControlVariant.Utility }
local FILL_BEHAVIORS = { FillBehavior.Fit, FillBehavior.Fill }

local function noop() end

local function Group(props: { caption: string, tag: string?, contentTag: string, LayoutOrder: number?, children: any })
	return VF.View({
		tag = props.tag or "col gap-medium size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.caption,
				tag = "auto-xy text-body-small content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = props.contentTag,
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local value = Vide.source(segments[1].id)
	local iconValue = Vide.source(iconSegments[1].id)

	return VF.View({
		tag = "col gap-small size-full-0 auto-y padding-large",
		children = {
			VF.SegmentedControl({
				size = controls.size,
				isCircular = controls.isCircular,
				segments = segments,
				value = value,
				onActivated = function(id: ItemId)
					value(id)
				end,
				LayoutOrder = 1,
			}),
			VF.SegmentedControl({
				size = controls.size,
				isCircular = controls.isCircular,
				segments = iconSegments,
				value = iconValue,
				onActivated = function(id: ItemId)
					iconValue(id)
				end,
				LayoutOrder = 2,
			}),
		},
	})
end

--* `variant` and `fillBehavior` only exist behind FoundationSegmentedControlBeta, which is off, so these sections
--* show the default control under each caption, as Foundation's do.
local function SizesByVariantsStory(controls: { [string]: any })
	local sizeGroups = {}
	for sizeIndex, size in ORDERED_SIZES do
		local variantGroups = {}
		for variantIndex, variant in VARIANTS do
			variantGroups[variantIndex] = Group({
				caption = variant,
				tag = "col gap-medium auto-xy",
				contentTag = "auto-xy",
				LayoutOrder = variantIndex,
				children = VF.SegmentedControl({
					segments = segments,
					value = segments[1].id,
					onActivated = noop,
					size = size,
					isCircular = controls.isCircular,
				}),
			})
		end
		sizeGroups[sizeIndex] = Group({
			caption = size,
			contentTag = "row gap-large auto-xy",
			LayoutOrder = sizeIndex,
			children = variantGroups,
		})
	end

	return VF.View({
		tag = "col gap-xlarge auto-xy",
		children = sizeGroups,
	})
end

local function FillBehaviorStory()
	local groups = {}
	for index, fill in FILL_BEHAVIORS do
		groups[index] = Group({
			caption = fill,
			contentTag = "col gap-small size-full-0 auto-y",
			LayoutOrder = index,
			children = VF.SegmentedControl({
				segments = segments,
				value = segments[1].id,
				onActivated = noop,
			}),
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y",
		children = groups,
	})
end

local function IsCircularStory()
	local groups = {}
	for index, option in { { caption = "Default", circular = false }, { caption = "Circular", circular = true } } do
		groups[index] = Group({
			caption = option.caption,
			tag = "col gap-medium auto-xy",
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = VF.SegmentedControl({
				segments = segments,
				value = segments[1].id,
				onActivated = noop,
				isCircular = option.circular,
			}),
		})
	end

	return VF.View({
		tag = "row gap-xxlarge auto-xy",
		children = groups,
	})
end

return foundation.sections({
	summary = "SegmentedControl",
	controls = {
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		isCircular = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizes × Variants", story = SizesByVariantsStory },
		{ name = "FillBehavior", story = FillBehaviorStory },
		{ name = "IsCircular", story = IsCircularStory },
	},
})
