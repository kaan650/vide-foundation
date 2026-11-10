local foundation = require("../foundation")
local VF = foundation.VF

return foundation.sections({
	summary = "SystemBanner is deprecated — use Alert instead",
	sections = {
		{
			name = "Deprecated",
			story = function()
				return VF.Alert({
					variant = VF.Enums.AlertVariant.System,
					severity = VF.Enums.AlertSeverity.Warning,
					text = "SystemBanner is deprecated. Use Alert with AlertVariant.System instead.",
				})
			end,
		},
	},
})
