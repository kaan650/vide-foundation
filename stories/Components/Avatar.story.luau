local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local AvatarSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/AvatarSize")
local UserPresence = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/UserPresence")

type AvatarSize = AvatarSize.AvatarSize
type ColorStyleValue = VideFoundation.ColorStyleValue
type UserPresence = UserPresence.UserPresence

local USER_ID = 24813339

--* The sizes Foundation shows with FoundationAvatarBeta on, as it is live.
local sizes: { AvatarSize } = {
	AvatarSize.Pictogram,
	AvatarSize.XLarge,
	AvatarSize.Large,
	AvatarSize.Medium,
	AvatarSize.Small,
}

--* Foundation maps over the UserPresence table without a LayoutOrder, so its rows follow the key order of the table
--* Dash.map returns.
local PRESENCE_ORDER: { UserPresence } = {
	UserPresence.None,
	UserPresence.Away,
	UserPresence.Active,
	UserPresence.InExperience,
}

local NO_SURFACE = "None"
local surfaceColorKeys = { NO_SURFACE, "Surface_0", "Surface_100", "Surface_200", "Surface_300" }

local function PlaygroundStory(controls: { [string]: any })
	local tokens = VF.Hooks.useTokens()
	local function surface(key: string): ColorStyleValue?
		return (tokens().Color.Surface :: any)[key]
	end

	--* Whether a backplate is set decides the avatar's stroke, so a backplate from or to None builds it again.
	return foundation.rebuildOn(controls.backplate, function(backplate: string)
		return VF.Avatar({
			userId = controls.userId,
			size = controls.size,
			userPresence = controls.userPresence,
			backgroundStyle = function(): ColorStyleValue
				return surface(controls.background()) :: any
			end,
			backplateStyle = if backplate == NO_SURFACE
				then nil
				else function(): ColorStyleValue
					return surface(backplate) :: any
				end,
			includeProfileFrame = controls.includeProfileFrame,
		})
	end)
end

local function PresenceAndSizesStory()
	local tokens = VF.Hooks.useTokens()
	local function background(): ColorStyleValue
		return tokens().Color.Shift.Shift_200 :: ColorStyleValue
	end

	local rows = {}
	for _, userPresence in PRESENCE_ORDER do
		local avatars = {}
		for index, size in sizes do
			avatars[index] = VF.Avatar({
				userId = USER_ID,
				userPresence = userPresence,
				size = size,
				backgroundStyle = background,
				LayoutOrder = index,
			})
		end

		table.insert(
			rows,
			VF.View({
				tag = "col gap-large auto-xy",
				LayoutOrder = #rows + 1,
				children = {
					VF.Text({
						Text = userPresence,
						tag = "align-x-left size-0-0 auto-xy text-caption-medium content-default",
						LayoutOrder = 1,
					}),
					VF.View({
						tag = "row gap-xxlarge auto-xy",
						LayoutOrder = 2,
						children = avatars,
					}),
				},
			})
		)
	end

	return VF.View({
		tag = "col gap-medium auto-xy",
		children = rows,
	})
end

return foundation.sections({
	summary = "Avatar",
	controls = {
		userId = USER_ID,
		size = UILabs.Choose(Dash.values(AvatarSize :: any)),
		userPresence = UILabs.Choose(Dash.values(UserPresence :: any)),
		background = UILabs.Choose(surfaceColorKeys),
		backplate = UILabs.Choose(surfaceColorKeys),
		includeProfileFrame = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Presence and sizes",
			summary = "Every user presence rendered across the supported sizes",
			story = function()
				return foundation.scroll(PresenceAndSizesStory())
			end,
		},
	},
})
