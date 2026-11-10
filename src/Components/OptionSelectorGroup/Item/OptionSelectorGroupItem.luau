local Vide = require("../../../Packages/Vide")

local Constants = require("../../../Constants")
local FillBehavior = require("../../../Enums/FillBehavior")
local Icon = require("../../Icon")
local Image = require("../../Image")
local InputSize = require("../../../Enums/InputSize")
local Motion = require("../../../Utility/Motion")
local OptionSelectorGroupSize = require("../../../Enums/OptionSelectorGroupSize")
local Orientation = require("../../../Enums/Orientation")
local Text = require("../../Text")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local escapeRichText = require("../../../Utility/escapeRichText")
local iconMigrationUtils = require("../../../Utility/iconMigrationUtils")
local named = require("../../../Utility/named")
local useOptionSelectorGroup = require("../useOptionSelectorGroup")
local useOptionSelectorGroupItemMotionStates = require("./useOptionSelectorGroupItemMotionStates")
local useOptionSelectorGroupItemVariants = require("./useOptionSelectorGroupItemVariants")
local useTokens = require("../../../Providers/Style/useTokens")
local withCommonProps = require("../../../Utility/withCommonProps")
local withDefaults = require("../../../Utility/withDefaults")

type ColorStyleValue = Types.ColorStyleValue
type FillBehavior = FillBehavior.FillBehavior
type InputSize = InputSize.InputSize
type OptionSelectorGroupSize = OptionSelectorGroupSize.OptionSelectorGroupSize
type Orientation = Orientation.Orientation
type Value<T> = Types.Value<T>

export type OptionSelectorGroupItemProps = {
	-- A unique value for the option selector item. It also names the item's test id, so it is a plain string.
	value: string,
	-- An optional icon shown next to the label.
	icon: Value<string?>?,
	-- Whether the option selector item is disabled. When `true`, the `setValue` method
	-- will not be invoked, even if the user interacts with the option selector item.
	isDisabled: Value<boolean?>?,
	-- A label for the option selector item. Optional; defaults to `value` when omitted.
	label: Value<string?>?,
	-- Optional metadata to give additional details about the option selector item.
	metadata: Value<string?>?,
	-- Optional description to give more context about the option selector item.
	description: Value<string?>?,
	-- Size of the option selector item.
	-- **DEPRECATED**: Prefer `size` on `OptionSelectorGroup.Root`, which takes `OptionSelectorGroupSize`
	-- and cascades to the items. Used when Root omits `size`; `InputSize.Large` falls back to `Medium`.
	size: Value<InputSize>?,
	--! Ignored, as in Foundation.
	width: Value<UDim>?,
	-- How the item sizes along the group's main axis. Only applies to stacked-elements items
	-- (Horizontal group); defaults to Fit. Inline-elements items (Vertical group) always span
	-- the group width (Fill).
	-- **DEPRECATED**: Prefer `fillBehavior` on `OptionSelectorGroup.Root`, which cascades when Root sets it.
	fillBehavior: Value<FillBehavior?>?,
} & Types.CommonProps

local defaultProps = {
	isDisabled = false,
	size = InputSize.Medium :: InputSize,
}

local function getTransparency(transparency: number?, disabledValue: number): number
	if transparency ~= nil then
		return transparency + (1 - transparency) * disabledValue
	end
	return disabledValue
end

type IconKind = "glyph" | "image"

--- One option of an OptionSelectorGroup: a bordered button with an optional icon, a label, metadata and a
--- description. Create it inside the group's `children`. In a vertical group the icon sits beside the text, in a
--- horizontal group above it.
local function OptionSelectorGroupItem(optionSelectorGroupItemProps: OptionSelectorGroupItemProps): GuiObject
	local props = withDefaults(optionSelectorGroupItemProps, defaultProps)
	local group = useOptionSelectorGroup()
	local tokens = useTokens()
	local value = props.value
	local testId = `{group.testId}--item-{value}`
	props.testId = testId

	local function isSelected(): boolean
		return group.value() == value
	end
	local function isDisabled(): boolean
		return Value.read(props.isDisabled) == true
	end

	local function size(): OptionSelectorGroupSize
		local groupSize = group.size()
		if groupSize ~= nil then
			return groupSize
		end
		local itemSize: InputSize = Value.read(props.size)
		return if itemSize == InputSize.Large then OptionSelectorGroupSize.Medium else itemSize :: any
	end

	local function orientation(): Orientation
		return if group.orientation() == Orientation.Vertical then Orientation.Horizontal else Orientation.Vertical
	end

	local function fillBehavior(): FillBehavior
		if orientation() == Orientation.Horizontal then
			return FillBehavior.Fill
		end
		local groupFillBehavior = group.fillBehavior()
		local itemFillBehavior: FillBehavior? = if groupFillBehavior ~= nil
			then groupFillBehavior
			else Value.read(props.fillBehavior)
		return itemFillBehavior or FillBehavior.Fit
	end

	local function containerSize(): UDim2?
		local isStackedFit = orientation() == Orientation.Vertical and fillBehavior() == FillBehavior.Fit
		return if isStackedFit then nil else UDim2.fromScale(1, 0)
	end

	local variantProps = Vide.derive(function()
		return useOptionSelectorGroupItemVariants(tokens(), size(), orientation(), fillBehavior(), isSelected())
	end)

	local function contentColor(): Color3
		return variantProps().content.Color3 :: Color3
	end
	local function supportingContentColor(): Color3
		local supportingContent = variantProps().supportingContent
		return if supportingContent then supportingContent.Color3 :: Color3 else contentColor()
	end

	local motionStates =
		useOptionSelectorGroupItemMotionStates(Vide.untrack(tokens), 0, Constants.DISABLED_TRANSPARENCY)
	local disabledValues, animateDisabledValues = Motion.useMotion(motionStates.Default)
	local function disabledTransparency(): number
		return disabledValues.transparency()
	end
	Vide.effect(function()
		local disabled = isDisabled()
		Vide.untrack(function()
			animateDisabledValues(if disabled then motionStates.Disabled else motionStates.Default)
		end)
	end)

	local function contentStyle(color: () -> Color3): () -> ColorStyleValue
		return function()
			return { Color3 = color(), Transparency = disabledTransparency() }
		end
	end

	local function icon(): string?
		return Value.read(props.icon)
	end
	local iconKind = Vide.derive(function(): IconKind?
		local name = icon()
		if name == nil then
			return nil
		end
		--* UIBlox paths that have no Builder icon stay images at the token extent.
		return if iconMigrationUtils.isBuilderOrMigratedIcon(name) then "glyph" else "image"
	end)

	local leadingIcon = Vide.switch(iconKind)({
		image = function()
			return named(
				"Icon",
				Image({
					Image = function()
						return icon() or ""
					end,
					Size = function()
						local extent = variantProps().icon.extent
						return UDim2.fromOffset(extent, extent)
					end,
					imageStyle = contentStyle(contentColor),
					LayoutOrder = 1,
					testId = `{testId}--icon`,
				})
			)
		end,
		glyph = function()
			local function normalized(): iconMigrationUtils.NormalizedIconName
				return iconMigrationUtils.normalizeIconName(icon() or "")
			end
			return named(
				"Icon",
				Icon({
					name = function()
						return normalized().name
					end,
					size = function()
						return variantProps().icon.size
					end,
					style = contentStyle(contentColor),
					variant = function()
						return normalized().variant
					end :: any,
					LayoutOrder = 1,
					testId = `{testId}--icon`,
				})
			)
		end,
	})

	local function textChild(
		name: string,
		text: () -> string?,
		tagKey: "label" | "metadata" | "description",
		color: () -> Color3,
		layoutOrder: number,
		extra: { [string]: any }?
	)
		local function build(): GuiObject
			local textProps: Text.TextProps = {
				Text = function()
					return escapeRichText(text() or "")
				end,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				RichText = true,
				tag = function()
					return (variantProps() :: any)[tagKey].tag
				end,
				textStyle = contentStyle(color),
				LayoutOrder = layoutOrder,
				testId = `{testId}--{tagKey}`,
			}
			if extra then
				for key, extraValue in extra do
					(textProps :: any)[key] = extraValue
				end
			end
			return named(name, Text(textProps))
		end
		return Vide.show(function()
			return text() ~= nil
		end, build)
	end

	local body = View({
		tag = function()
			return variantProps().textContainer.tag
		end,
		LayoutOrder = 2,
		testId = `{testId}--body`,
		children = {
			textChild("Label", function()
				return Value.read(props.label) or value
			end, "label", contentColor, 1),
			textChild("Metadata", function()
				return Value.read(props.metadata)
			end, "metadata", supportingContentColor, 2, { TextTruncate = Enum.TextTruncate.None }),
			textChild("Description", function()
				return Value.read(props.description)
			end, "description", supportingContentColor, 3),
		},
	})
	body.Name = "Text"

	local itemInner = View({
		tag = function()
			return variantProps().itemInner.tag
		end,
		testId = `{testId}--content`,
		children = {
			Value.bindProperty("Size", containerSize),
			leadingIcon,
			body,
		},
	})
	itemInner.Name = "ItemInner"

	return View(withCommonProps(props, {
		stroke = {
			Color = function()
				return variantProps().container.stroke.Color3 :: Color3
			end,
			Transparency = function()
				return getTransparency(variantProps().container.stroke.Transparency, disabledTransparency())
			end,
		},
		selection = {
			Selectable = function()
				return if isDisabled() then false else Value.read(group.Selectable) ~= false
			end,
		},
		cursor = function(): Types.Cursor?
			return {
				radius = UDim.new(0, variantProps().container.radius),
				offset = tokens().Size.Size_200,
				borderWidth = tokens().Stroke.Thicker,
			}
		end,
		onActivated = function()
			group.onValueChanged(if group.value() == value then nil else value)
		end,
		isDisabled = isDisabled,
		tag = function()
			return variantProps().container.tag
		end,
		children = {
			Value.bindProperty("Size", containerSize),
			itemInner,
		},
	}) :: any)
end

return OptionSelectorGroupItem
