local foundation = require("../foundation")
local VF = foundation.VF

return foundation.sections({
	summary = "Toast is deprecated — replace with Notification when available",
	sections = {
		{
			name = "Deprecated",
			story = function()
				return VF.SystemBanner({
					severity = VF.Enums.AlertSeverity.Warning,
					title = "Toast is deprecated",
					description = "Toast is deprecated and should be replaced with Notification whenever it becomes available (see Components [Planned]).",
				})
			end,
		},
	},
})
