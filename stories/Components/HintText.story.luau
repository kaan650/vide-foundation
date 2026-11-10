local foundation = require("../foundation")
local VF = foundation.VF

return foundation.sections({
	summary = "Helper text put below inputs",
	controls = {
		text = "Helper text",
		hasError = false,
		isDisabled = false,
	},
	sections = {
		{
			name = "Playground",
			story = function(controls)
				return VF.UNSTABLE.HintText({
					text = controls.text,
					hasError = controls.hasError,
					isDisabled = controls.isDisabled,
				})
			end,
		},
	},
})
