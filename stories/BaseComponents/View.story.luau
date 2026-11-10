local foundation = require("../foundation")
local StyleProvider = require("@game/ReplicatedStorage/Packages/VideFoundation/Providers/Style/StyleProvider")
local VF = foundation.VF

local ColorMode = VF.Enums.ColorMode
local UILabs = foundation.UILabs

type ColorMode = "Light" | "Dark"

-- Every control holds a whole style tag, applied as is; UNSET applies none.
local UNSET = ""

--* VideFoundation.Enums has no ShadowPreset; these are its values.
local SHADOW_PRESETS = { "raised-100", "raised-300", "overlay-100", "overlay-300" }

local COLOR_MODES: { ColorMode } = { ColorMode.Light, ColorMode.Dark }

local function shadowTag(preset: string): string
	return `shadow-{preset}`
end

local GROUP_TRANSPARENCY_OPTIONS = { 0, 0.25, 0.5, 0.75, 1 }
local BACKGROUND_OPTIONS = { "bg-surface-200", UNSET, "bg-surface-0", "bg-surface-100", "bg-surface-300" }
local RADIUS_OPTIONS = {
	UNSET,
	"radius-none",
	"radius-xsmall",
	"radius-small",
	"radius-medium",
	"radius-large",
	"radius-circle",
}
local STROKE_OPTIONS = {
	UNSET,
	"stroke-standard",
	"stroke-emphasis",
	"stroke-muted",
	"stroke-default",
	"stroke-system-neutral",
	"stroke-system-emphasis",
}
local SHADOW_OPTIONS = { UNSET }
for _, preset in SHADOW_PRESETS do
	table.insert(SHADOW_OPTIONS, shadowTag(preset))
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.View({
		GroupTransparency = controls.GroupTransparency,
		tag = function()
			local background, radius, stroke, shadow =
				controls.background(), controls.radius(), controls.stroke(), controls.shadow()
			return {
				["row align-x-center align-y-center size-2500"] = true,
				[background] = background ~= UNSET,
				[radius] = radius ~= UNSET,
				[stroke] = stroke ~= UNSET,
				[shadow] = shadow ~= UNSET,
			}
		end,
		children = VF.Text({
			Text = "View",
			tag = "auto-xy text-title-medium content-emphasis",
			LayoutOrder = 1,
		}),
	})
end

local function ShadowCard(props: { LayoutOrder: number, preset: string })
	return VF.View({
		tag = "col align-x-center gap-xxlarge auto-xy padding-x-xxlarge",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = shadowTag(props.preset),
				tag = "auto-xy padding-bottom-xxlarge text-label-small content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = `size-3000 radius-large bg-surface-200 {shadowTag(props.preset)}`,
				LayoutOrder = 2,
			}),
		},
	})
end

local function ShadowPanel(props: { LayoutOrder: number, colorMode: ColorMode })
	local tokens = VF.Hooks.useTokens()

	local function size(token: string): () -> UDim
		return function()
			return UDim.new(0, (tokens().Size :: any)[token])
		end
	end

	--* Each panel has its own StyleProvider, so its StyleLink styles this subtree in its own color mode.
	return VF.View({
		tag = "auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = StyleProvider({
			colorMode = props.colorMode,
			children = function()
				local cards = {}
				for index, preset in SHADOW_PRESETS do
					cards[index] = ShadowCard({ LayoutOrder = index, preset = preset })
				end

				return VF.View({
					tag = "col align-x-left gap-xxlarge auto-xy radius-large bg-surface-200",
					--* Overlay300 drops 48px with a 56px blur, more than the 32px padding tags reach below the cards.
					padding = {
						top = size("Size_800"),
						left = size("Size_800"),
						right = size("Size_800"),
						bottom = size("Size_2000"),
					},
					children = {
						VF.Text({
							Text = props.colorMode,
							tag = "auto-xy text-heading-medium content-emphasis",
							LayoutOrder = 1,
						}),
						VF.View({
							tag = "row align-y-center gap-xxlarge auto-xy",
							LayoutOrder = 2,
							children = cards,
						}),
					},
				})
			end,
		}),
	})
end

local function ShadowsStory()
	local panels = {}
	for index, colorMode in COLOR_MODES do
		panels[index] = ShadowPanel({ LayoutOrder = index, colorMode = colorMode })
	end
	return VF.View({
		tag = "row wrap align-x-center align-y-center gap-xxlarge auto-xy padding-xxlarge",
		children = panels,
	})
end

return foundation.sections({
	summary = "View",
	controls = {
		GroupTransparency = UILabs.Choose(GROUP_TRANSPARENCY_OPTIONS),
		background = UILabs.Choose(BACKGROUND_OPTIONS),
		radius = UILabs.Choose(RADIUS_OPTIONS),
		stroke = UILabs.Choose(STROKE_OPTIONS),
		shadow = UILabs.Choose(SHADOW_OPTIONS),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Shadows",
			summary = "Elevation shadow style tags applied to View via the tag prop, in light and dark side by side",
			story = ShadowsStory,
		},
	},
})
