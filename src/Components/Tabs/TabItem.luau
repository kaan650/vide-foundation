local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")

local Constants = require("../../Constants")
local FillBehavior = require("../../Enums/FillBehavior")
local Icon = require("../Icon")
local Image = require("../Image")
local InputSize = require("../../Enums/InputSize")
local StatusIndicator = require("../StatusIndicator")
local StatusIndicatorShape = require("../../Enums/StatusIndicatorShape")
local StatusIndicatorVariant = require("../../Enums/StatusIndicatorVariant")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local getIconScale = require("../../Utility/getIconScale")
local iconMigrationUtils = require("../../Utility/iconMigrationUtils")
local rebuildOn = require("../../Utility/rebuildOn")
local useTabItemVariants = require("./useTabItemVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")

type FillBehavior = FillBehavior.FillBehavior
type IconVariant = BuilderIcons.IconVariant
type InputSize = InputSize.InputSize
type ItemId = Types.ItemId
type StatusIndicatorShape = StatusIndicatorShape.StatusIndicatorShape
type StatusIndicatorVariant = StatusIndicatorVariant.StatusIndicatorVariant
type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

export type TabItemIcon = {
	name: string,
	variant: IconVariant?,
}

export type TabItemIndicator = {
	variant: StatusIndicatorVariant?,
	shape: StatusIndicatorShape?,
	value: Value<number?>?,
	max: number?,
}

export type TabItem = {
	id: ItemId,
	text: Value<string>,
	icon: Value<(string | TabItemIcon)?>?,
	indicator: Value<TabItemIndicator?>?,
	isDisabled: Value<boolean?>?,
	-- Builds what is shown under the tabs while this tab is active. Called each time the tab becomes active.
	content: (() -> Types.Children)?,
	-- Receives the tab's interactive area.
	ref: ((GuiObject) -> ())?,
}

export type TabItemProps = {
	tab: () -> TabItem,
	isActive: () -> boolean,
	isDisabled: Value<boolean>,
	onActivated: (id: ItemId) -> (),
	size: () -> InputSize,
	fillBehavior: () -> FillBehavior,
	-- Receives the interactive area of each instance the tab is built as.
	interactiveRef: (GuiObject) -> (),
} & Types.CommonProps

type IconKind = "Glyph" | "Image"

--- One tab of Tabs. A source `isDisabled` returns a source of the instance: a disabled tab is a CanvasGroup, so it
--- is rebuilt when the value changes, as React remounts it.
local function TabItem(props: TabItemProps): GuiObject | () -> GuiObject
	local tokens = useTokens()

	local variantProps = Vide.derive(function()
		return useTabItemVariants(tokens(), props.size(), props.fillBehavior() == FillBehavior.Fill)
	end)

	local function contentStyle(): ColorStyleValue
		local color = tokens().Color.Content
		return (if props.isActive() then color.Default else color.Emphasis) :: any
	end

	local icon = Vide.derive(function(): TabItemIcon?
		local value: (string | TabItemIcon)? = Value.read(props.tab().icon)
		if typeof(value) == "string" then
			return { name = value, variant = BuilderIcons.IconVariant.Regular }
		end
		return value
	end)

	local iconKind = Vide.derive(function(): IconKind?
		local current = icon()
		if not current then
			return nil
		elseif iconMigrationUtils.isBuilderOrMigratedIcon(current.name) then
			return "Glyph"
		end
		local intrinsicSize = getIconScale(current.name, variantProps().icon.size)
		return if intrinsicSize then "Image" else nil
	end)

	--! Effects of an icon can run once more after the icon was removed, before the icon is destroyed.
	local lastIcon: TabItemIcon = Vide.untrack(icon) or { name = "" }
	local function currentIcon(): TabItemIcon
		local current = icon()
		if current then
			lastIcon = current
		end
		return lastIcon
	end

	local function glyph(): GuiObject
		local function normalized(): TabItemIcon
			local current = currentIcon()
			return if iconMigrationUtils.isMigrated(current.name)
				then iconMigrationUtils.normalizeIconName(current.name)
				else current
		end
		return Icon({
			name = function()
				return normalized().name
			end,
			variant = function()
				return normalized().variant :: any
			end,
			size = function()
				return variantProps().icon.size
			end,
			style = contentStyle,
		})
	end

	local function image(): GuiObject
		local function scale(): (Vector2?, number)
			return getIconScale(currentIcon().name, variantProps().icon.size)
		end
		return Image({
			Image = function()
				return currentIcon().name
			end,
			Size = function()
				local intrinsicSize = scale()
				return if intrinsicSize then UDim2.fromOffset(intrinsicSize.X, intrinsicSize.Y) else UDim2.new()
			end,
			imageStyle = contentStyle,
			scale = function()
				local _, iconScale = scale()
				return iconScale
			end,
		})
	end

	local function indicator(): TabItemIndicator?
		return Value.read(props.tab().indicator)
	end

	local function content(): GuiObject
		local iconElement = Vide.switch(iconKind)({
			Glyph = function()
				local instance = glyph()
				instance.Name = "Icon"
				return instance
			end,
			Image = function()
				local instance = image()
				instance.Name = "Icon"
				return instance
			end,
		})

		local text = Text({
			Text = function()
				return Value.read(props.tab().text)
			end,
			tag = function()
				return variantProps().text.tag
			end,
			LayoutOrder = 2,
		})
		text.Name = "Text"

		local statusIndicator = Vide.show(function()
			return indicator() ~= nil
		end, function()
			--! The indicator's effects can run once more after it was removed, before it is destroyed.
			local last: TabItemIndicator = Vide.untrack(indicator) or {}
			local function field(key: string): () -> any
				return function()
					local current = indicator()
					if current then
						last = current
					end
					return Value.read((last :: any)[key])
				end
			end
			local instance = StatusIndicator({
				value = field("value"),
				variant = field("variant"),
				shape = field("shape"),
				max = field("max"),
				LayoutOrder = 3,
				testId = `{props.testId}--indicator`,
			})
			instance.Name = "Indicator"
			return instance
		end)

		local view = View({
			LayoutOrder = 2,
			tag = function()
				return variantProps().content.tag
			end,
			children = {
				Value.bindProperty("Size", function()
					return variantProps().content.Size
				end),
				iconElement,
				text,
				statusIndicator,
			},
		})
		view.Name = "Content"
		return view
	end

	local function build(isDisabled: boolean): GuiObject
		local interactive = View({
			LayoutOrder = 1,
			Size = UDim2.fromScale(1, 1),
			onActivated = function()
				props.onActivated(Vide.untrack(props.tab).id)
			end,
			selection = {
				Selectable = not isDisabled,
			},
			cursor = function()
				return {
					radius = UDim.new(0, 0),
					offset = 0,
					borderWidth = tokens().Stroke.Thicker,
				}
			end,
			isDisabled = isDisabled,
		})
		interactive.Name = "Interactive"
		props.interactiveRef(interactive)

		return View(withCommonProps(props, {
			tag = function()
				return variantProps().container.tag
			end,
			GroupTransparency = if isDisabled then Constants.DISABLED_TRANSPARENCY else nil,
			children = { interactive, content() },
		}) :: any)
	end

	return rebuildOn<<boolean>>(props.isDisabled, build)
end

return TabItem
