local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide

local ControlState = VF.Enums.ControlState

type ColorStyleValue = VideFoundation.ColorStyleValue

local function Story()
	local tokens = VF.Hooks.useTokens()
	local state = Vide.source(ControlState.Initialize :: string)

	return VF.UNSTABLE.Interactable({
		Size = UDim2.fromOffset(100, 100),
		BackgroundTransparency = function()
			return tokens().Color.Extended.Green.Green_500.Transparency
		end,
		BackgroundColor3 = function()
			return tokens().Color.Extended.Green.Green_500.Color3
		end,
		onStateChanged = function(new)
			state(new)
		end,
		onActivated = function()
			print("activated")
		end,
		onSecondaryActivated = function()
			print("secondary activated")
		end,
		VF.Text({
			Text = function()
				return tostring(state())
			end,
			Position = UDim2.fromScale(0.5, 0.5),
			textStyle = function(): ColorStyleValue
				return tokens().Color.Content.Emphasis :: ColorStyleValue
			end,
		}),
	} :: any)
end

return foundation.sections({
	summary = "View",
	sections = {
		{ name = "GUI State Use", story = Story },
	},
})
