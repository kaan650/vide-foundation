local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
local ButtonVariant = require("../../Enums/ButtonVariant")
local Constants = require("../../Constants")
local FillBehavior = require("../../Enums/FillBehavior")
local IconSize = require("../../Enums/IconSize")
local Image = require("../Image")
local InputSize = require("../../Enums/InputSize")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local getIconScale = require("../../Utility/getIconScale")
local iconMigrationUtils = require("../../Utility/iconMigrationUtils")
local isBuilderIcon = require("../../Utility/isBuilderIcon")
local rebuildOn = require("../../Utility/rebuildOn")
local useIconButtonVariants = require("./useIconButtonVariants")
local useIconSize = require("../../Utility/useIconSize")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type IconVariant = BuilderIcons.IconVariant
type FillBehavior = FillBehavior.FillBehavior
type IconSize = IconSize.IconSize
type InputSize = InputSize.InputSize
type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

-- IconButton reuses the Button variant enum, with only these variants supported.
type SupportedIconButtonVariant =
	typeof(ButtonVariant.Standard)
	| typeof(ButtonVariant.Emphasis)
	| typeof(ButtonVariant.Utility)
	| typeof(ButtonVariant.OverMedia)
	| typeof(ButtonVariant.Alert)

export type IconButtonIcon = string | {
	name: string,
	variant: IconVariant?,
}

export type IconButtonProps = {
	onActivated: () -> (),
	isDisabled: Value<boolean>?,
	isCircular: Value<boolean>?,
	-- Size of IconButton. `IconSize` is deprecated - use `InputSize`.
	-- `Large` and `XLarge` `IconSize`s map to `InputSize.Large` and are not supported.
	size: Value<InputSize | IconSize>?,
	-- **DEPRECATED** Sets a custom width. Prefer wrapping in a fixed-width container and using `fillBehavior = Fill` instead.
	width: Value<UDim>?,
	-- **DEPRECATED** Controls how the IconButton fills space in a layout.
	fillBehavior: Value<FillBehavior?>?,
	variant: Value<SupportedIconButtonVariant>?,
	icon: Value<IconButtonIcon>,
} & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	isDisabled = false,
	size = InputSize.Medium,
	width = UDim.new(0, 0),
	isCircular = false,
	variant = ButtonVariant.Utility,
	testId = "--foundation-icon-button",
}

type IconKind = "builder" | "migrated" | "image"

--- A square button showing one icon. A source `isDisabled` returns a source of the instance: a disabled button is
--- a CanvasGroup, so it is rebuilt when the value changes, as React remounts it.
local function IconButton(iconButtonProps: IconButtonProps): GuiObject | () -> GuiObject
	local props = withDefaults(iconButtonProps, defaultProps)
	local tokens = useTokens()
	local colorNamespace = PresentationContext.usePresentationContext().colorNamespace
	local testId = props.testId

	local function size(): InputSize | IconSize
		return Value.read(props.size)
	end
	local function iconName(): string
		local icon: IconButtonIcon = Value.read(props.icon)
		return if typeof(icon) == "table" then icon.name else icon
	end
	local function iconVariant(): IconVariant?
		local icon: IconButtonIcon = Value.read(props.icon)
		return if typeof(icon) == "table" then icon.variant else nil
	end

	local variantProps = Vide.derive(function()
		return useIconButtonVariants(tokens(), size() :: InputSize, Value.read(props.variant), colorNamespace)
	end)

	local function radius(): UDim
		return if Value.read(props.isCircular)
			then UDim.new(0, tokens().Radius.Circle)
			else UDim.new(0, variantProps().container.radius or tokens().Radius.Large)
	end

	local function contentStyle(): ColorStyleValue
		return variantProps().content.style
	end

	local iconKind = Vide.derive(function(): IconKind
		local name = iconName()
		if isBuilderIcon(name) then
			return "builder"
		end
		return if iconMigrationUtils.isMigrated(name) then "migrated" else "image"
	end)

	local function glyph(kind: IconKind): GuiObject
		--* Migrated UIBlox names keep the image icon sizes, as in Foundation.
		local iconSize = useIconSize(size, kind == "builder", true)
		local function normalized(): (string, IconVariant?)
			local name = iconName()
			if iconMigrationUtils.isMigrated(name) then
				local migrated = iconMigrationUtils.normalizeIconName(name)
				return migrated.name, migrated.variant
			end
			return name, iconVariant() or BuilderIcons.IconVariant.Regular
		end
		local text = Text({
			Text = function()
				return (normalized())
			end,
			fontStyle = function()
				local _, variant = normalized()
				return {
					Font = if variant then (BuilderIcons.Font :: any)[variant] else nil,
					FontSize = iconSize().Y.Offset,
				}
			end,
			tag = "position-center-center anchor-center-center",
			Size = iconSize,
			textStyle = contentStyle,
			testId = `{testId}--icon`,
		})
		text.Name = "Icon"
		return text
	end

	local function image(): GuiObject
		local iconSize = useIconSize(size, false, true)
		local function scale(): (Vector2?, number)
			return getIconScale(iconName(), size() :: IconSize)
		end
		local instance = Image({
			tag = "position-center-center anchor-center-center",
			Image = iconName,
			Size = function()
				local intrinsic = scale()
				return if intrinsic then UDim2.fromOffset(intrinsic.X, intrinsic.Y) else iconSize()
			end,
			imageStyle = contentStyle,
			scale = function()
				local _, iconScale = scale()
				return iconScale
			end,
			testId = `{testId}--image`,
		})
		instance.Name = "Icon"
		return instance
	end

	local function build(isDisabled: boolean?): GuiObject
		return View(withCommonProps(props, {
			onActivated = function()
				props.onActivated()
			end,
			Size = function()
				local containerSize: UDim2 = variantProps().container.size
				local fillBehavior: FillBehavior? = Value.read(props.fillBehavior)
				local width: UDim = Value.read(props.width)
				local sizeX = if fillBehavior == FillBehavior.Fill
					then UDim.new(1, 0)
					elseif width.Scale ~= 0 or width.Offset ~= 0 then width
					else containerSize.X
				return UDim2.new(sizeX, UDim.new(0, containerSize.Y.Offset))
			end,
			flexItem = function(): Types.FlexItem?
				local fillBehavior: FillBehavior? = Value.read(props.fillBehavior)
				if fillBehavior == nil then
					return nil
				end
				return {
					FlexMode = if fillBehavior == FillBehavior.Fill
						then Enum.UIFlexMode.Fill
						else Enum.UIFlexMode.Shrink,
				}
			end,
			selection = {
				Selectable = if isDisabled then false else props.Selectable,
				NextSelectionUp = props.NextSelectionUp,
				NextSelectionDown = props.NextSelectionDown,
				NextSelectionLeft = props.NextSelectionLeft,
				NextSelectionRight = props.NextSelectionRight,
			},
			isDisabled = isDisabled,
			stateLayer = {
				mode = function()
					local stateLayer = variantProps().container.stateLayer
					return if stateLayer then Value.read(stateLayer.mode) else nil
				end,
			},
			padding = function()
				return variantProps().container.padding
			end,
			cornerRadius = radius,
			backgroundStyle = function()
				return variantProps().container.style
			end,
			stroke = function(): Types.Stroke?
				return variantProps().container.stroke
			end,
			cursor = function()
				return {
					radius = radius(),
					offset = tokens().Size.Size_150,
					borderWidth = tokens().Stroke.Thicker,
				}
			end,
			GroupTransparency = if isDisabled then Constants.DISABLED_TRANSPARENCY else nil,
			children = Vide.switch(iconKind)({
				builder = function()
					return glyph("builder")
				end,
				migrated = function()
					return glyph("migrated")
				end,
				image = image,
			}),
		}) :: any)
	end

	return rebuildOn(props.isDisabled, build)
end

return IconButton
