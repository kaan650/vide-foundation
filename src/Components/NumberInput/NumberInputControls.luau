local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
local Constants = require("../../Constants")
local Icon = require("../Icon")
local IconSize = require("../../Enums/IconSize")
local InputSize = require("../../Enums/InputSize")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local blendTransparencies = require("../../Utility/blendTransparencies")
local named = require("../../Utility/named")
local useNumberInputVariants = require("./useNumberInputVariants")
local useTokens = require("../../Providers/Style/useTokens")

type IconSize = IconSize.IconSize
type InputSize = InputSize.InputSize
type StateLayerAffordance = StateLayerAffordance.StateLayerAffordance
type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

type NumberInputControlProps = {
	isDisabled: Value<boolean>,
	onClick: () -> (),
}

export type NumberInputControlsProps = {
	-- Size of the controls
	size: Value<InputSize>,
	increment: NumberInputControlProps,
	decrement: NumberInputControlProps,
	hasDivider: boolean?,
	testId: string,
}

type IncrementButtonProps = {
	icon: string,
	iconSize: () -> IconSize,
	hasDivider: boolean?,
	isDisabled: Value<boolean>,
	onActivated: () -> (),
	radius: () -> number,
	size: () -> number,
	LayoutOrder: number,
	testId: string,
}

local function IncrementButton(props: IncrementButtonProps): GuiObject
	local tokens = useTokens()

	local function isDisabled(): boolean
		return Value.read(props.isDisabled) == true
	end
	local function radius(): UDim
		return UDim.new(0, props.radius())
	end

	return View({
		onActivated = function()
			props.onActivated()
		end,
		isDisabled = props.isDisabled,
		selection = {
			Selectable = function()
				return not isDisabled()
			end,
		},
		stateLayer = {
			affordance = function(): StateLayerAffordance
				return if isDisabled() then StateLayerAffordance.None else StateLayerAffordance.Background
			end,
		},
		cursor = function(): Types.Cursor
			return { radius = radius(), offset = tokens().Size.Size_150, borderWidth = tokens().Stroke.Thicker }
		end,
		cornerRadius = radius,
		Size = function()
			local size = props.size()
			return UDim2.fromOffset(size, size)
		end,
		LayoutOrder = props.LayoutOrder,
		testId = props.testId,
		children = {
			if props.hasDivider
				then named(
					"Divider",
					View({
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.fromScale(0, 0.5),
						Size = function()
							return UDim2.new(0, tokens().Stroke.Standard, 1, 0)
						end,
						backgroundStyle = function(): ColorStyleValue
							return tokens().Color.Stroke.Default :: any
						end,
						testId = `{props.testId}--divider`,
					})
				)
				else nil,
			named(
				"Icon",
				Icon({
					name = props.icon,
					size = props.iconSize,
					style = function(): ColorStyleValue
						local foreground = tokens().Color.ActionUtility.Foreground
						return {
							Color3 = foreground.Color3,
							Transparency = if isDisabled()
								then blendTransparencies(foreground.Transparency, Constants.DISABLED_TRANSPARENCY)
								else foreground.Transparency,
						}
					end,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					testId = `{props.testId}--icon`,
				})
			),
		},
	})
end

--- NumberInput's minus and plus buttons, side by side on a shared background.
local function NumberInputControls(props: NumberInputControlsProps): GuiObject
	local tokens = useTokens()
	local controls = Vide.derive(function()
		return useNumberInputVariants(tokens(), Value.read(props.size)).controls
	end)
	local function iconSize(): IconSize
		return controls().iconSize
	end
	local function radius(): number
		return controls().radius
	end
	local function buttonSize(): number
		return controls().buttonSize
	end

	return View({
		tag = function()
			return controls().tag
		end,
		Size = function()
			local current = controls()
			return UDim2.fromOffset(current.width, current.buttonSize)
		end,
		LayoutOrder = 1,
		testId = `{props.testId}--increment-buttons`,
		children = {
			named(
				"ControlDecrement",
				IncrementButton({
					icon = BuilderIcons.Icon.MinusSmall,
					iconSize = iconSize,
					isDisabled = props.decrement.isDisabled,
					onActivated = props.decrement.onClick,
					radius = radius,
					size = buttonSize,
					LayoutOrder = 1,
					testId = `{props.testId}--decrement`,
				})
			),
			named(
				"ControlIncrement",
				IncrementButton({
					icon = BuilderIcons.Icon.PlusSmall,
					iconSize = iconSize,
					hasDivider = props.hasDivider,
					isDisabled = props.increment.isDisabled,
					onActivated = props.increment.onClick,
					radius = radius,
					size = buttonSize,
					LayoutOrder = 2,
					testId = `{props.testId}--increment`,
				})
			),
		},
	})
end

return NumberInputControls
