local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local ColorNamespace = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ColorNamespace")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local PresentationContext =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Providers/Style/PresentationContext")

type ColorStyleValue = VideFoundation.ColorStyleValue
type InputSize = InputSize.InputSize
type Value<T> = VideFoundation.Value<T>

local SIZES: { InputSize } = { InputSize.Large, InputSize.Medium, InputSize.Small, InputSize.XSmall }

type StoryProps = {
	style: VideFoundation.ColorStyle?,
	stroke: Value<any>?,
	hasShadow: Value<boolean>?,
	icon: { name: string, variant: string }?,
	isDisabled: Value<boolean>?,
}

local function Story(props: StoryProps)
	local knobs = {}
	for index, size in SIZES do
		knobs[index] = VF.Knob({
			size = size,
			style = props.style,
			stroke = props.stroke,
			hasShadow = props.hasShadow,
			icon = props.icon :: any,
			isDisabled = props.isDisabled,
			LayoutOrder = index,
		})
	end
	return VF.View({
		tag = "row align-y-center gap-medium size-full-0 auto-y",
		children = knobs,
	})
end

--- The story's surface with `build` inside a PresentationContext that follows the isInverse control.
--* Foundation's story provides `{ isInverse = ... }`, a field its PresentationContext does not have, so its knobs
--* never turn inverse. Here isInverse sets the Inverse color namespace, as the story's summary describes.
local function Surface(controls: { [string]: any }, inverseBackground: boolean, build: () -> any)
	local tokens = VF.Hooks.useTokens()

	return VF.View({
		tag = "align-y-center gap-medium auto-xy padding-medium radius-medium",
		backgroundStyle = function(): any
			if controls.isInverse() == inverseBackground then
				return tokens().Inverse.Surface.Surface_0 :: ColorStyleValue
			end
			return nil
		end,
		--* PresentationContext holds a plain value, so a change builds the knobs again.
		children = foundation.rebuildOn(controls.isInverse, function(isInverse: boolean)
			return PresentationContext.context({
				isIconSize = false,
				colorNamespace = if isInverse then ColorNamespace.Inverse else ColorNamespace.Color,
			}, build) :: any
		end),
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return Surface(controls, true, function()
		return VF.Knob({
			size = controls.size,
			hasShadow = controls.hasShadow,
			isDisabled = controls.isDisabled,
		})
	end)
end

local function SizesStory(controls: { [string]: any })
	return Surface(controls, true, function()
		return Story({
			hasShadow = controls.hasShadow,
			isDisabled = controls.isDisabled,
		})
	end)
end

local function WithStrokeStory(controls: { [string]: any })
	local tokens = VF.Hooks.useTokens()

	return Surface(controls, true, function()
		return Story({
			style = function(): ColorStyleValue
				return tokens().Color.None :: ColorStyleValue
			end,
			stroke = function()
				local emphasis = if controls.isInverse()
					then tokens().Inverse.Content.Emphasis
					else tokens().Color.Content.Emphasis
				return {
					Color = emphasis.Color3,
					Thickness = tokens().Stroke.Thicker,
					Transparency = emphasis.Transparency,
				}
			end,
			hasShadow = controls.hasShadow,
			isDisabled = controls.isDisabled,
		})
	end)
end

local function WithIconStory(controls: { [string]: any })
	return Surface(controls, false, function()
		return Story({
			hasShadow = controls.hasShadow,
			isDisabled = controls.isDisabled,
			icon = {
				name = VF.Enums.IconName.Check,
				variant = VF.Enums.IconVariant.Regular,
			},
		})
	end)
end

return foundation.sections({
	summary = "Interactive circular handle used by higher-level inputs (e.g., Slider and Toggle). Typically composed by parent controls rather than used directly. Uses PresentationContext for inverse styling.",
	controls = {
		isInverse = false,
		hasShadow = true,
		isDisabled = false,
		size = UILabs.Choose(Dash.values(InputSize :: any)),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizes", summary = "Default knob across sizes.", story = SizesStory },
		{
			name = "With Stroke",
			summary = "Knob with transparent fill and emphasis stroke across sizes.",
			story = WithStrokeStory,
		},
		{
			name = "With Icon",
			summary = "Knob rendering a BuilderIcons check icon instead of the circle.",
			story = WithIconStory,
		},
	},
})
