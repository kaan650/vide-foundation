local StatusIndicatorVariant = require("../../Enums/StatusIndicatorVariant")
type StatusIndicatorVariant = StatusIndicatorVariant.StatusIndicatorVariant

local numericVariants: { [StatusIndicatorVariant]: boolean } = {
	[StatusIndicatorVariant.Emphasis] = true,
	[StatusIndicatorVariant.Standard] = true,
}

return numericVariants
