local Vide = require("../../Packages/Vide")

local InputSize = require("../../Enums/InputSize")
local Radius = require("../../Enums/Radius")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local useScaledValue = require("../../Utility/useScaledValue")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local BaseMenuContext = require("./BaseMenuContext")
local BaseMenuScrollContainer = require("./BaseMenuScrollContainer")
local DeclarativeBaseMenuContent = require("./DeclarativeBaseMenuContent")
local useSubmenuHover = require("./useSubmenuHover")

type InputSize = InputSize.InputSize
type Radius = Radius.Radius
type OnItemActivated = Types.OnItemActivated
type SizeConstraint = Types.SizeConstraint
type Value<T> = Types.Value<T>

export type BaseMenuItem = DeclarativeBaseMenuContent.BaseMenuItem
export type BaseMenuItems<Item = BaseMenuItem> = DeclarativeBaseMenuContent.BaseMenuItems<Item>
export type BaseMenuItemGroup<Item = BaseMenuItem> = DeclarativeBaseMenuContent.BaseMenuItemGroup<Item>

export type BaseMenuProps<Item = BaseMenuItem> = {
	-- List of items to display in the menu
	items: Value<BaseMenuItems<Item>?>?,
	-- Size of the menu and its items
	size: Value<InputSize>?,
	-- Width of the component. If not specified, the menu is sized based on the content.
	width: Value<UDim?>?,
	onActivated: OnItemActivated?,
	onNestedLeafActivated: (() -> ())?,
	-- Makes menu to use the provided width as a minimum width and use autosize instead to grow until the max width.
	-- If the provided width is bigger than the max width of the menu menu will have the width provided.
	-- If used with relative width, e.g. UDim.new(0.5, 0), the constraints always kick in.
	couldGrow: Value<boolean?>?,
	-- Builds the menu's items (BaseMenu.Item, BaseMenu.Group) inside the menu's context. Replaces `items`.
	children: (() -> any)?,
	-- Maximum height after which the menu starts scrolling. Any value but nil, a source included, makes the menu a
	-- scroll container.
	maxHeight: Value<number?>?,
	-- Radius of the menu
	radius: Value<Radius?>?,
	-- Receives the scrolling frame when the menu is scrollable (`maxHeight` set).
	scrollingFrameRef: ((ScrollingFrame) -> ())?,
} & Types.CommonProps

local defaultProps = {
	size = InputSize.Medium,
}

local radiusToTag: { [Radius]: string } = {
	[Radius.Small] = "radius-small",
	[Radius.Medium] = "radius-medium",
}

local MIN_WIDTH = 260
local MAX_WIDTH = 320

--- A list of menu items, flat or in titled groups, with nested submenus. Menu and Dropdown show it in a popover.
local function BaseMenu(baseMenuProps: BaseMenuProps): GuiObject
	local props = withDefaults(baseMenuProps, defaultProps)
	local scaledMinWidth = useScaledValue(MIN_WIDTH)
	local scaledMaxWidth = useScaledValue(MAX_WIDTH)
	local hasLeading = Vide.source(false)
	local submenuHover = useSubmenuHover()

	--* Hidden until the next frame, as in Foundation.
	local isVisible = Vide.source(false)
	Vide.cleanup(task.delay(0, function()
		isVisible(true)
	end))

	local function width(): UDim?
		return Value.read(props.width)
	end

	local function minWidth(): number
		local widthValue = width()
		return if widthValue then widthValue.Offset else scaledMinWidth()
	end

	local autoSize = Vide.derive(function(): boolean
		local widthValue = width()
		return not widthValue or (Value.read(props.couldGrow) == true and widthValue.Offset < scaledMaxWidth())
	end)

	local function sizeConstraint(): SizeConstraint
		local isAutoSize = autoSize()
		return {
			MinSize = if isAutoSize then Vector2.new(minWidth(), 0) else nil,
			MaxSize = if isAutoSize then Vector2.new(scaledMaxWidth(), math.huge) else nil,
		}
	end

	local function radiusTag(): string
		local radius: Radius? = Value.read(props.radius)
		return if radius ~= nil then `{radiusToTag[radius]}` else ""
	end

	local menuContent = BaseMenuContext({
		onActivated = props.onActivated,
		onNestedLeafActivated = props.onNestedLeafActivated,
		size = function(): InputSize
			return Value.read(props.size)
		end,
		hasLeading = function()
			return hasLeading()
		end,
		setHasLeading = function()
			hasLeading(true)
		end,
		hoverOpenPath = submenuHover.openPath,
		hoverOpenAtDepth = submenuHover.openAtDepth,
		hoverCloseAtDepth = submenuHover.closeAtDepth,
		hoverReset = submenuHover.reset,
		depth = 1,
		maxHeight = props.maxHeight,
	}, function(): any
		local buildChildren = props.children
		if buildChildren then
			return buildChildren()
		elseif props.items ~= nil then
			return DeclarativeBaseMenuContent({ items = props.items :: any })
		end
		return nil
	end)

	local visible = if props.Visible ~= nil then props.Visible else isVisible

	if props.maxHeight ~= nil then
		local scrollViewProps = withCommonProps(
			props,
			{
				sizeConstraint = sizeConstraint,
				scrollingFrameRef = props.scrollingFrameRef,
				tag = function()
					return `stroke-standard stroke-default {radiusTag()}`
				end,
			} :: BaseMenuScrollContainer.ScrollContainerProps
		)
		scrollViewProps.Visible = visible
		return BaseMenuScrollContainer({
			maxHeight = props.maxHeight,
			autoSize = autoSize,
			width = width,
			scrollViewProps = scrollViewProps,
			children = menuContent,
		})
	end

	local viewProps = withCommonProps(
		props,
		{
			tag = function()
				return `col stroke-standard stroke-default {radiusTag()}`
			end,
			AutomaticSize = function()
				return if autoSize() then Enum.AutomaticSize.XY else Enum.AutomaticSize.Y
			end,
			sizeConstraint = sizeConstraint,
			children = {
				Value.bindProperty("Size", function(): UDim2?
					local widthValue = width()
					return if autoSize() or widthValue == nil then nil else UDim2.new(widthValue, UDim.new())
				end),
				menuContent,
			},
		} :: View.ViewProps
	)
	viewProps.Visible = visible
	return View(viewProps)
end

return BaseMenu
