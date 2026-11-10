local foundation = require("../foundation")
local VF = foundation.VF

return foundation.sections({
	summary = "FeedbackAlert is deprecated — use Alert instead",
	sections = {
		{
			name = "Deprecated",
			story = function()
				return VF.Alert({
					variant = VF.Enums.AlertVariant.Feedback,
					severity = VF.Enums.AlertSeverity.Warning,
					text = "FeedbackAlert is deprecated. Use Alert with AlertVariant.Feedback instead.",
				})
			end,
		},
	},
})
