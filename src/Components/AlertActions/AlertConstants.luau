local BuilderIcons = require("../../Packages/BuilderIcons")
local IconName = BuilderIcons.Icon

local AlertSeverity = require("../../Enums/AlertSeverity")
type AlertSeverity = AlertSeverity.AlertSeverity

local ButtonVariant = require("../../Enums/ButtonVariant")
type ButtonVariant = ButtonVariant.ButtonVariant

local SEVERITY_TO_ICON: { [AlertSeverity]: string } = {
	[AlertSeverity.Info] = IconName.CircleI,
	[AlertSeverity.Warning] = IconName.TriangleExclamation,
	[AlertSeverity.Success] = IconName.CircleCheck,
	[AlertSeverity.Error] = IconName.CircleX,
}

local MAX_ACTION_COUNT = 3

export type AlertAction = {
	onActivated: () -> (),
	-- Only `Standard` and `Utility` variants are supported
	variant: (typeof(ButtonVariant.Standard) | typeof(ButtonVariant.Utility))?,
	text: string,
}

return {
	MAX_ACTION_COUNT = MAX_ACTION_COUNT,
	SEVERITY_TO_ICON = SEVERITY_TO_ICON,
}
