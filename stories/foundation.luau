local Vide = require("@game/ReplicatedStorage/Packages/Vide")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
local VF = require("@game/ReplicatedStorage/Packages/VideFoundation")

local TokenOverridesStore = require("./Shared/TokenOverridesStore")

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

--- Mounts `build` inside a FoundationProvider on a surface background, following the theme controls and the token
--- overrides set in the Elements/TokenOverrides story.
local function story(props: { controls: { [string]: any } }, build: () -> any)
	return VF.FoundationProvider({
		colorMode = props.controls.colorMode,
		themeName = props.controls.themeName,
		tokenOverrides = TokenOverridesStore.use() :: any,
		children = function()
			return VF.View({
				tag = "size-full bg-surface-0 padding-xlarge col gap-large",
				children = build(),
			})
		end,
	})
end

export type Section = {
	name: string,
	summary: string?,
	-- Builds the section; `controls` holds a source per control.
	story: (controls: { [string]: any }) -> any,
}

--- One UI Labs story from a Foundation story module that holds several stories (Playground, Variants, Sizing...).
--- A `section` control picks which one is shown. Pass Foundation's summary, its controls and its stories in order.
local function sections(spec: { summary: string, controls: { [string]: any }?, sections: { Section } })
	local names = {}
	local builders = {}
	for _, section in spec.sections do
		table.insert(names, section.name)
	end

	local allControls = controls(spec.controls)
	allControls.section = UILabs.Choose(names)

	return {
		summary = spec.summary,
		vide = Vide,
		controls = allControls,
		story = function(props: { controls: { [string]: any } })
			for _, section in spec.sections do
				builders[section.name] = function()
					return section.story(props.controls)
				end
			end
			return story(props, function()
				return Vide.switch(props.controls.section)(builders)
			end)
		end,
	}
end

--- One UI Labs story from a Foundation story module with a single `story` instead of a `stories` list.
local function single(spec: {
	summary: string?,
	controls: { [string]: any }?,
	story: (controls: { [string]: any }) -> any,
})
	return {
		summary = spec.summary,
		vide = Vide,
		controls = controls(spec.controls),
		story = function(props: { controls: { [string]: any } })
			return story(props, function()
				return spec.story(props.controls)
			end)
		end,
	}
end

--- Wraps a section taller than the preview in a ScrollView that fills the story, as Foundation's storybook scrolls.
local function scroll(children: any)
	return VF.ScrollView({
		tag = "size-full",
		scroll = {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollingDirection = Enum.ScrollingDirection.Y,
		},
		children = children,
	})
end

--- The entry of a Choose control standing for Foundation's `React.None`: the prop is left nil.
local NONE = "nil"

--- Reads a Choose control that has a `NONE` entry, giving nil for it.
local function orNil(control: () -> any): () -> any
	return function()
		local value = control()
		return if value == NONE then nil else value
	end
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
	--- Foundation's Dash (`Dash.values(Enum)` for Choose controls, `Dash.map`...).
	Dash = require("@game/ReplicatedStorage/Packages/VideFoundation/Utility/Dash"),
	--- Builds a child again whenever a source changes, as a React `key` change remounts it.
	rebuildOn = require("@game/ReplicatedStorage/Packages/VideFoundation/Utility/rebuildOn"),
	--- Vide.create without Vide's class defaults, for engine instances (`create("UIGradient")({ ... })`).
	create = require("@game/ReplicatedStorage/Packages/VideFoundation/Utility/create"),
	controls = controls,
	story = story,
	sections = sections,
	single = single,
	scroll = scroll,
	NONE = NONE,
	orNil = orNil,
	action = action,
}
