local Motion = require("../../../Utility/Motion")
local Tokens = require("../../../Providers/Style/Tokens")
local TransitionPreset = Motion.TransitionPreset
type MotionState = Motion.MotionState
type Tokens = Tokens.Tokens

export type OptionSelectorGroupItemMotionStates = {
	Default: MotionState,
	Disabled: MotionState,
}

local function useOptionSelectorGroupItemMotionStates(
	tokens: Tokens,
	defaultTransparency: number?,
	disabledTransparency: number
): OptionSelectorGroupItemMotionStates
	return {
		Default = Motion.createState({
			transparency = defaultTransparency or 0,
			textTransparency = defaultTransparency or 0,
		}, {
			iconTransparency = Motion.transition(
				TransitionPreset.Default,
				{ easingStyle = Enum.EasingStyle.Linear, duration = tokens.Time.Time_500 }
			),
			transparency = Motion.transition({ easingStyle = Enum.EasingStyle.Linear, duration = tokens.Time.Time_200 }),
			default = Motion.transition(TransitionPreset.Default, { duration = tokens.Time.Time_200 }),
		}),
		Disabled = Motion.createState({
			transparency = disabledTransparency,
			textTransparency = disabledTransparency,
		}, {
			default = Motion.transition({ easingStyle = Enum.EasingStyle.Linear, duration = tokens.Time.Time_100 }),
		}),
	}
end

return useOptionSelectorGroupItemMotionStates
