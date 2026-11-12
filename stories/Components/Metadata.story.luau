local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local AccessoryType = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/AccessoryType")
local MetadataSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/MetadataSize")

type MetadataItem = VideFoundation.MetadataItem
type MetadataSize = MetadataSize.MetadataSize

local IconName = VF.Enums.IconName

local SIZE_ORDER: { MetadataSize } = { MetadataSize.Medium, MetadataSize.Small }
local ITEM_COUNT_OPTIONS = { "1", "2", "3" }
local NARROW_WIDTH = 240

--* The type checker infers an unannotated list from its first entry and rejects it against the text union, as
--* Metadata.code.md notes, so lists go through this annotation.
local function list(items: { MetadataItem }): { MetadataItem }
	return items
end

local function Example(props: { label: string, LayoutOrder: number, width: number?, children: any })
	return VF.View({
		tag = if props.width then "col gap-small auto-y" else "col gap-small auto-xy",
		Size = if props.width then UDim2.fromOffset(props.width, 0) else nil,
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-muted",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "size-full-0 auto-y",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function Column(children: { any })
	return VF.View({
		tag = "col gap-xlarge size-full-0 auto-y",
		children = children,
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.Metadata({
		text = function(): MetadataItem | { MetadataItem }
			local count = tonumber(controls.items()) or 1
			if count == 1 then
				return if controls.leadingIcon()
					then { text = controls.text(), leading = IconName.Diamond }
					else controls.text()
			end
			local items: { MetadataItem } = {}
			for _ = 1, count do
				table.insert(
					items,
					if controls.leadingIcon()
						then { text = controls.text(), leading = IconName.Diamond }
						else controls.text()
				)
			end
			return items
		end,
		trailing = function()
			return if controls.trailingIcon() then IconName.Diamond else nil
		end,
		hasSeparator = controls.hasSeparator,
		maxLines = controls.maxLines,
		size = controls.size,
	})
end

local function ItemsStory()
	local mixed: { MetadataItem } = {
		"Metadata",
		{ text = "Metadata", leading = IconName.Diamond },
	}
	return Column({
		Example({ label = "Single item", LayoutOrder = 1, children = VF.Metadata({ text = "Metadata" }) }),
		Example({
			label = "List",
			LayoutOrder = 2,
			children = VF.Metadata({ text = list({ "Metadata", "Metadata", "Metadata" }) }),
		}),
		Example({
			label = "Leading and trailing icons",
			LayoutOrder = 3,
			children = VF.Metadata({
				text = { text = "Metadata", leading = IconName.Diamond },
				trailing = IconName.Diamond,
			}),
		}),
		Example({
			label = "Avatar",
			LayoutOrder = 4,
			children = VF.Metadata({
				text = { text = "Builderman", leading = { type = AccessoryType.Avatar, userId = 156 } },
			}),
		}),
		Example({
			label = "Without separator",
			LayoutOrder = 5,
			children = VF.Metadata({
				text = list({
					{ text = "Metadata", leading = IconName.Diamond },
					{ text = "Metadata", leading = IconName.Diamond },
				}),
				hasSeparator = false,
			}),
		}),
		Example({
			label = "Mixed list",
			LayoutOrder = 6,
			children = VF.Metadata({ text = mixed, hasSeparator = false }),
		}),
	})
end

local function SizeStory()
	local examples = {}
	for index, size in SIZE_ORDER do
		examples[index] = Example({
			label = size,
			LayoutOrder = index,
			children = VF.Metadata({
				text = list({ { text = "Metadata", leading = IconName.Diamond }, "Metadata" }),
				size = size,
			}),
		})
	end
	return Column(examples)
end

local function TruncationStory()
	return Column({
		Example({
			label = `Last item truncates ({NARROW_WIDTH}px)`,
			width = NARROW_WIDTH,
			LayoutOrder = 1,
			children = VF.Metadata({
				text = list({ "4.5K Playing", "Ages 9+", "Adventure and Exploration Experiences" }),
			}),
		}),
		Example({
			label = `truncateIndex = 2 ({NARROW_WIDTH}px)`,
			width = NARROW_WIDTH,
			LayoutOrder = 2,
			children = VF.Metadata({
				text = list({ "4.5K Playing", "Adventure and Exploration Experiences", "Ages 9+" }),
				truncateIndex = 2,
			}),
		}),
		Example({
			label = `Single item ({NARROW_WIDTH}px)`,
			width = NARROW_WIDTH,
			LayoutOrder = 3,
			children = VF.Metadata({
				text = "Adventure and Exploration Experiences for the whole family",
			}),
		}),
	})
end

local function WrappingStory()
	return Column({
		Example({
			label = `maxLines = 2 ({NARROW_WIDTH}px)`,
			width = NARROW_WIDTH,
			LayoutOrder = 1,
			children = VF.Metadata({
				text = "Adventure and Exploration Experiences for the whole family to enjoy together",
				maxLines = 2,
			}),
		}),
		Example({
			label = `maxLines = 3 ({NARROW_WIDTH}px)`,
			width = NARROW_WIDTH,
			LayoutOrder = 2,
			children = VF.Metadata({
				text = "Adventure and Exploration Experiences for the whole family to enjoy together, every day of the week",
				maxLines = 3,
			}),
		}),
	})
end

local function GlyphsStory()
	return Column({
		Example({
			label = "Slashed zero and tailed l",
			LayoutOrder = 1,
			children = VF.Metadata({ text = list({ "0O", "l I 1", "user_l0l1" }) }),
		}),
	})
end

return foundation.sections({
	summary = "Metadata provides concise, high-signal contextual information. It helps users quickly understand classification, status, appropriateness, or other decision-relevant descriptors. Metadata is not interactive.",
	controls = {
		text = "Metadata",
		items = UILabs.Choose(ITEM_COUNT_OPTIONS),
		leadingIcon = false,
		trailingIcon = false,
		hasSeparator = true,
		maxLines = 1,
		size = UILabs.Choose(SIZE_ORDER),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Items", story = ItemsStory },
		{
			name = "Size",
			summary = "Small uses body small text, for use next to smaller headings. Icons, avatars and spacing stay the same.",
			story = SizeStory,
		},
		{
			name = "Truncation",
			summary = "Metadata truncates with an ellipsis when its parent is narrower than its content. truncateIndex picks the list item that gives up space.",
			story = TruncationStory,
		},
		{
			name = "Wrapping",
			summary = "A single item wraps up to maxLines before it truncates. Lists always stay on one line.",
			story = WrappingStory,
		},
		{
			name = "Glyphs",
			summary = "Metadata always renders a slashed zero and a tailed lowercase l.",
			story = GlyphsStory,
		},
	},
})
