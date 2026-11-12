local foundation = require("../foundation")
local VF = foundation.VF
local Vide = foundation.Vide

local NavigationBar = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/NavigationBar")
local Types = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Types")

type ItemId = Types.ItemId
type NavigationBarItem = NavigationBar.NavigationBarItem

local IconName = VF.Enums.IconName

local AVATAR_USER_ID = 156

local DESTINATIONS: { NavigationBarItem } = {
	{ id = "home", text = "Home", icon = IconName.House },
	{ id = "discover", text = "Discover", icon = IconName.Compass },
	{ id = "chat", text = "Chat", icon = IconName.SpeechBubbleAlignCenter, indicator = { value = 5 } },
	{ id = "avatar", text = "Avatar", icon = IconName.PersonStanding, indicator = {} },
	{ id = "me", text = "Me", icon = { type = "Avatar", userId = AVATAR_USER_ID } },
}

local function Labeled(props: { label: string, LayoutOrder: number, children: any })
	return VF.View({
		tag = "col gap-small size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
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

--- The first `count` destinations, always ending with the avatar tab.
local function destinations(count: number, chatCount: number): { NavigationBarItem }
	local clamped = math.clamp(count, 3, #DESTINATIONS)
	local items: { NavigationBarItem } = {}
	for index = 1, clamped - 1 do
		items[index] = table.clone(DESTINATIONS[index])
	end
	items[clamped] = DESTINATIONS[#DESTINATIONS]
	for _, item in items do
		if item.id == "chat" then
			item.indicator = if chatCount > 0 then { value = chatCount } else nil
		end
	end
	return items
end

local function PlaygroundStory(controls: { [string]: any })
	local activeItemId = Vide.source("home" :: ItemId)
	return NavigationBar({
		items = function()
			return destinations(controls.tabCount(), controls.chatCount())
		end,
		activeItemId = activeItemId,
		onActivated = function(id: ItemId)
			activeItemId(id)
		end,
	})
end

local function UsageStory()
	local activeItemId = Vide.source("home" :: ItemId)
	return NavigationBar({
		items = {
			{ id = "home", text = "Home", icon = IconName.House },
			{ id = "chat", text = "Chat", icon = IconName.SpeechBubbleAlignCenter, indicator = { value = 5 } },
			{ id = "me", text = "Me", icon = { type = "Avatar", userId = AVATAR_USER_ID } },
		},
		activeItemId = activeItemId,
		onActivated = function(id: ItemId)
			activeItemId(id)
		end,
	})
end

local function IndicatorsStory()
	return VF.View({
		tag = "col gap-xlarge size-full-0 auto-y",
		children = {
			Labeled({
				label = "Dot, count, and counts above max",
				LayoutOrder = 1,
				children = NavigationBar({
					items = {
						{ id = "dot", text = "Dot", icon = IconName.Bell, indicator = {} },
						{
							id = "count",
							text = "Count",
							icon = IconName.SpeechBubbleAlignCenter,
							indicator = { value = 5 },
						},
						{ id = "overflow", text = "99+", icon = IconName.Envelope, indicator = { value = 150 } },
						{
							id = "max",
							text = "Max 9",
							icon = IconName.ThreePeople,
							indicator = { value = 12, max = 9 },
						},
					},
				}),
			}),
			Labeled({
				label = "On an avatar",
				LayoutOrder = 2,
				children = NavigationBar({
					items = {
						{ id = "home", text = "Home", icon = IconName.House },
						{
							id = "me",
							text = "Me",
							icon = { type = "Avatar", userId = AVATAR_USER_ID },
							indicator = { value = 3 },
						},
						{ id = "more", text = "More", icon = IconName.ThreeDotsHorizontal, indicator = {} },
					},
				}),
			}),
		},
	})
end

local function UncontrolledStory()
	return Labeled({
		label = 'defaultActiveItemId = "chat"; NavigationBar tracks the active tab',
		LayoutOrder = 1,
		children = NavigationBar({
			items = destinations(5, 5),
			defaultActiveItemId = "chat",
			onActivated = foundation.action("Tab activated"),
		}),
	})
end

return foundation.sections({
	summary = "NavigationBar lets users switch between the primary destinations of an app, particularly on smaller screens. It sits at the bottom of the screen and holds 3 to 5 tabs.",
	controls = {
		tabCount = 5,
		chatCount = 5,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Usage", story = UsageStory },
		{
			name = "Indicators",
			summary = "A dot (indicator = {}) or a count; counts above max (99 by default) show as max+.",
			story = IndicatorsStory,
		},
		{ name = "Uncontrolled", story = UncontrolledStory },
	},
})
