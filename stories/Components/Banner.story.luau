local foundation = require("../foundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local BannerSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/BannerSize")
local CardDensity = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/CardDensity")
local UserPresence = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/UserPresence")

type BannerSize = BannerSize.BannerSize
type BannerDensity = typeof(CardDensity.Compact) | typeof(CardDensity.Default)

local IconName = VF.Enums.IconName

local SAMPLE_IMAGE = Content.fromAssetId(78323814447735).Uri :: string
local SAMPLE_USER_ID = 156

local SIZE_ORDER: { BannerSize } = { BannerSize.Medium, BannerSize.Small }
local DENSITY_ORDER: { BannerDensity } = { CardDensity.Default, CardDensity.Compact }
local THUMBNAIL_OPTIONS = { "None", "Avatar", "Image", "Icon", "Slot" }

local BANNER_WIDTH = 480
local TITLE = "Title"
local DESCRIPTION = "Description that tells the player what the banner is about and why it matters."

local function action(name: string): () -> ()
	return function()
		print(`[Banner] {name}`)
	end
end

local function thumbnail(kind: string): any
	if kind == "Avatar" then
		return { type = "Avatar", userId = SAMPLE_USER_ID, userPresence = UserPresence.InExperience }
	elseif kind == "Image" then
		return { type = "Image", image = SAMPLE_IMAGE }
	elseif kind == "Icon" then
		return { type = "Icon", icon = IconName.Diamond }
	elseif kind == "Slot" then
		return {
			type = "Slot",
			children = VF.Text({
				Text = "99+",
				tag = "auto-xy text-title-large content-emphasis",
			}),
		}
	end
	return nil
end

local function Example(props: { label: string, LayoutOrder: number, children: any })
	return VF.View({
		Size = UDim2.fromOffset(BANNER_WIDTH, 0),
		tag = "col gap-small auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-muted",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "col size-full-0 auto-y",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function Grid(children: { any })
	return foundation.scroll(VF.View({
		tag = "row wrap gap-xlarge size-full-0 auto-y align-y-top",
		children = children,
	}))
end

local function PlaygroundStory(controls: { [string]: any })
	--* `size` picks the layout and the actions are callbacks, all plain props, so changing one builds the banner again.
	local key = function(): string
		return `{controls.size()}|{controls.primary()}|{controls.secondary()}|{controls.close()}|{controls.thumbnail()}`
	end

	local function optional(control: () -> string): () -> string?
		return function()
			local value = control()
			return if value ~= "" then value else nil
		end
	end

	return Example({
		label = "Banner",
		LayoutOrder = 1,
		children = foundation.rebuildOn(key, function()
			local primary = if controls.primary() then { onActivated = action("primary") } else nil
			local onClose = if controls.close() then action("close") else nil
			if controls.size() == BannerSize.Small then
				--* A Slot thumbnail holds an instance, so a thumbnail change rebuilds the banner instead of reaching it as a source.
				return VF.Banner({
					size = BannerSize.Small,
					density = controls.density,
					title = optional(controls.title),
					description = optional(controls.description),
					thumbnail = thumbnail(controls.thumbnail()),
					actions = { primary = primary },
					onClose = onClose,
				})
			end
			return VF.Banner({
				density = controls.density,
				title = optional(controls.title),
				description = optional(controls.description),
				media = function()
					return if controls.media() then SAMPLE_IMAGE else nil
				end,
				actions = {
					primary = primary,
					secondary = if controls.secondary()
						then { text = "Secondary", onActivated = action("secondary") }
						else nil,
				},
				onClose = onClose,
			})
		end),
	})
end

local function SizesStory()
	return Grid({
		Example({
			label = "Medium",
			LayoutOrder = 1,
			children = VF.Banner({
				title = TITLE,
				description = DESCRIPTION,
				media = SAMPLE_IMAGE,
				actions = { primary = { onActivated = action("primary") } },
			}),
		}),
		Example({
			label = "Small",
			LayoutOrder = 2,
			children = VF.Banner({
				size = BannerSize.Small,
				title = TITLE,
				description = DESCRIPTION,
				thumbnail = thumbnail("Image"),
				actions = { primary = { onActivated = action("primary") } },
			}),
		}),
	})
end

local function DensityStory()
	local examples = {}
	for sizeIndex, size in SIZE_ORDER do
		for densityIndex, density in DENSITY_ORDER do
			local layoutOrder = (sizeIndex - 1) * #DENSITY_ORDER + densityIndex
			examples[layoutOrder] = Example({
				label = `{size}, {density}`,
				LayoutOrder = layoutOrder,
				children = if size == BannerSize.Small
					then VF.Banner({
						size = BannerSize.Small,
						density = density,
						title = TITLE,
						description = DESCRIPTION,
						thumbnail = thumbnail("Avatar"),
						onClose = action("close"),
					})
					else VF.Banner({
						density = density,
						title = TITLE,
						description = DESCRIPTION,
						media = SAMPLE_IMAGE,
						actions = { secondary = { text = "Secondary", onActivated = action("secondary") } },
						onClose = action("close"),
					}),
			})
		end
	end
	return Grid(examples)
end

local function MediumStory()
	return Grid({
		Example({
			label = "Text only",
			LayoutOrder = 1,
			children = VF.Banner({ title = TITLE, description = DESCRIPTION }),
		}),
		Example({
			label = "End media",
			LayoutOrder = 2,
			children = VF.Banner({ title = TITLE, description = DESCRIPTION, media = SAMPLE_IMAGE }),
		}),
		Example({
			label = "End media, width 96",
			LayoutOrder = 3,
			children = VF.Banner({
				title = TITLE,
				description = DESCRIPTION,
				media = { image = SAMPLE_IMAGE, width = 96 },
			}),
		}),
		Example({
			label = "Secondary action",
			LayoutOrder = 4,
			children = VF.Banner({
				title = TITLE,
				description = DESCRIPTION,
				actions = { secondary = { text = "Secondary", onActivated = action("secondary") } },
			}),
		}),
		Example({
			label = "Close",
			LayoutOrder = 5,
			children = VF.Banner({ title = TITLE, description = DESCRIPTION, onClose = action("close") }),
		}),
		Example({
			label = "Everything",
			LayoutOrder = 6,
			children = VF.Banner({
				title = TITLE,
				description = DESCRIPTION,
				media = SAMPLE_IMAGE,
				actions = {
					primary = { onActivated = action("primary") },
					secondary = { text = "Secondary", onActivated = action("secondary") },
				},
				onClose = action("close"),
			}),
		}),
	})
end

local function SmallStory()
	local examples = {}
	for index = 2, #THUMBNAIL_OPTIONS do
		local kind = THUMBNAIL_OPTIONS[index]
		examples[index - 1] = Example({
			label = `{kind} thumbnail`,
			LayoutOrder = index - 1,
			children = VF.Banner({
				size = BannerSize.Small,
				title = TITLE,
				description = DESCRIPTION,
				thumbnail = thumbnail(kind),
				actions = { primary = { onActivated = action("primary") } },
			}),
		})
	end
	local count = #examples
	table.insert(
		examples,
		Example({
			label = "Close, no primary action",
			LayoutOrder = count + 1,
			children = VF.Banner({
				size = BannerSize.Small,
				title = TITLE,
				description = DESCRIPTION,
				thumbnail = thumbnail("Icon"),
				onClose = action("close"),
			}),
		})
	)
	table.insert(
		examples,
		Example({
			label = "Close is hidden by the primary action",
			LayoutOrder = count + 2,
			children = VF.Banner({
				size = BannerSize.Small,
				title = TITLE,
				description = DESCRIPTION,
				thumbnail = thumbnail("Icon"),
				actions = { primary = { onActivated = action("primary") } },
				onClose = action("close"),
			}),
		})
	)
	return Grid(examples)
end

return foundation.sections({
	summary = "Banner highlights a message with an optional action.",
	controls = {
		size = UILabs.Choose(SIZE_ORDER),
		density = UILabs.Choose(DENSITY_ORDER),
		title = TITLE,
		description = DESCRIPTION,
		primary = true,
		secondary = false,
		close = false,
		media = true,
		thumbnail = UILabs.Choose(THUMBNAIL_OPTIONS),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Sizes",
			summary = "Medium supports media and a secondary action; Small supports a thumbnail.",
			story = SizesStory,
		},
		{ name = "Density", story = DensityStory },
		{ name = "Medium", story = MediumStory },
		{
			name = "Small",
			summary = "On Small the close button only appears without a primary action, whose chevron takes its place.",
			story = SmallStory,
		},
	},
})
