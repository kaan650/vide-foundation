local foundation = require("../foundation")
local VF = foundation.VF
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local IconSize = VF.Enums.IconSize

local SIZES = { IconSize.Large, IconSize.Medium, IconSize.Small, IconSize.XSmall }

return foundation.single({
	summary = "Icon component for displaying icons",
	controls = {
		name = UILabs.Choose(Dash.values(VF.Enums.IconName :: any)),
		variant = UILabs.Choose(Dash.values(VF.Enums.IconVariant :: any)),
	},
	story = function(controls)
		local icons = {}
		for index, size in SIZES do
			icons[index] = VF.Icon({
				name = controls.name,
				size = size,
				variant = controls.variant,
				LayoutOrder = index,
			})
		end
		return VF.View({
			tag = "row align-y-center gap-xxlarge auto-xy",
			children = icons,
		})
	end,
})
