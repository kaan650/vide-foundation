local foundation = require("./foundation")
local VF = foundation.VF
local Vide = foundation.Vide

local BADGE_VARIANTS = { "Emphasis", "Standard", "Neutral", "Success", "Warning", "Alert", "Contrast" }

return {
	summary = "Badges, status indicators, chips, avatars, tabs, toast and loading",
	vide = Vide,
	controls = foundation.controls({
		count = foundation.UILabs.Slider(3, 0, 150, 1),
	}),
	story = function(props: { controls: { [string]: any } })
		local controls = props.controls
		local selectedChip = Vide.source("all")

		return foundation.story(props, function()
			local badges = {}
			for index, variant in BADGE_VARIANTS do
				table.insert(badges, VF.Badge({ text = variant, variant = variant :: any, LayoutOrder = index }))
			end

			local chips = {}
			for index, id in { "all", "friends", "groups" } do
				table.insert(
					chips,
					VF.Chip({
						text = id,
						isChecked = function()
							return selectedChip() == id
						end,
						onActivated = function()
							selectedChip(id)
						end,
						LayoutOrder = index,
					})
				)
			end

			return {
				VF.View({ tag = "auto-xy row gap-small", LayoutOrder = 1, children = badges }),
				VF.View({
					tag = "auto-xy row gap-large align-y-center",
					LayoutOrder = 2,
					children = {
						VF.StatusIndicator({ variant = "Alert" :: any, value = controls.count, LayoutOrder = 1 }),
						VF.StatusIndicator({ variant = "Success" :: any, LayoutOrder = 2 }),
						VF.Avatar({ userId = 1, size = "Medium" :: any, userPresence = "Active" :: any, LayoutOrder = 3 }),
						VF.Avatar({ userId = 156, size = "Large" :: any, LayoutOrder = 4 }),
					},
				}),
				VF.View({ tag = "auto-xy row gap-small", LayoutOrder = 3, children = chips }),
				VF.Tabs({
					defaultActiveTabId = "home",
					tabs = {
						{ id = "home", text = "Home", content = function()
							return VF.Text({ Text = "Home content", tag = "auto-xy text-body-medium content-default" })
						end },
						{ id = "inbox", text = "Inbox", indicator = { value = controls.count } :: any, content = function()
							return VF.Text({ Text = "Inbox content", tag = "auto-xy text-body-medium content-default" })
						end },
						{ id = "settings", text = "Settings", icon = "gear", content = function()
							return VF.Text({ Text = "Settings content", tag = "auto-xy text-body-medium content-default" })
						end },
					} :: any,
					LayoutOrder = 4,
				} :: any),
				VF.Toast({
					title = "Saved",
					text = "Your changes were saved.",
					LayoutOrder = 5,
				} :: any),
				VF.Loading({ LayoutOrder = 6 } :: any),
			}
		end)
	end,
}
