local foundation = require("../foundation")
local VF = foundation.VF

return foundation.sections({
	summary = "Coachmark is deprecated — use EducationalTooltip instead",
	sections = {
		{
			name = "Deprecated",
			story = function()
				return VF.SystemBanner({
					severity = VF.Enums.AlertSeverity.Warning,
					title = "Coachmark is deprecated",
					description = "Use EducationalTooltip instead. Coachmark will be removed in Foundation v2.",
				})
			end,
		},
	},
})
