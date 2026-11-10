local foundation = require("../foundation")
local VF = foundation.VF
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local StatusBadgeShape = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/StatusBadgeShape")
local StatusBadgeSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/StatusBadgeSize")
local StatusBadgeVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/StatusBadgeVariant")

type StatusBadgeShape = StatusBadgeShape.StatusBadgeShape
type StatusBadgeSize = StatusBadgeSize.StatusBadgeSize
type StatusBadgeVariant = StatusBadgeVariant.StatusBadgeVariant

local VARIANTS: { StatusBadgeVariant } = Dash.values(StatusBadgeVariant :: any)
local LONG_LABEL = "This status label is longer than the maximum width"

local function Example(props: {
	LayoutOrder: number,
	shape: StatusBadgeShape,
	size: StatusBadgeSize,
	variant: StatusBadgeVariant,
})
	return VF.View({
		tag = "col align-x-center gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.variant,
				tag = "auto-xy text-caption-small content-muted",
				LayoutOrder = 1,
			}),
			VF.StatusBadge({
				text = "Label",
				shape = props.shape,
				size = props.size,
				variant = props.variant,
				LayoutOrder = 2,
			}),
		},
	})
end

local function VariantRow(props: {
	label: string,
	LayoutOrder: number,
	shape: StatusBadgeShape,
	size: StatusBadgeSize,
})
	local examples = {}
	for index, variant in VARIANTS do
		examples[index] = Example({
			LayoutOrder = index,
			shape = props.shape,
			size = props.size,
			variant = variant,
		})
	end

	return VF.View({
		tag = "col gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-label-small content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "row wrap gap-xlarge auto-xy",
				LayoutOrder = 2,
				children = examples,
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.View({
		tag = "row align-x-center align-y-center size-full-2000 padding-large bg-surface-0",
		children = VF.StatusBadge({
			text = controls.text,
			variant = controls.variant,
			shape = controls.shape,
			size = controls.size,
			LayoutOrder = 1,
		}),
	})
end

local function SizesStory()
	return VF.View({
		tag = "col gap-xlarge auto-xy padding-large bg-surface-0",
		children = {
			VariantRow({
				label = "Small",
				LayoutOrder = 1,
				shape = StatusBadgeShape.Utility,
				size = StatusBadgeSize.Small,
			}),
			VariantRow({
				label = "XSmall",
				LayoutOrder = 2,
				shape = StatusBadgeShape.Utility,
				size = StatusBadgeSize.XSmall,
			}),
		},
	})
end

local function ShapesStory()
	return VF.View({
		tag = "col gap-xlarge auto-xy padding-large bg-surface-0",
		children = {
			VariantRow({
				label = "Utility",
				LayoutOrder = 1,
				shape = StatusBadgeShape.Utility,
				size = StatusBadgeSize.Small,
			}),
			VariantRow({
				label = "Box",
				LayoutOrder = 2,
				shape = StatusBadgeShape.Box,
				size = StatusBadgeSize.Small,
			}),
		},
	})
end

local function LongLabelStory()
	return VF.View({
		tag = "row gap-large auto-xy padding-large bg-surface-0",
		children = {
			VF.StatusBadge({
				text = LONG_LABEL,
				shape = StatusBadgeShape.Utility,
				LayoutOrder = 1,
			}),
			VF.StatusBadge({
				text = LONG_LABEL,
				shape = StatusBadgeShape.Box,
				LayoutOrder = 2,
			}),
		},
	})
end

return foundation.sections({
	summary = "A non-interactive status label for repeated, color-coded states in data-dense interfaces.",
	controls = {
		text = "Label",
		variant = UILabs.Choose(VARIANTS),
		shape = UILabs.Choose(Dash.values(StatusBadgeShape :: any)),
		size = UILabs.Choose(Dash.values(StatusBadgeSize :: any)),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizes", summary = "Size comparison per-variant", story = SizesStory },
		{ name = "Shapes", summary = "Shape comparison per-variant", story = ShapesStory },
		{
			name = "Long labels",
			summary = "Labels truncate after the component's maximum content width.",
			story = LongLabelStory,
		},
	},
})
