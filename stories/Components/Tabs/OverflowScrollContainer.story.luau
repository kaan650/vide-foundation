local foundation = require("../../foundation")
local VF = foundation.VF
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local OverflowScrollContainer =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Tabs/OverflowScrollContainer")

local function PlaygroundStory(controls: { [string]: any })
	-- Enough content to scroll through.
	local children = {}
	for i = 1, 10 do
		children[i] = foundation.create("Frame")({
			Name = `Child{i}`,
			Size = UDim2.fromOffset(100, 32),
		})
	end

	return OverflowScrollContainer({
		size = controls.size,
		children = VF.View({
			tag = "row gap-small auto-xy",
			children = children,
		}),
	})
end

return foundation.sections({
	summary = "",
	controls = {
		size = UILabs.Choose(Dash.values(InputSize :: any)),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
	},
})
