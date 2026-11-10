local foundation = require("../foundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local ChipSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ChipSize")
local RatingValue = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/RatingValue")

type ChipSize = ChipSize.ChipSize
type RatingValue = RatingValue.RatingValue

local TRUNCATION_TEXT = "99% of players liked this experience"

local VALUE_ORDER: { RatingValue } = {
	RatingValue.ThumbUp,
	RatingValue.ThumbDown,
	RatingValue.None,
}

--* Foundation maps over the ChipSize table, so its LayoutOrder is the key string and the engine rejects it,
--* leaving the sizes in declaration order.
local SIZE_ORDER: { ChipSize } = { ChipSize.Small, ChipSize.Medium, ChipSize.Large }

local function noop() end

local function PlaygroundStory(controls: { [string]: any })
	return VF.Rating({
		text = controls.text,
		size = controls.size,
		value = controls.value,
		onThumbUp = function()
			print("Thumb up")
		end,
		onThumbDown = function()
			print("Thumb down")
		end,
	})
end

local function Section(props: { LayoutOrder: number, name: string, contentTag: string?, children: any })
	return VF.View({
		tag = "col gap-medium size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.name,
				tag = "auto-xy text-label-medium content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = props.contentTag or "row gap-large auto-xy wrap",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function LabeledRating(props: {
	label: string,
	LayoutOrder: number,
	size: ChipSize?,
	value: RatingValue,
	text: string?,
})
	return VF.View({
		tag = "col gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.Rating({
				text = props.text or "99% liked",
				size = props.size,
				value = props.value,
				onThumbUp = noop,
				onThumbDown = noop,
				LayoutOrder = 2,
			}),
		},
	})
end

local function SiblingRow(props: { LayoutOrder: number, size: ChipSize })
	return VF.View({
		tag = "col gap-small size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.size,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "size-full-0 auto-y",
				LayoutOrder = 2,
				children = VF.View({
					tag = "row wrap gap-small size-full-0 auto-y",
					children = {
						VF.Rating({
							text = "Rating",
							size = props.size,
							value = RatingValue.None,
							onThumbUp = noop,
							onThumbDown = noop,
							LayoutOrder = 1,
						}),
						VF.Chip({
							text = "Chip",
							size = props.size,
							onActivated = noop,
							LayoutOrder = 2,
						}),
						VF.Chip({
							text = "Chip",
							size = props.size,
							onActivated = noop,
							LayoutOrder = 3,
						}),
					},
				}),
			}),
		},
	})
end

local function SizingStory()
	local ratings = {}
	for index, size in SIZE_ORDER do
		ratings[index] = LabeledRating({
			label = size,
			LayoutOrder = index,
			size = size,
			value = RatingValue.None,
		})
	end
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "Size",
			contentTag = "row gap-large auto-xy wrap",
			children = ratings,
		}),
	})
end

local function ControlledImplementationExample()
	local value = Vide.source(RatingValue.None :: RatingValue)
	local text = Vide.source("99% liked")

	return VF.Rating({
		text = text,
		value = value,
		onThumbUp = function()
			value(RatingValue.ThumbUp)
			text("100% liked")
		end,
		onThumbDown = function()
			value(RatingValue.ThumbDown)
			text("99% liked")
		end,
	})
end

local function ControlledStory()
	local values = {}
	for index, value in VALUE_ORDER do
		values[index] = LabeledRating({
			label = value,
			LayoutOrder = index,
			value = value,
		})
	end
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Controlled implementation",
				contentTag = "auto-xy",
				children = ControlledImplementationExample(),
			}),
			Section({
				LayoutOrder = 2,
				name = "Value",
				contentTag = "row gap-large auto-xy wrap",
				children = values,
			}),
		},
	})
end

local function TruncatedRating(props: { LayoutOrder: number, size: ChipSize })
	return VF.View({
		tag = "col gap-small size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.size,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "size-full-0 auto-y padding-small radius-medium bg-surface-100",
				sizeConstraint = {
					MaxSize = Vector2.new(200, math.huge),
				},
				LayoutOrder = 2,
				children = VF.Rating({
					text = TRUNCATION_TEXT,
					size = props.size,
					value = RatingValue.None,
					onThumbUp = noop,
					onThumbDown = noop,
				}),
			}),
		},
	})
end

local function ContentStory()
	local ratings = {}
	for index, size in SIZE_ORDER do
		ratings[index] = TruncatedRating({ LayoutOrder = index, size = size })
	end
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "Truncation",
			contentTag = "col gap-large size-full-0 auto-y",
			children = ratings,
		}),
	})
end

local function InContextStory()
	local rows = {}
	for index, size in SIZE_ORDER do
		rows[index] = SiblingRow({ LayoutOrder = index, size = size })
	end
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "Chips",
			contentTag = "col gap-medium size-full-0 auto-y",
			children = rows,
		}),
	})
end

return foundation.sections({
	summary = "Rating is a component that displays user voting feedback with upvote and downvote options.",
	controls = {
		text = "99% liked",
		size = UILabs.Choose(Dash.values(ChipSize :: any)),
		value = UILabs.Choose(Dash.values(RatingValue :: any)),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizing", story = SizingStory },
		{ name = "Controlled component", story = ControlledStory },
		{ name = "Content", story = ContentStory },
		{
			name = "In context",
			summary = "Rating should remain visually consistent with Chips.",
			story = InContextStory,
		},
	},
})
