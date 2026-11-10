local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
type IconVariant = BuilderIcons.IconVariant

local ColorNamespace = require("../../Enums/ColorNamespace")
local Constants = require("../../Constants")
local Icon = require("../Icon")
local InputSize = require("../../Enums/InputSize")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local blendTransparencies = require("../../Utility/blendTransparencies")
local useKnobVariants = require("./useKnobVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InputSize = InputSize.InputSize
type ColorStyleValue = Types.ColorStyleValue
type Stroke = Types.Stroke
type Value<T> = Types.Value<T>

export type KnobIcon = { name: string, variant: IconVariant }

export type KnobProps = {
	size: Value<InputSize>?,
	style: Types.ColorStyle?,
	stroke: Value<Stroke?>?,
	hasShadow: Value<boolean>?,
	-- Icon rendered instead of the default knob circle.
	icon: Value<KnobIcon?>?,
	isDisabled: Value<boolean>?,
} & Types.CommonProps

local defaultProps = {
	size = InputSize.Medium,
	hasShadow = true,
	isDisabled = false,
	testId = "--foundation-knob",
}

local SHADOW_TAG = "position-center-center anchor-center-center radius-circle shadow-raised-100"

--- The round handle of Toggle and Slider: a circle (or an icon) over a raised shadow.
local function Knob(knobProps: KnobProps): GuiObject
	local props = withDefaults(knobProps, defaultProps)
	local tokens = useTokens()
	local isInverse = PresentationContext.usePresentationContext().colorNamespace == ColorNamespace.Inverse

	local function size(): InputSize
		return Value.read(props.size)
	end
	local function isDisabled(): boolean
		return Value.read(props.isDisabled) == true
	end
	local function stroke(): Stroke?
		return Value.read(props.stroke)
	end

	local variantProps = Vide.derive(function()
		return useKnobVariants(tokens(), size(), isInverse)
	end)

	local function knobStyle(): ColorStyleValue
		return Value.read(props.style) or variantProps().knob.style
	end
	local function knobTransparency(): number
		return knobStyle().Transparency or 0
	end

	local function circleSize(): UDim2
		local knobSize = variantProps().knob.size
		local current = stroke()
		local thickness: number? = if current then Value.read(current.Thickness) else nil
		if thickness then
			return knobSize - UDim2.fromOffset(thickness * 2, thickness * 2)
		end
		return knobSize
	end

	local function circle(): GuiObject
		local view = View({
			tag = function()
				return variantProps().knob.tag
			end,
			backgroundStyle = function(): ColorStyleValue
				local style = knobStyle()
				if isDisabled() then
					return {
						Color3 = style.Color3,
						Transparency = blendTransparencies(style.Transparency, Constants.DISABLED_TRANSPARENCY),
					}
				end
				return style
			end,
			Size = circleSize,
			stroke = if props.stroke ~= nil
				then function(): Stroke?
					local current = stroke()
					if current and isDisabled() then
						local transparency: number? = Value.read(current.Transparency)
						if transparency ~= nil then
							local disabled = table.clone(current)
							disabled.Transparency = blendTransparencies(transparency, Constants.DISABLED_TRANSPARENCY)
							return disabled
						end
					end
					return current
				end
				else nil,
			ZIndex = 4,
			testId = `{props.testId}--circle`,
		})
		view.Name = "Icon"
		return view
	end

	local function iconContainer(icon: () -> KnobIcon): GuiObject
		local glyph = Icon({
			name = function()
				return icon().name
			end,
			variant = function()
				return icon().variant
			end,
			style = function(): ColorStyleValue
				local style = variantProps().knob.style
				if isDisabled() then
					return {
						Color3 = style.Color3,
						Transparency = blendTransparencies(style.Transparency, Constants.DISABLED_TRANSPARENCY),
					}
				end
				return style
			end,
			size = function()
				return variantProps().knob.iconSize
			end,
			testId = `{props.testId}--icon`,
		})
		glyph.Name = "Children"
		local view = View({
			tag = function()
				return variantProps().knob.tag
			end,
			Size = circleSize,
			ZIndex = 4,
			backgroundStyle = function()
				return variantProps().iconContainer.backgroundStyle
			end,
			children = glyph,
		})
		view.Name = "Icon"
		return view
	end

	--* Foundation renders the shadow as a CanvasGroup only while the knob is translucent, like any View whose
	--* GroupTransparency is a plain number.
	local function shadow(isTranslucent: boolean): GuiObject
		local view = View({
			tag = SHADOW_TAG,
			GroupTransparency = if isTranslucent then knobTransparency else nil,
			Size = circleSize,
			Visible = function()
				return knobTransparency() < 1
			end,
			ZIndex = 3,
			testId = `{props.testId}--shadow`,
		})
		view.Name = "Shadow"
		return view
	end

	local getIcon: () -> KnobIcon? = function()
		return Value.read(props.icon)
	end

	return View(withCommonProps(props, {
		Size = function()
			return variantProps().knob.size
		end,
		isDisabled = props.isDisabled,
		children = {
			Vide.show(getIcon, iconContainer, circle),
			Vide.show(function()
				return Value.read(props.hasShadow) and not isDisabled()
			end, function()
				return Vide.switch(function()
					return knobTransparency() > 0
				end)({
					[true] = function()
						return shadow(true)
					end,
					[false] = function()
						return shadow(false)
					end,
				})
			end),
		},
	}) :: any)
end

return Knob
