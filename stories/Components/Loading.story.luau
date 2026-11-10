local foundation = require("../foundation")
local VF = foundation.VF

local IconSize = VF.Enums.IconSize

return foundation.sections({
	summary = "Loading component",
	controls = {
		size = foundation.UILabs.Choose({ IconSize.Large, IconSize.Medium, IconSize.Small }),
	},
	sections = {
		{
			name = "Playground",
			story = function(controls)
				return VF.Loading({ size = controls.size })
			end,
		},
	},
})
