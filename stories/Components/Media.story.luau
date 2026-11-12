local foundation = require("../foundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local MediaAspectRatio = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/MediaAspectRatio")
local MediaOrientation = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/MediaOrientation")

type MediaAspectRatio = MediaAspectRatio.MediaAspectRatio
type MediaOrientation = MediaOrientation.MediaOrientation

local SAMPLE_IMAGE = Content.fromAssetId(78323814447735).Uri :: string

local ASPECT_RATIO_ORDER: { MediaAspectRatio } = {
	MediaAspectRatio.Ratio1x1,
	MediaAspectRatio.Ratio5x4,
	MediaAspectRatio.Ratio4x3,
	MediaAspectRatio.Ratio3x2,
	MediaAspectRatio.Ratio16x9,
	MediaAspectRatio.Ratio2x1,
}

local ORIENTATION_ORDER: { MediaOrientation } = {
	MediaOrientation.Landscape,
	MediaOrientation.Portrait,
}

local PLAYGROUND_WIDTH = 320
local CELL_WIDTH = 160

--- Media takes its width from its container, so every example sits in a fixed-width column.
local function Example(props: {
	label: string,
	width: number,
	LayoutOrder: number,
	aspectRatio: any,
	orientation: any,
})
	return VF.View({
		Size = UDim2.fromOffset(props.width, 0),
		tag = "col gap-small auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.Media({
				content = { type = "Image", source = SAMPLE_IMAGE },
				aspectRatio = props.aspectRatio,
				orientation = props.orientation,
				LayoutOrder = 2,
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return Example({
		label = "Media",
		width = PLAYGROUND_WIDTH,
		LayoutOrder = 1,
		aspectRatio = controls.aspectRatio,
		orientation = controls.orientation,
	})
end

local function AspectRatiosStory()
	local rows = {}
	for orientationIndex, orientation in ORIENTATION_ORDER do
		local examples = {}
		for index, aspectRatio in ASPECT_RATIO_ORDER do
			examples[index] = Example({
				label = aspectRatio,
				width = CELL_WIDTH,
				LayoutOrder = index,
				aspectRatio = aspectRatio,
				orientation = orientation,
			})
		end
		rows[orientationIndex] = VF.View({
			tag = "col gap-medium size-full-0 auto-y",
			LayoutOrder = orientationIndex,
			children = {
				VF.Text({
					Text = orientation,
					tag = "auto-xy text-label-medium content-default",
					LayoutOrder = 1,
				}),
				VF.View({
					tag = "row wrap gap-large size-full-0 auto-y align-y-top",
					LayoutOrder = 2,
					children = examples,
				}),
			},
		})
	end
	return foundation.scroll(VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y",
		children = rows,
	}))
end

local function OrientationStory()
	local examples = {}
	for index, orientation in ORIENTATION_ORDER do
		examples[index] = Example({
			label = `16:9 {orientation}`,
			width = CELL_WIDTH,
			LayoutOrder = index,
			aspectRatio = MediaAspectRatio.Ratio16x9,
			orientation = orientation,
		})
	end
	return VF.View({
		tag = "row gap-large auto-xy align-y-top",
		children = examples,
	})
end

return foundation.sections({
	summary = "Media displays visual content such as an image at a fixed aspect ratio. The content is cropped to fill the chosen aspect ratio. It fills the width of its container by default and derives its height from the aspect ratio and orientation.",
	controls = {
		aspectRatio = UILabs.Choose(ASPECT_RATIO_ORDER),
		orientation = UILabs.Choose(ORIENTATION_ORDER),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Aspect ratios", story = AspectRatiosStory },
		{
			name = "Orientation",
			summary = "Portrait swaps the ratio so the taller dimension dominates. It has no visible effect on 1:1.",
			story = OrientationStory,
		},
	},
})
