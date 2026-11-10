local Motion = require("../../Utility/Motion")
local TransitionPreset = Motion.TransitionPreset
type MotionState = Motion.MotionState

local Tokens = require("../../Providers/Style/Tokens")
type Tokens = Tokens.Tokens

local Types = require("../Types")
type ColorStyleValue = Types.ColorStyleValue

export type InputColors = {
	backgroundStyle: ColorStyleValue?,
	hoverStyle: ColorStyleValue?,
	checkedStyle: ColorStyleValue?,
	labelStyle: ColorStyleValue?,
	labelHoverStyle: ColorStyleValue?,
}

export type InputMotionStates = {
	Default: MotionState,
	Checked: MotionState,
}

local function useInputMotionStates(tokens: Tokens, colors: InputColors?): InputMotionStates
	local defaultStyle: ColorStyleValue = if colors and colors.backgroundStyle
		then colors.backgroundStyle
		else tokens.Color.Content.Default :: ColorStyleValue
	local checkedStyle: ColorStyleValue = if colors and colors.checkedStyle
		then colors.checkedStyle
		else tokens.Color.ActionSubEmphasis.Background :: ColorStyleValue
	local labelStyle = tokens.Color.Content.Emphasis :: ColorStyleValue

	return {
		Default = Motion.createState({
			backgroundStyle = {
				Color3 = defaultStyle.Color3,
				Transparency = if colors and colors.backgroundStyle then colors.backgroundStyle.Transparency else 1,
			},
			strokeStyle = defaultStyle,
			labelStyle = labelStyle,
		}, {
			default = Motion.transition(TransitionPreset.Default, { duration = 0.2 }),
			transparency = Motion.transition({ easingStyle = Enum.EasingStyle.Linear, duration = 0.2 }),
		}),
		Checked = Motion.createState({
			backgroundStyle = checkedStyle,
			strokeStyle = checkedStyle,
			labelStyle = labelStyle,
		}, {
			default = Motion.transition(TransitionPreset.Default, { duration = 0.2 }),
			transparency = Motion.transition({ easingStyle = Enum.EasingStyle.Linear, duration = 0.2 }),
		}),
	}
end

return useInputMotionStates
