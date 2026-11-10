local foundation = require("../foundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local InputLabelSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputLabelSize")
type InputLabelSize = InputLabelSize.InputLabelSize

local SIZES: { InputLabelSize } = { InputLabelSize.Large, InputLabelSize.Medium, InputLabelSize.Small }

local function PlaygroundStory(controls: { [string]: any })
	local labels = {}
	for index, size in SIZES do
		labels[index] = VF.InputLabel({
			Text = controls.Text,
			size = size,
			isRequired = foundation.orNil(controls.isRequired),
			isDisabled = controls.isDisabled,
			RichText = controls.RichText,
			LayoutOrder = index,
		})
	end
	return VF.View({
		tag = "row align-y-center gap-xxlarge auto-xy",
		children = labels,
	})
end

return foundation.sections({
	summary = "Label put above inputs",
	controls = {
		Text = "Input label",
		isRequired = UILabs.Choose({ foundation.NONE, false, true } :: { any }),
		isDisabled = false,
		RichText = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
	},
})
