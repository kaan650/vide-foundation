local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local AvatarGroupType = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/AvatarGroupType")
local AvatarIconSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/AvatarIconSize")

type AvatarGroupType = AvatarGroupType.AvatarGroupType
type AvatarIconSize = AvatarIconSize.AvatarIconSize
type Value<T> = VideFoundation.Value<T>

local avatars: { Value<number> } = {
	24813339,
	24813338,
	24813337,
	24813336,
	24813335,
	24813334,
}

local function Captioned(props: { caption: string, LayoutOrder: number, group: any })
	return VF.View({
		tag = "col align-x-center gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				tag = "auto-xy text-caption-small text-align-x-center",
				Text = props.caption,
				LayoutOrder = 1,
			}),
			props.group,
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.AvatarIconGroup({
		avatars = avatars,
		type = controls.type,
		max = controls.max,
		size = controls.size,
	})
end

local function SizeStory()
	local children = {}
	for index, size: AvatarIconSize in Dash.values(AvatarIconSize :: any) do
		children[index] = Captioned({
			caption = size,
			LayoutOrder = index,
			group = VF.AvatarIconGroup({
				avatars = avatars,
				size = size,
				LayoutOrder = 2,
			}),
		})
	end
	return VF.View({ tag = "row wrap gap-xxlarge auto-xy", children = children })
end

local function TypeStory()
	local children = {}
	for index, groupType: AvatarGroupType in Dash.values(AvatarGroupType :: any) do
		children[index] = Captioned({
			caption = groupType,
			LayoutOrder = index,
			group = VF.AvatarIconGroup({
				avatars = avatars,
				type = groupType,
				LayoutOrder = 2,
			}),
		})
	end
	return VF.View({ tag = "row wrap gap-xxlarge auto-xy", children = children })
end

local function ContentStory()
	return VF.View({
		tag = "row wrap gap-xxlarge auto-xy",
		children = {
			Captioned({
				caption = "Truncated (max 3)",
				LayoutOrder = 1,
				group = VF.AvatarIconGroup({ avatars = avatars, max = 3, LayoutOrder = 2 }),
			}),
			Captioned({
				caption = "Full display",
				LayoutOrder = 2,
				group = VF.AvatarIconGroup({ avatars = avatars, LayoutOrder = 2 }),
			}),
		},
	})
end

return foundation.sections({
	summary = "AvatarIconGroup",
	controls = {
		type = UILabs.Choose(Dash.values(AvatarGroupType :: any)),
		max = 4,
		size = UILabs.Choose(Dash.values(AvatarIconSize :: any)),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Size", story = SizeStory },
		{ name = "Type", story = TypeStory },
		{ name = "Content", story = ContentStory },
	},
})
