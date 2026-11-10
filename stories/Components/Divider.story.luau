local foundation = require("../foundation")
local VF = foundation.VF

local DividerVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/DividerVariant")
local Orientation = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/Orientation")

type DividerVariant = DividerVariant.DividerVariant
type Orientation = Orientation.Orientation

local VARIANT_ORDER: { DividerVariant } = {
	DividerVariant.Default,
	DividerVariant.Heavy,
	DividerVariant.Inset,
	DividerVariant.InsetLeft,
	DividerVariant.InsetRight,
}

local function LabeledDivider(props: {
	label: string,
	LayoutOrder: number,
	variant: DividerVariant?,
	orientation: Orientation?,
})
	return VF.View({
		tag = "col align-x-left gap-small size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.Divider({
				variant = props.variant,
				orientation = props.orientation,
				LayoutOrder = 2,
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.View({
		tag = "align-x-center align-y-center gap-large size-full-2000 padding-large bg-surface-0",
		children = VF.Divider({
			variant = controls.variant,
			orientation = controls.orientation,
		}),
	})
end

local function VariantsStory()
	local children = {}
	for index, variant in VARIANT_ORDER do
		children[index] = LabeledDivider({
			label = variant,
			LayoutOrder = index,
			variant = variant,
			orientation = Orientation.Horizontal,
		})
	end
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = children,
	})
end

local function OrientationStory()
	return VF.View({
		tag = "col align-x-center gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = {
			LabeledDivider({
				label = "Horizontal",
				LayoutOrder = 1,
				orientation = Orientation.Horizontal,
			}),
			VF.View({
				tag = "col align-x-left gap-small size-full-0 auto-y",
				LayoutOrder = 2,
				children = {
					VF.Text({
						Text = "Vertical",
						tag = "auto-xy text-caption-small text-align-x-left content-default",
						LayoutOrder = 1,
					}),
					VF.View({
						tag = "row align-x-center align-y-center",
						Size = UDim2.new(1, 0, 0, 200),
						LayoutOrder = 2,
						children = VF.Divider({
							orientation = Orientation.Vertical,
						}),
					}),
				},
			}),
		},
	})
end

return foundation.sections({
	summary = "Divider is a simple visual element used to separate related content into distinct sections or groups.",
	controls = {
		variant = foundation.UILabs.Choose(VARIANT_ORDER),
		orientation = foundation.UILabs.Choose({ Orientation.Horizontal, Orientation.Vertical }),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Variants", summary = "Variant applies to horizontal only.", story = VariantsStory },
		{ name = "Orientation", story = OrientationStory },
	},
})
