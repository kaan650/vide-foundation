local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local AvatarIconSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/AvatarIconSize")

type AvatarIconSize = AvatarIconSize.AvatarIconSize
type ColorStyleValue = VideFoundation.ColorStyleValue

local USER_ID = 24813339

local orderedSizes: { AvatarIconSize } = {
	AvatarIconSize.XSmall,
	AvatarIconSize.Small,
	AvatarIconSize.Medium,
	AvatarIconSize.Large,
	AvatarIconSize.XLarge,
}

local NO_SURFACE = "None"
local surfaceKeys: { string } =
	Dash.joinArrays({ NO_SURFACE } :: { any }, Dash.keys(VF.Utility.getTokens("Dark").Color.Surface :: any))

local function Group(props: { caption: string, contentTag: string, LayoutOrder: number?, children: any })
	return VF.View({
		tag = "col gap-medium auto-xy",
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
	local tokens = VF.Hooks.useTokens()
	local function surface(key: string): ColorStyleValue?
		return (tokens().Color.Surface :: any)[key]
	end

	--* Whether a backplate is set decides the icon's stroke, so a backplate from or to None builds it again.
	return foundation.rebuildOn(controls.backplate, function(backplate: string)
		return VF.AvatarIcon({
			userId = controls.userId,
			size = controls.size,
			backplateStyle = if backplate == NO_SURFACE
				then nil
				else function(): ColorStyleValue
					return surface(backplate) :: any
				end,
			backgroundStyle = function(): ColorStyleValue
				return surface(controls.background()) :: any
			end,
		})
	end)
end

local function SizesStory()
	local groups = {}
	for index, size in orderedSizes do
		groups[index] = Group({
			caption = size,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = VF.AvatarIcon({
				userId = USER_ID,
				size = size,
			}),
		})
	end
	return VF.View({
		tag = "row align-y-center gap-xlarge auto-xy",
		children = groups,
	})
end

return foundation.sections({
	summary = "AvatarIcon",
	controls = {
		userId = USER_ID,
		size = UILabs.Choose(Dash.values(AvatarIconSize :: any)),
		backplate = UILabs.Choose(surfaceKeys),
		background = UILabs.Choose(surfaceKeys),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizes", story = SizesStory },
	},
})
