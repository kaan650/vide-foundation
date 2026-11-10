local Vide = require("../../Packages/Vide")

local ButtonIcon = require("./ButtonIcon")
local ButtonVariant = require("../../Enums/ButtonVariant")
local Constants = require("../../Constants")
local ControlState = require("../../Enums/ControlState")
local FillBehavior = require("../../Enums/FillBehavior")
local InputSize = require("../../Enums/InputSize")
local Motion = require("../../Utility/Motion")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local Spinner = require("./Spinner")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local create = require("../../Utility/create")
local endAlignedIcons = require("./endAlignedIcons")
local iconMigrationUtils = require("../../Utility/iconMigrationUtils")
local useButtonMotionStates = require("./useButtonMotionStates")
local useButtonVariants = require("./useButtonVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ButtonVariant = ButtonVariant.ButtonVariant
type SupportedButtonVariant = ButtonVariant.SupportedButtonVariant
type ControlState = ControlState.ControlState
type FillBehavior = FillBehavior.FillBehavior
type InputSize = InputSize.InputSize
type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

local BUTTON_VARIANT_TO_RICH_TEXT_FORMAT: { [string]: { format: string, controlState: { ControlState } } } = {
	[ButtonVariant.Link] = {
		format = "<u>%s</u>",
		controlState = { ControlState.Hover, ControlState.Pressed },
	},
}

local function onProgressChange(progress: number): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(math.max(0, progress - 0.0001), 0),
		NumberSequenceKeypoint.new(math.min(1, progress + 0.0001), Constants.DISABLED_TRANSPARENCY),
		NumberSequenceKeypoint.new(1, Constants.DISABLED_TRANSPARENCY),
	})
end

local function getTransparency(transparency: number?, disabledValue: number): number
	if transparency ~= nil then
		return transparency + (1 - transparency) * disabledValue
	end
	return disabledValue
end

export type ButtonProps = {
	text: Value<string?>?,
	icon: Value<string?>?,
	onActivated: () -> (),
	isDisabled: Value<boolean>?,
	isLoading: Value<boolean>?,
	-- Officially supported variants are Standard, Emphasis, SoftEmphasis, Alert and Utility.
	variant: Value<SupportedButtonVariant>?,
	size: Value<InputSize>?,
	-- Width of the button. `fillBehavior` is preferred and works better with flex layouts.
	width: Value<UDim>?,
	fillBehavior: Value<FillBehavior?>?,
	-- Seconds before the button is enabled. Only visible on variants with a filled background.
	inputDelay: Value<number>?,
} & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	isDisabled = false,
	isLoading = false,
	variant = ButtonVariant.Standard,
	size = InputSize.Medium,
	width = UDim.new(0, 0),
	inputDelay = 0,
	testId = "--foundation-button",
}

local function Button(buttonProps: ButtonProps): GuiObject
	local props = withDefaults(buttonProps, defaultProps)
	local tokens = useTokens()
	local colorNamespace = PresentationContext.usePresentationContext().colorNamespace

	local function variant(): SupportedButtonVariant
		return Value.read(props.variant)
	end
	local function size(): InputSize
		return Value.read(props.size)
	end
	local function width(): UDim
		return Value.read(props.width)
	end
	local function fillBehavior(): FillBehavior?
		return Value.read(props.fillBehavior)
	end
	local function text(): string?
		return Value.read(props.text)
	end
	local function icon(): string?
		return Value.read(props.icon)
	end
	local function isLoading(): boolean
		return Value.read(props.isLoading) == true
	end
	local function isDisabled(): boolean
		return Value.read(props.isDisabled) == true
	end

	local variantProps = Vide.derive(function()
		return useButtonVariants(tokens(), size(), variant(), colorNamespace)
	end)

	local controlState = Vide.source(ControlState.Initialize :: ControlState)

	local isDelaying = Vide.source(Vide.untrack(function(): boolean
		return Value.read(props.inputDelay) > 0
	end))
	local progress, setProgressGoal = Motion.useAnimatedBinding(0, function()
		isDelaying(false)
	end)
	Vide.effect(function()
		local inputDelay: number = Value.read(props.inputDelay)
		Vide.untrack(function()
			if inputDelay > 0 then
				isDelaying(true)
				setProgressGoal(Motion.ease(1, { duration = inputDelay, easingStyle = Enum.EasingStyle.Quad }))
			else
				isDelaying(false)
			end
		end)
	end)
	Vide.effect(function()
		if not isDelaying() then
			Vide.untrack(function()
				setProgressGoal(Motion.instant(0))
			end)
		end
	end)

	local function motionStates()
		return useButtonMotionStates(variantProps().content.style.Transparency, Constants.DISABLED_TRANSPARENCY)
	end
	local initialStates = Vide.untrack(motionStates)
	local disabledValues, animateDisabledValues = Motion.useMotion(initialStates.Default :: any)
	local values, animate = Motion.useMotion(initialStates.Default :: any)
	Vide.effect(function()
		local loading = isLoading()
		Vide.untrack(function()
			animate((if loading then motionStates().Loading else motionStates().Default) :: any)
		end)
	end)
	Vide.effect(function()
		local disabled = isDisabled()
		Vide.untrack(function()
			animateDisabledValues((if disabled then motionStates().Disabled else motionStates().Default) :: any)
		end)
	end)

	local function hasText(): boolean
		local value = text()
		return value ~= nil and value ~= ""
	end

	local function contentColor(): Color3?
		return variantProps().content.style.Color3
	end

	--* Whether the button has a background or stroke depends on the variant, so a variant source makes both reactive.
	local isVariantStatic = type(props.variant) ~= "function"
	local initialContainer = Vide.untrack(variantProps).container
	local hasBackground = not isVariantStatic or initialContainer.style ~= nil

	local function stroke(): Types.Stroke?
		local variantStroke = variantProps().container.stroke
		if not variantStroke then
			return nil
		end
		return {
			Color = variantStroke.Color,
			Transparency = getTransparency(variantStroke.Transparency, disabledValues.transparency()),
		}
	end

	local isWidthStatic = type(props.width) ~= "function"
	local function automaticSize(): Enum.AutomaticSize
		local resolved = width()
		return if resolved.Scale == 0 and resolved.Offset == 0 then Enum.AutomaticSize.X else Enum.AutomaticSize.None
	end

	local iconKind = Vide.derive(function(): ("glyph" | "image")?
		local name = icon()
		if not name then
			return nil
		end
		return if iconMigrationUtils.isBuilderOrMigratedIcon(name) then "glyph" else "image"
	end)

	local function iconWrapper(isGlyph: boolean): GuiObject
		local wrapper = View({
			Size = function()
				return variantProps().icon.size
			end,
			LayoutOrder = function()
				local name = icon()
				return if name and endAlignedIcons[name] then 3 else 1
			end,
			testId = `{props.testId}--icon-wrapper`,
			children = ButtonIcon({
				icon = function()
					return icon() or ""
				end,
				isGlyph = isGlyph,
				size = size,
				iconSize = function()
					return variantProps().icon.size
				end,
				contentColor = contentColor,
				disabledTransparency = disabledValues.transparency,
				textTransparency = values.textTransparency,
				testId = props.testId,
			}),
		})
		wrapper.Name = "IconWrapper"
		return wrapper
	end

	local children = {
		Vide.show(isLoading, function()
			local spinner = Spinner({
				Size = function()
					return variantProps().icon.size
				end,
				style = function(): ColorStyleValue
					return { Color3 = contentColor(), Transparency = disabledValues.transparency() }
				end,
				testId = `{props.testId}--spinner`,
			})
			spinner.Name = "Spinner"
			return create("Folder")({ Name = "Loading", spinner })
		end),
		Vide.switch(iconKind)({
			glyph = function()
				return iconWrapper(true)
			end,
			image = function()
				return iconWrapper(false)
			end,
		}),
		Vide.show(hasText, function()
			local label = Text({
				Text = function()
					local format = BUTTON_VARIANT_TO_RICH_TEXT_FORMAT[variant()]
					local value = text()
					if value and format and table.find(format.controlState, controlState()) then
						return format.format:format(value)
					end
					return value or ""
				end,
				RichText = function()
					return BUTTON_VARIANT_TO_RICH_TEXT_FORMAT[variant()] ~= nil
				end,
				tag = function()
					return variantProps().text.tag
				end,
				textStyle = function(): ColorStyleValue
					return {
						Color3 = contentColor(),
						Transparency = values.textTransparency() + disabledValues.transparency(),
					}
				end,
				LayoutOrder = 2,
				testId = `{props.testId}--text`,
			})
			label.Name = "Text"
			return label
		end),
		Vide.show(isDelaying, function()
			return create("UIGradient")({
				Name = "Gradient",
				Transparency = function()
					return onProgressChange(progress())
				end,
			})
		end),
	}

	return View(withCommonProps(props, {
		AutomaticSize = if isWidthStatic
			then (if automaticSize() == Enum.AutomaticSize.X then Enum.AutomaticSize.X else nil)
			else automaticSize,
		cornerRadius = function()
			return UDim.new(0, variantProps().container.radius)
		end,
		backgroundStyle = if hasBackground
			then function(): ColorStyleValue?
				local style = variantProps().container.style
				if not style then
					return nil
				end
				return {
					Color3 = style.Color3,
					Transparency = getTransparency(style.Transparency, disabledValues.transparency()),
				}
			end
			else nil,
		flexItem = if type(props.fillBehavior) == "function"
			then function(): Types.FlexItem?
				local behavior = fillBehavior()
				if behavior == nil then
					return nil
				end
				return {
					FlexMode = if behavior == FillBehavior.Fill then Enum.UIFlexMode.Fill else Enum.UIFlexMode.Shrink,
				}
			end
			elseif props.fillBehavior ~= nil then {
				FlexMode = if props.fillBehavior == FillBehavior.Fill
					then Enum.UIFlexMode.Fill
					else Enum.UIFlexMode.Shrink,
			}
			else nil,
		stroke = if not isVariantStatic
			then stroke
			elseif initialContainer.stroke then {
				Color = function()
					return (stroke() :: Types.Stroke).Color
				end,
				Transparency = function()
					return (stroke() :: Types.Stroke).Transparency
				end,
			}
			else nil,
		Size = function()
			local isFill = fillBehavior() == FillBehavior.Fill
			local resolved = width()
			return UDim2.new(
				if isFill then 1 else resolved.Scale,
				if isFill then 0 else resolved.Offset,
				0,
				variantProps().container.height
			)
		end,
		--* Focus stays allowed while inputDelay or isLoading is what disables the button.
		selection = {
			Selectable = function()
				return if isDisabled() then false else Value.read(props.Selectable) ~= false
			end,
			NextSelectionUp = props.NextSelectionUp,
			NextSelectionDown = props.NextSelectionDown,
			NextSelectionLeft = props.NextSelectionLeft,
			NextSelectionRight = props.NextSelectionRight,
		},
		cursor = function()
			return {
				radius = UDim.new(0, variantProps().container.radius),
				offset = tokens().Size.Size_200,
				borderWidth = tokens().Stroke.Thicker,
			}
		end,
		onActivated = function()
			props.onActivated()
		end,
		onStateChanged = function(newState: ControlState)
			controlState(newState)
		end,
		isDisabled = function()
			return isDisabled() or isLoading() or isDelaying()
		end,
		stateLayer = {
			mode = function()
				local stateLayer = variantProps().container.stateLayer
				return if stateLayer then Value.read(stateLayer.mode) else nil
			end,
		},
		tag = function()
			return variantProps().container.tag
		end,
		children = children,
	}) :: any)
end

return Button
