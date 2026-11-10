local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")

local Accessory = require("./Accessory")
local ChipSize = require("../../Enums/ChipSize")
local ChipVariant = require("../../Enums/ChipVariant")
local ColorNamespace = require("../../Enums/ColorNamespace")
local Constants = require("../../Constants")
local IconPosition = require("../../Enums/IconPosition")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local StateLayerMode = require("../../Enums/StateLayerMode")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local useChipVariants = require("./useChipVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type Accessory = Accessory.Accessory
type ChipSize = ChipSize.ChipSize
type ChipVariant = ChipVariant.ChipVariant
type IconPosition = IconPosition.IconPosition
type Value<T> = Types.Value<T>

-- DEPRECATED
type Icon = {
	name: string,
	position: IconPosition,
}

export type ChipProps = {
	text: Value<string?>?,
	leading: Value<(string | Accessory)?>?,
	trailing: Value<(string | Accessory)?>?,
	onActivated: () -> (),
	isChecked: Value<boolean>?,
	size: Value<ChipSize>?,
	variant: Value<ChipVariant>?,
	isDisabled: Value<boolean>?,
	-- DEPRECATED
	icon: Value<(string | Icon)?>?,
} & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	isChecked = false,
	Selectable = true,
	isDisabled = false,
	size = ChipSize.Medium,
	variant = ChipVariant.Standard,
	testId = "--foundation-chip",
}

local CHECKED_CONTEXT: PresentationContext.PresentationContextValue = {
	colorNamespace = ColorNamespace.Inverse,
	isIconSize = true,
}
local UNCHECKED_CONTEXT: PresentationContext.PresentationContextValue = {
	colorNamespace = ColorNamespace.Color,
	isIconSize = true,
}

local function toConfig(value: (string | Accessory)?): Accessory?
	if type(value) == "string" then
		return { iconName = value, isCircular = false } :: Accessory
	end
	return value
end

--* Circular icons are drawn filled. A copy, where Foundation writes into the caller's table.
local function withFilledCircle(config: Accessory?): Accessory?
	if config and config.type == nil and config.isCircular then
		local filled = table.clone(config)
		filled.iconVariant = BuilderIcons.IconVariant.Filled
		return filled
	end
	return config
end

--- A rounded toggle with a label and optional leading and trailing accessories. A source `isDisabled` returns a
--- source of the instance: a disabled chip is a CanvasGroup, so it is rebuilt when the value changes.
local function Chip(chipProps: ChipProps): GuiObject | () -> GuiObject
	local props = withDefaults(chipProps, defaultProps)
	local tokens = useTokens()
	local testId = props.testId

	local function size(): ChipSize
		return Value.read(props.size)
	end
	local function isChecked(): boolean
		return Value.read(props.isChecked) == true
	end
	local function text(): string?
		return Value.read(props.text)
	end

	local accessories = Vide.derive(function(): { leading: Accessory?, trailing: Accessory? }
		local leading = toConfig(Value.read(props.leading))
		local trailing = toConfig(Value.read(props.trailing))

		-- Migration step for the deprecated `icon` prop
		local icon: (string | Icon)? = Value.read(props.icon)
		if icon ~= nil then
			if typeof(icon) == "string" then
				leading = { iconName = icon } :: Accessory
			else
				local config: Accessory = { iconName = icon.name } :: Accessory
				if icon.position == IconPosition.Left then
					leading = config
				else
					trailing = config
				end
			end
		end

		return { leading = withFilledCircle(leading), trailing = withFilledCircle(trailing) }
	end)
	local function leading(): Accessory?
		return accessories().leading
	end
	local function trailing(): Accessory?
		return accessories().trailing
	end

	local variantProps = Vide.derive(function()
		return useChipVariants(
			tokens(),
			size(),
			Value.read(props.variant),
			isChecked(),
			leading() ~= nil,
			trailing() ~= nil
		)
	end)

	local function contentStyle()
		return variantProps().text.contentStyle
	end
	local function chipBackgroundStyle()
		return variantProps().chip.backgroundStyle
	end

	local function content(isDisabled: boolean): { any }
		local function accessory(name: string, config: () -> Accessory?, isLeading: boolean, suffix: string)
			return Vide.show(config, function(current: () -> Accessory)
				return named(
					name,
					Accessory({
						isLeading = isLeading,
						config = current,
						size = size,
						chipBackgroundStyle = chipBackgroundStyle,
						contentStyle = contentStyle,
						isDisabled = isDisabled,
						testId = `{testId}--{suffix}`,
					})
				)
			end)
		end

		return {
			accessory("Leading", leading, true, "leading-accessory"),
			Vide.show(function()
				local value = text()
				return value ~= nil and value ~= ""
			end, function()
				return named(
					"Text",
					Text({
						Text = function()
							return text() or ""
						end,
						textStyle = contentStyle,
						LayoutOrder = 2,
						tag = function()
							return variantProps().text.tag
						end,
						padding = {
							left = function()
								return variantProps().text.padding.left or UDim.new()
							end,
							right = function()
								return variantProps().text.padding.right or UDim.new()
							end,
						},
						testId = `{testId}--text`,
					})
				)
			end),
			accessory("Trailing", trailing, false, "trailing-accessory"),
		}
	end

	local function build(isDisabled: boolean): GuiObject
		--* The presentation context is a plain value, so the content is rebuilt when the chip is checked or unchecked.
		local children = Vide.switch(isChecked)({
			[true] = function()
				return PresentationContext.context(CHECKED_CONTEXT, function()
					return content(isDisabled)
				end)
			end,
			[false] = function()
				return PresentationContext.context(UNCHECKED_CONTEXT, function()
					return content(isDisabled)
				end)
			end,
		})

		return View(withCommonProps(props, {
			isDisabled = isDisabled,
			selection = {
				Selectable = if isDisabled then false else props.Selectable,
				NextSelectionUp = props.NextSelectionUp,
				NextSelectionDown = props.NextSelectionDown,
				NextSelectionLeft = props.NextSelectionLeft,
				NextSelectionRight = props.NextSelectionRight,
			},
			onActivated = function()
				props.onActivated()
			end,
			stateLayer = {
				mode = function()
					return if isChecked() then StateLayerMode.Inverse else nil
				end,
			},
			backgroundStyle = chipBackgroundStyle,
			cursor = function()
				local borderWidth = math.floor(tokens().Stroke.Thicker)
				return {
					radius = UDim.new(0, tokens().Radius.Circle),
					offset = borderWidth * 2,
					borderWidth = borderWidth,
				}
			end,
			tag = function()
				return variantProps().chip.tag
			end,
			GroupTransparency = if isDisabled then Constants.DISABLED_TRANSPARENCY else nil,
			children = children,
		}) :: any)
	end

	return rebuildOn(props.isDisabled, build)
end

return Chip
