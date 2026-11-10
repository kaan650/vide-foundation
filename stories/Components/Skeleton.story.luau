local foundation = require("../foundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local AvatarSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/AvatarSize")
local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local PreferencesProvider =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Providers/Preferences/PreferencesProvider")
local Radius = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/Radius")

type Radius = Radius.Radius

type StorySize = {
	size: UDim2,
	title: string,
}

local EXAMPLE_SIZE_CONTROL = "Size (examples)"
local CUSTOM_SIZE_CONTROL = "Size (custom)"

local SKELETON_SIZE_EXAMPLES: { StorySize } = {
	{ size = UDim2.fromOffset(48, 48), title = "Small square" },
	{ size = UDim2.fromOffset(200, 16), title = "Wide bar" },
	{ size = UDim2.fromOffset(120, 120), title = "Medium square" },
	{ size = UDim2.fromOffset(280, 140), title = "Wide rectangle" },
}

local EMPTY_EXAMPLE_SIZE = ""
local CUSTOM_SIZE_PLACEHOLDER = "e.g. 120, 120"
local DEFAULT_SIZE = UDim2.fromScale(1, 1)

local function trim(value: string): string
	return (string.gsub(string.gsub(value, "^%s+", ""), "%s+$", ""))
end

local function formatSizeString(size: UDim2): string
	return `UDim2.fromOffset({size.X.Offset}, {size.Y.Offset})`
end

local function parseSizeString(value: string): UDim2?
	local trimmed = trim(value)
	if trimmed == "" then
		return nil
	end

	local width, height = string.match(trimmed, "^(%d+)%s*,%s*(%d+)$")
	if width and height then
		return UDim2.fromOffset(tonumber(width) :: number, tonumber(height) :: number)
	end

	width, height = string.match(trimmed, "^(%d+)%s*[x×]%s*(%d+)$")
	if width and height then
		return UDim2.fromOffset(tonumber(width) :: number, tonumber(height) :: number)
	end

	return nil
end

local function isInactiveCustomSize(customSize: string): boolean
	local trimmed = trim(customSize)
	return trimmed == "" or trimmed == CUSTOM_SIZE_PLACEHOLDER
end

local function formatDisplayLabel(example: StorySize): string
	return `{example.title} ({formatSizeString(example.size)})`
end

local EXAMPLE_SIZE_OPTIONS: { [string]: UDim2 } = {}
local EXAMPLE_SIZE_LABELS: { string } = {}
for _, example in SKELETON_SIZE_EXAMPLES do
	EXAMPLE_SIZE_OPTIONS[formatSizeString(example.size)] = example.size
	table.insert(EXAMPLE_SIZE_LABELS, formatSizeString(example.size))
end
table.insert(EXAMPLE_SIZE_LABELS, EMPTY_EXAMPLE_SIZE)

local function resolveSize(exampleSize: string, customSize: string): UDim2
	local parsedCustomSize = if isInactiveCustomSize(customSize) then nil else parseSizeString(customSize)
	if parsedCustomSize then
		return parsedCustomSize
	end
	if exampleSize ~= EMPTY_EXAMPLE_SIZE then
		local example = EXAMPLE_SIZE_OPTIONS[exampleSize]
		if example then
			return example
		end
	end
	return DEFAULT_SIZE
end

local IN_CONTEXT_AVATAR_USER_ID = 24813339
local IN_CONTEXT_BUTTON_SIZE = UDim2.fromOffset(140, 36)
local REDUCED_MOTION_EXAMPLE_SIZE = UDim2.fromOffset(160, 160)

local RADIUS_OPTIONS: { Radius } = {
	Radius.None,
	Radius.XSmall,
	Radius.Small,
	Radius.Medium,
	Radius.Large,
	Radius.Circle,
}

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

local function Label(text: string)
	return VF.Text({
		Text = text,
		tag = "auto-xy text-caption-small text-align-x-left content-default",
		LayoutOrder = 1,
	})
end

local function LabeledSkeleton(props: { label: string, LayoutOrder: number, radius: Radius?, size: UDim2? })
	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			Label(props.label),
			VF.Skeleton({
				radius = props.radius,
				Size = props.size or UDim2.fromOffset(100, 100),
				LayoutOrder = 2,
			}),
		},
	})
end

local function InContextPair(props: {
	label: string,
	LayoutOrder: number,
	content: any,
	skeletonRadius: Radius,
	skeletonSize: UDim2,
})
	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			Label(props.label),
			VF.View({
				tag = "row align-y-center gap-xlarge auto-xy",
				LayoutOrder = 2,
				children = {
					VF.View({
						tag = "auto-xy",
						LayoutOrder = 1,
						children = props.content,
					}),
					VF.Skeleton({
						radius = props.skeletonRadius,
						Size = props.skeletonSize,
						LayoutOrder = 2,
					}),
				},
			}),
		},
	})
end

local function MotionExample(props: { label: string, description: string, LayoutOrder: number, reducedMotion: boolean })
	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			Label(props.label),
			VF.Text({
				Text = props.description,
				tag = "auto-xy text-caption-small text-align-x-left content-muted",
				LayoutOrder = 2,
			}),
			PreferencesProvider({
				preferences = { reducedMotion = props.reducedMotion },
				children = function()
					return VF.Skeleton({
						radius = Radius.Small,
						Size = REDUCED_MOTION_EXAMPLE_SIZE,
					})
				end,
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.Skeleton({
		radius = controls.radius,
		Size = function()
			return resolveSize(controls[EXAMPLE_SIZE_CONTROL](), controls[CUSTOM_SIZE_CONTROL]())
		end,
	})
end

local function SizingStory()
	local skeletons = {}
	for index, entry in SKELETON_SIZE_EXAMPLES do
		skeletons[index] = LabeledSkeleton({
			label = formatDisplayLabel(entry),
			LayoutOrder = index,
			radius = Radius.Small,
			size = entry.size,
		})
	end
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "Size (these are example sizes)",
			contentTag = "row gap-xlarge auto-xy wrap",
			children = skeletons,
		}),
	})
end

local function RoundingStory()
	local skeletons = {}
	for index, radius in RADIUS_OPTIONS do
		skeletons[index] = LabeledSkeleton({
			label = radius,
			LayoutOrder = index,
			radius = radius,
			size = UDim2.fromOffset(80, 80),
		})
	end
	return VF.View({
		tag = "row wrap gap-large auto-xy padding-large bg-surface-0",
		children = skeletons,
	})
end

local function InContextStory()
	local avatarExample = SKELETON_SIZE_EXAMPLES[1]
	local textExample = SKELETON_SIZE_EXAMPLES[2]

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "In context",
			contentTag = "col gap-xlarge align-x-left auto-xy",
			children = {
				InContextPair({
					label = "Avatar",
					LayoutOrder = 1,
					skeletonRadius = Radius.Circle,
					skeletonSize = avatarExample.size,
					content = VF.Avatar({
						userId = IN_CONTEXT_AVATAR_USER_ID,
						size = AvatarSize.Medium,
					}),
				}),
				InContextPair({
					label = "Text",
					LayoutOrder = 2,
					skeletonRadius = Radius.Small,
					skeletonSize = textExample.size,
					content = VF.Text({
						Text = "Display name",
						tag = "auto-xy text-body-medium content-default",
					}),
				}),
				InContextPair({
					label = "Button",
					LayoutOrder = 3,
					skeletonRadius = Radius.Small,
					skeletonSize = IN_CONTEXT_BUTTON_SIZE,
					content = VF.Button({
						text = "Button",
						variant = ButtonVariant.Emphasis,
						size = InputSize.Medium,
						onActivated = function() end,
					}),
				}),
			},
		}),
	})
end

local function ReducedMotionStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "Reduced motion",
			contentTag = "row gap-xlarge auto-xy wrap",
			children = {
				MotionExample({
					label = "Default",
					description = "Scrolling shimmer gradient",
					LayoutOrder = 1,
					reducedMotion = false,
				}),
				MotionExample({
					label = "Reduced motion",
					description = "Pulsating opacity, no gradient",
					LayoutOrder = 2,
					reducedMotion = true,
				}),
			},
		}),
	})
end

return foundation.sections({
	summary = "A placeholder shape shown in place of content while it loads.",
	controls = {
		radius = UILabs.Choose(RADIUS_OPTIONS),
		[EXAMPLE_SIZE_CONTROL] = UILabs.Choose(EXAMPLE_SIZE_LABELS),
		[CUSTOM_SIZE_CONTROL] = CUSTOM_SIZE_PLACEHOLDER,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizing", story = SizingStory },
		{ name = "Rounding", story = RoundingStory },
		{
			name = "Reduced motion",
			summary = "Compares the default scrolling shimmer with the reduced-motion pulse behavior.",
			story = ReducedMotionStory,
		},
		{
			name = "In context",
			summary = "Common components shown alongside skeleton placeholders that match their dimensions.",
			story = InContextStory,
		},
	},
})
