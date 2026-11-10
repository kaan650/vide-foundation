local InputGroupStory = require("../Shared/InputGroupStory")
local VF = require("@game/ReplicatedStorage/Packages/VideFoundation")

return InputGroupStory.create({
	Group = VF.ToggleGroup,
	Item = VF.Toggle,
	itemName = "Toggle",
	summary = "ToggleGroup lays out related toggles with a shared legend and cascaded size, placement, and isDisabled.",
	defaultLegend = "Settings",
	labels = { "Notifications", "Sounds", "Vibration", "Do Not Disturb" },
	hints = {
		"Receive push and email alerts",
		"Play UI and notification sounds",
		"Vibrate on alerts and interactions",
		"Silence all interruptions",
	},
	states = {
		{ label = "Unchecked", isChecked = false },
		{ label = "Checked", isChecked = true },
		{ label = "Disabled", isDisabled = true, isChecked = false },
		{ label = "Disabled checked", isDisabled = true, isChecked = true },
	},
})
