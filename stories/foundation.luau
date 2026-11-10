local Vide = require("@game/ReplicatedStorage/Packages/Vide")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
local VF = require("@game/ReplicatedStorage/Packages/VideFoundation")

--- Controls every story shares: the color mode and the theme.
local themeControls = {
	colorMode = UILabs.Choose({ "Dark", "Light" }),
	themeName = UILabs.Choose({ "Default", "Classic", "Kids", "CircuitRush", "NebulaDrift", "PixelPop" }),
}

local function controls(extra: { [string]: any }?): { [string]: any }
	local all = table.clone(themeControls)
	for key, value in extra or {} do
		all[key] = value
	end
	return all
end

--- Mounts `build` inside a FoundationProvider on a surface background, following the theme controls.
local function story(props: { controls: { [string]: any } }, build: () -> any)
	return VF.FoundationProvider({
		colorMode = props.controls.colorMode,
		themeName = props.controls.themeName,
		children = function()
			return VF.View({
				tag = "size-full bg-surface-0 padding-xlarge col gap-large",
				children = build(),
			})
		end,
	})
end

--- A callback that prints its arguments, for buttons in stories.
local function action(name: string)
	return function(...)
		print(`[Story] {name}`, ...)
	end
end

return {
	Vide = Vide,
	VF = VF,
	UILabs = UILabs,
	controls = controls,
	story = story,
	action = action,
}
