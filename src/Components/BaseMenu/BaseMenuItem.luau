local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
local Constants = require("../../Constants")
local Icon = require("../Icon")
local InputSize = require("../../Enums/InputSize")
local Logger = require("../../Utility/Logger")
local Popover = require("../Popover")
local PopoverAlign = require("../../Enums/PopoverAlign")
local PopoverSide = require("../../Enums/PopoverSide")
local Radius = require("../../Enums/Radius")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")

local Accessory = require("./BaseMenuItemAccessory")
local BaseMenuContext = require("./BaseMenuContext")
local BaseMenuScrollContainer = require("./BaseMenuScrollContainer")
local useBaseMenuItemVariants = require("./useBaseMenuItemVariants")
local useMenuItemHover = require("./useMenuItemHover")

type InputSize = InputSize.InputSize
type ColorStyleValue = Types.ColorStyleValue
type ItemId = Types.ItemId
type ListLayout = Types.ListLayout
type OnItemActivated = Types.OnItemActivated
type Value<T> = Types.Value<T>
type BaseMenuContextType = BaseMenuContext.BaseMenuContextType

export type LeadingAccessory = Accessory.LeadingAccessory
export type TrailingAccessory = Accessory.TrailingAccessory

export type BaseMenuItemProps = {
	id: ItemId,
	icon: Value<string?>?,
	leading: Value<(string | LeadingAccessory)?>?,
	trailing: Value<TrailingAccessory?>?,
	isChecked: Value<boolean?>?,
	isDisabled: Value<boolean?>?,
	text: Value<string>,
	onActivated: OnItemActivated?,
	size: Value<InputSize?>?,
	-- Builds the submenu's items (BaseMenu.Item, BaseMenu.Group) inside the submenu's context. Makes the item open
	-- a submenu.
	children: (() -> any)?,
	menuHasLeading: Value<boolean?>?,
	menuHasCheck: Value<boolean?>?,
	-- Receives the item's instance, again whenever it is rebuilt.
	ref: ((GuiObject) -> ())?,
} & Types.CommonProps

local function resolveAccessory(prop: (string | LeadingAccessory | TrailingAccessory)?): Accessory.Accessory?
	if prop == nil then
		return nil
	end
	if type(prop) == "string" then
		return { iconName = prop } :: LeadingAccessory
	end
	return prop
end

local function getInputSinkAll(): Enum.InputSink?
	local hasFeature, enabled = pcall(game.GetEngineFeature, game, "GuiObjectInputSink")
	if not hasFeature or not enabled then
		return nil
	end
	local ok, value = pcall(function()
		return (Enum :: any).InputSink.All
	end)
	return if ok then value else nil
end

local InputSinkAll = getInputSinkAll()

local CONTAINER_LAYOUT: ListLayout = {
	FillDirection = Enum.FillDirection.Horizontal,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 0),
	SortOrder = Enum.SortOrder.LayoutOrder,
}

--- A menu row: check column, leading accessory, text, trailing accessory. With `children` it opens a submenu on
--- hover or press, and returns the row (named "Item") with the submenu popover. A leaf returns the row: the instance,
--- or a source of it when `isDisabled` is a source, since a disabled row is a CanvasGroup.
local function BaseMenuItem(props: BaseMenuItemProps): any
	local context = BaseMenuContext()
	local tokens = useTokens()
	local depth = context.depth
	local isSubmenu = props.children ~= nil
	local testId = props.testId
	local isSubmenuScrollable = context.maxHeight ~= nil

	local function size(): InputSize
		return Value.read(props.size) or context.size()
	end

	local variantProps = Vide.derive(function()
		return useBaseMenuItemVariants(tokens(), size(), isSubmenuScrollable)
	end)

	local resolvedLeading = Vide.derive(function()
		return resolveAccessory(Value.read(props.leading) or Value.read(props.icon))
	end)

	local resolvedTrailing = Vide.derive(function()
		return resolveAccessory(Value.read(props.trailing))
	end)

	local function isChecked(): boolean
		return Value.read(props.isChecked) == true
	end

	local function isDisabled(): boolean
		return Value.read(props.isDisabled) == true
	end

	local function alignmentHasLeading(): boolean
		local menuHasLeading = Value.read(props.menuHasLeading)
		if menuHasLeading ~= nil then
			return menuHasLeading
		end
		return context.hasLeading ~= nil and context.hasLeading()
	end

	local function menuHasCheck(): boolean
		local value = Value.read(props.menuHasCheck)
		if value ~= nil then
			return value
		end
		return isChecked()
	end

	local isOpen = Vide.derive(function()
		return isSubmenu and context.hoverOpenPath()[depth] == props.id
	end)

	local setHasLeading = context.setHasLeading
	if setHasLeading then
		Vide.effect(function()
			if resolvedLeading() ~= nil then
				Vide.untrack(setHasLeading)
			end
		end)
	end

	local function onActivated()
		if isSubmenu then
			if Vide.untrack(isDisabled) then
				return
			end
			if context.hoverOpenAtDepth and not Vide.untrack(isOpen) then
				context.hoverOpenAtDepth(depth, props.id, true)
			end
		else
			if context.hoverReset then
				context.hoverReset()
			end

			local callback: OnItemActivated? = props.onActivated or context.onActivated
			if not callback then
				Logger:warning("Menu should have either onActivated on itself or on all of its children")
			else
				callback(props.id)
			end

			if depth > 1 and context.onNestedLeafActivated then
				context.onNestedLeafActivated()
			end
		end
	end

	local function checkColumn(): GuiObject
		local column = View({
			LayoutOrder = 1,
			tag = function()
				local variant = variantProps()
				return `{variant.slotAlign.tag} {variant.check.tag}`
			end,
			testId = `{testId}--check-column`,
			children = Vide.show(function()
				return isChecked() and not isSubmenu
			end, function()
				local check = Icon({
					name = BuilderIcons.Icon.Check,
					style = function(): ColorStyleValue
						return variantProps().check.style
					end,
					size = function()
						return variantProps().check.size
					end,
					testId = `{testId}--checkmark`,
				})
				check.Name = "Check"
				return check
			end),
		})
		column.Name = "Check"
		return column
	end

	local function leadingSlot(): any
		return Vide.switch(function(): string?
			if resolvedLeading() ~= nil then
				return "accessory"
			end
			return if alignmentHasLeading() then "slot" else nil
		end)({
			accessory = function()
				return named(
					"Leading",
					Accessory({
						LayoutOrder = 1,
						accessory = resolvedLeading,
						iconVariant = function()
							return variantProps().icon
						end,
						size = size,
						testId = `{testId}--leading`,
					})
				)
			end,
			slot = function()
				local slot = View({
					LayoutOrder = 1,
					tag = function()
						local variant = variantProps()
						return `{variant.slotAlign.tag} {variant.icon.tag}`
					end,
				})
				slot.Name = "Leading"
				return slot
			end,
		})
	end

	local function trailingSlot(): any
		if isSubmenu then
			local chevron = Icon({
				LayoutOrder = 3,
				name = BuilderIcons.Icon.ChevronSmallRight,
				style = function(): ColorStyleValue
					return variantProps().check.style
				end,
				size = function()
					return variantProps().chevron.size
				end,
				testId = `{testId}--chevron`,
			})
			chevron.Name = "Trailing"
			return chevron
		end
		return Vide.show(function()
			return resolvedTrailing() ~= nil
		end, function()
			return named(
				"Trailing",
				Accessory({
					LayoutOrder = 3,
					accessory = resolvedTrailing,
					iconVariant = function()
						return variantProps().icon
					end,
					size = size,
					testId = `{testId}--trailing`,
				})
			)
		end)
	end

	local function wrapper(): GuiObject
		local title = Text({
			LayoutOrder = 2,
			Text = props.text,
			tag = function()
				return variantProps().text.tag
			end,
		})
		title.Name = "Title"

		local view = View({
			LayoutOrder = 2,
			tag = "auto-xy",
			flexItem = { FlexMode = Enum.UIFlexMode.Fill },
			layout = {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = function()
					local wrapperVariant = variantProps().wrapper
					return UDim.new(0, (wrapperVariant and wrapperVariant.gap) or 0)
				end,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			children = { leadingSlot(), title, trailingSlot() },
		})
		view.Name = "Wrapper"
		return view
	end

	local function buildItem(disabled: boolean): GuiObject
		local item = View(withCommonProps(props, {
			GroupTransparency = if disabled then Constants.DISABLED_TRANSPARENCY else nil,
			isDisabled = disabled,
			onActivated = onActivated,
			selection = {
				Selectable = not disabled,
			},
			cursor = function()
				local current = tokens()
				return {
					radius = UDim.new(0, current.Radius.Small),
					offset = current.Size.Size_200,
					borderWidth = current.Stroke.Thicker,
				}
			end,
			tag = function()
				return variantProps().container.tag
			end,
			padding = {
				left = function()
					local container = variantProps().container
					local left = if menuHasCheck()
						then container.paddingLeftWithCheck
						else container.paddingLeftWithoutCheck
					return UDim.new(0, left or 0)
				end,
				right = function()
					return UDim.new(0, variantProps().container.paddingRight or 0)
				end,
			},
			layout = CONTAINER_LAYOUT,
			children = {
				Vide.show(menuHasCheck, checkColumn),
				wrapper(),
			},
		}) :: any)
		if props.ref then
			props.ref(item)
		end
		return item
	end

	local disabled: Value<boolean> = if type(props.isDisabled) == "function" then isDisabled else props.isDisabled == true
	local item = rebuildOn<<boolean>>(disabled, buildItem)
	local function itemInstance(): GuiObject?
		return if type(item) == "function" then item() else item
	end

	useMenuItemHover({
		item = itemInstance,
		id = props.id,
		depth = depth,
		isSubmenu = isSubmenu,
		isDisabled = isDisabled,
		hoverOpenAtDepth = context.hoverOpenAtDepth,
		hoverCloseAtDepth = context.hoverCloseAtDepth,
	})

	local buildSubmenuItems = props.children
	if buildSubmenuItems == nil then
		return item
	end

	local submenuHasLeading = Vide.source(false)
	local submenuContext: BaseMenuContextType = {
		onActivated = context.onActivated,
		onNestedLeafActivated = context.onNestedLeafActivated,
		size = size,
		hasLeading = function()
			return submenuHasLeading()
		end,
		setHasLeading = function()
			submenuHasLeading(true)
		end,
		hoverOpenPath = context.hoverOpenPath,
		hoverOpenAtDepth = context.hoverOpenAtDepth,
		hoverCloseAtDepth = context.hoverCloseAtDepth,
		hoverReset = context.hoverReset,
		depth = depth + 1,
		maxHeight = context.maxHeight,
	}

	local function submenuContent(): GuiObject
		local submenuItems = BaseMenuContext(submenuContext, buildSubmenuItems)
		local function tag(): string
			return variantProps().submenuContent.tag
		end
		local content = if isSubmenuScrollable
			then BaseMenuScrollContainer({
				maxHeight = context.maxHeight,
				scrollViewProps = {
					tag = tag,
					InputSink = InputSinkAll,
				},
				children = submenuItems,
			})
			else View({
				tag = tag,
				InputSink = InputSinkAll,
				children = submenuItems,
			})
		content.Name = "Children"
		return content
	end

	local submenu = Popover.Root({
		isOpen = isOpen,
		testId = `{testId}--submenu`,
		children = function()
			return {
				Popover.Anchor({ anchorRef = itemInstance }),
				Popover.Content({
					side = function()
						return {
							position = PopoverSide.Right,
							offset = variantProps().groupPadding.size / 2 + tokens().Stroke.Standard,
						}
					end,
					align = function()
						return {
							position = PopoverAlign.Start,
							offset = -variantProps().groupPadding.size,
						}
					end,
					hasArrow = false,
					onPressedOutside = function()
						if context.hoverReset then
							context.hoverReset()
						end
					end,
					backgroundStyle = function(): ColorStyleValue
						return tokens().Color.Surface.Surface_200 :: ColorStyleValue
					end,
					radius = Radius.Medium,
					children = submenuContent,
				}),
			}
		end,
	})

	return { named("Item", item), submenu }
end

return BaseMenuItem
