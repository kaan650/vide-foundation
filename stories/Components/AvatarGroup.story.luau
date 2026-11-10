local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local AvatarGroupType = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/AvatarGroupType")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local UserPresence = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/UserPresence")

type AvatarGroupItem = VideFoundation.AvatarGroupItem
type AvatarGroupType = AvatarGroupType.AvatarGroupType
type InputSize = InputSize.InputSize
type Value<T> = VideFoundation.Value<T>

type Avatars = { AvatarGroupItem | Value<number> }

local AVATAR_USER_IDS = {
	24813339,
	24813338,
	24813333,
	24813337,
	24813336,
	24813335,
	24813334,
	24813332,
	24813331,
}

local orderedSizes: { InputSize } = { InputSize.XSmall, InputSize.Small, InputSize.Medium, InputSize.Large }

local function buildAvatars(count: number): Avatars
	local avatars: Avatars = {}
	for index = 1, count do
		local userId = AVATAR_USER_IDS[(index - 1) % #AVATAR_USER_IDS + 1]
		if index % 3 == 1 then
			table.insert(avatars, { userId = userId, userPresence = UserPresence.InExperience })
		else
			table.insert(avatars, userId)
		end
	end
	return avatars
end

local avatars = buildAvatars(#AVATAR_USER_IDS)

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
	return VF.AvatarGroup({
		avatars = function(): Avatars
			return buildAvatars(controls.avatars())
		end,
		type = controls.type,
		max = controls.max,
		size = controls.size,
	})
end

local function SizeStory()
	local children = {}
	for index, size in orderedSizes do
		children[index] = Captioned({
			caption = size,
			LayoutOrder = index,
			group = VF.AvatarGroup({
				avatars = avatars,
				size = size,
				LayoutOrder = 2,
			}),
		})
	end
	return VF.View({ tag = "col wrap gap-xxlarge auto-xy", children = children })
end

local function TypeStory()
	local children = {}
	for index, groupType: AvatarGroupType in Dash.values(AvatarGroupType :: any) do
		children[index] = Captioned({
			caption = groupType,
			LayoutOrder = index,
			group = VF.AvatarGroup({
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
				group = VF.AvatarGroup({ avatars = avatars, max = 3, LayoutOrder = 2 }),
			}),
			Captioned({
				caption = "Full display",
				LayoutOrder = 2,
				group = VF.AvatarGroup({ avatars = avatars, LayoutOrder = 2 }),
			}),
		},
	})
end

return foundation.sections({
	summary = "AvatarGroup",
	controls = {
		type = UILabs.Choose(Dash.values(AvatarGroupType :: any)),
		avatars = 9,
		max = 5,
		size = UILabs.Choose(Dash.values(InputSize :: any)),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Size", story = SizeStory },
		{ name = "Type", story = TypeStory },
		{ name = "Content", story = ContentStory },
	},
})
