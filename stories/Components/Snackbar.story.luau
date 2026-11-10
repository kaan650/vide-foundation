local foundation = require("../foundation")
local StoryIcons = require("../Shared/StoryIcons")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF

type SnackbarProps = VideFoundation.SnackbarProps

local function iconFromControl(controls: { [string]: any }): () -> string?
	return function()
		return StoryIcons.parseIconControl(controls.icon())
	end
end

return foundation.sections({
	summary = "Snackbar",
	controls = {
		icon = foundation.UILabs.Choose(StoryIcons.buildIconControlOptions()),
		title = "This is a snackbar!",
		actionText = "Primary",
		hasCloseAffordance = true,
	},
	sections = {
		{
			name = "Playground",
			story = function(controls)
				--* onClose is a plain callback, so toggling the close affordance builds the snackbar again.
				return foundation.rebuildOn(controls.hasCloseAffordance, function(hasCloseAffordance: boolean)
					local props: SnackbarProps = {
						action = function()
							local text = controls.actionText()
							return if text ~= ""
								then {
									text = text,
									onActivated = function()
										print("action activated")
									end,
								}
								else nil
						end,
						icon = iconFromControl(controls),
						onClose = if hasCloseAffordance
							then function()
								print("close clicked!")
							end
							else nil,
						title = controls.title,
					}
					return VF.Snackbar(props)
				end)
			end,
		},
		{
			name = "No Button Snackbar",
			story = function(controls)
				return VF.Snackbar({
					icon = iconFromControl(controls),
					title = controls.title,
				})
			end,
		},
	},
})
