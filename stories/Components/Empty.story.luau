local foundation = require("../foundation")
local VF = foundation.VF

local IconName = VF.Enums.IconName
local IconSize = VF.Enums.IconSize

local function PlaygroundStory(controls: { [string]: any })
	--* `button` is a plain table, so showing it builds Empty again.
	return foundation.rebuildOn(controls.showButton, function(showButton: boolean)
		return VF.Empty({
			icon = {
				name = controls.iconName,
				size = controls.iconSize,
			},
			text = function(): string
				local text = controls.text()
				return if text ~= "" then text else nil :: any
			end,
			button = if showButton
				then {
					text = controls.buttonText,
					onActivated = function() end,
				}
				else nil,
		})
	end)
end

local function WithButtonStory()
	return VF.Empty({
		icon = {
			name = "rbxasset://textures/ui/LuaChat/icons/ic-friends.png",
			size = IconSize.XLarge,
		},
		text = "To Party with friends, turn on Party in your privacy settings.",
		button = {
			text = "Privacy Settings",
			icon = IconName.ArrowUpRightFromSquare,
			onActivated = function() end,
		},
	})
end

return foundation.sections({
	summary = "Empty component for displaying emptys",
	controls = {
		text = "To Party with friends, turn on Party in your privacy settings.",
		showButton = false,
		buttonText = "Privacy Settings",
		iconName = foundation.UILabs.Choose({ IconName.MagnifyingGlass, IconName.SignalExclamation }),
		iconSize = foundation.UILabs.Choose({ IconSize.XLarge, IconSize.Large }),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "With Button", story = WithButtonStory },
	},
})
