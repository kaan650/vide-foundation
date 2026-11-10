local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
local CloseAffordanceVariant = require("../../Enums/CloseAffordanceVariant")
local Constants = require("../../Constants")
local Icon = require("../Icon")
local InputSize = require("../../Enums/InputSize")
local Padding = require("../Padding")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local rebuildOn = require("../../Utility/rebuildOn")
local useCloseAffordanceVariants = require("./useCloseAffordanceVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type CloseAffordanceVariant = CloseAffordanceVariant.CloseAffordanceVariant
type Value<T> = Types.Value<T>

export type CloseAffordanceSize = typeof(InputSize.XSmall) | typeof(InputSize.Small) | typeof(InputSize.Medium)

export type CloseAffordanceProps = {
	onActivated: () -> (),
	isDisabled: Value<boolean>?,
	size: Value<CloseAffordanceSize>?,
	variant: Value<CloseAffordanceVariant>?,
	isCircular: Value<boolean>?,
	hasPadding: Value<boolean>?,
} & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	isDisabled = false,
	size = InputSize.Medium,
	variant = CloseAffordanceVariant.OverMedia,
	isCircular = false,
	hasPadding = true,
	testId = "--foundation-close-affordance",
}

--- The X button that closes a dialog, sheet or toast. A source `isDisabled` returns a source of the instance: a
--- disabled button is a CanvasGroup, so it is rebuilt when the value changes, as React remounts it.
local function CloseAffordance(closeAffordanceProps: CloseAffordanceProps): GuiObject | () -> GuiObject
	local props = withDefaults(closeAffordanceProps, defaultProps)
	local tokens = useTokens()
	local colorNamespace = PresentationContext.usePresentationContext().colorNamespace

	local variantProps = Vide.derive(function()
		return useCloseAffordanceVariants(
			tokens(),
			Value.read(props.size),
			Value.read(props.variant),
			colorNamespace,
			Value.read(props.hasPadding) == true,
			Value.read(props.isCircular) == true
		)
	end)

	local function radius(): UDim
		return UDim.new(0, variantProps().container.radius)
	end

	local function build(isDisabled: boolean?): GuiObject
		local icon = Icon({
			name = BuilderIcons.Icon.X,
			variant = BuilderIcons.IconVariant.Regular,
			size = function()
				return variantProps().content.iconSize
			end,
			style = function()
				return variantProps().content.style
			end,
		})
		icon.Name = "Icon"

		return View(withCommonProps(props, {
			--* Without a handler (a disabled InputChip) the button is a plain Frame, as in Foundation.
			onActivated = if props.onActivated
				then function()
					props.onActivated()
				end
				else nil,
			selection = {
				Selectable = if isDisabled then false else props.Selectable,
				NextSelectionUp = props.NextSelectionUp,
				NextSelectionDown = props.NextSelectionDown,
				NextSelectionLeft = props.NextSelectionLeft,
				NextSelectionRight = props.NextSelectionRight,
			},
			isDisabled = isDisabled,
			cornerRadius = radius,
			stateLayer = {
				mode = function()
					local stateLayer = variantProps().container.stateLayer
					return if stateLayer then Value.read(stateLayer.mode) else nil
				end,
			},
			cursor = function()
				return {
					radius = radius(),
					offset = tokens().Size.Size_150,
					borderWidth = tokens().Stroke.Thicker,
				}
			end,
			tag = function()
				return variantProps().container.tag
			end,
			GroupTransparency = if isDisabled then Constants.DISABLED_TRANSPARENCY else nil,
			children = {
				Value.bindProperty("Size", function()
					return variantProps().container.size
				end),
				Vide.show(function()
					return variantProps().container.padding
				end, function(value: () -> UDim)
					local padding = Padding({ value = value, testId = `{props.testId}--padding` })
					padding.Name = "Padding"
					return padding
				end),
				icon,
			},
		}) :: any)
	end

	return rebuildOn(props.isDisabled, build)
end

return CloseAffordance
