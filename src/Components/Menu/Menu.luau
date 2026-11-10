local BaseMenu = require("../BaseMenu")
local InputSize = require("../../Enums/InputSize")
local Popover = require("../Popover")
local PopoverAlign = require("../../Enums/PopoverAlign")
local PopoverSide = require("../../Enums/PopoverSide")
local Radius = require("../../Enums/Radius")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ColorStyleValue = Types.ColorStyleValue
type InputSize = InputSize.InputSize
type PopoverSide = PopoverSide.PopoverSide
type PopoverAlign = PopoverAlign.PopoverAlign
type OnItemActivated = Types.OnItemActivated
type PopoverAnchor = Types.PopoverAnchor
type Value<T> = Types.Value<T>

export type MenuItem = BaseMenu.BaseMenuItem
export type MenuItems = BaseMenu.BaseMenuItems

export type MenuProps = {
	-- Whether the menu is open
	isOpen: Value<boolean>,
	-- List of items to display in the menu
	items: Value<MenuItems>,
	-- Size of the menu and its items
	size: Value<InputSize>?,
	-- Width of the component. If not specified, the menu is sized based on the content.
	width: Value<UDim?>?,
	-- Maximum height after which the menu starts scrolling
	maxHeight: Value<number?>?,
	-- The side the popover should be anchored to
	side: Value<PopoverSide>?,
	-- The alignment of the popover relative to the anchor
	align: Value<PopoverAlign>?,
	-- Callback for when the backdrop is pressed
	onPressedOutside: (() -> ())?,
	-- Callback for when a menu item is activated.
	-- Should be defined either for the whole Menu, or separately for all the MenuItems
	onActivated: OnItemActivated?,
	-- The element that will serve as an anchor: an instance, a source of one, or a `useMeasurableRef` object
	anchorRef: Value<PopoverAnchor?>?,
	-- Children to render as the anchor
	children: Types.Children?,
	-- Selection behavior
	selection: Types.Selection?,
	selectionGroup: (Value<boolean> | Types.SelectionGroup)?,
	-- Receives the popover content frame when the menu opens, and nil when it closes.
	ref: ((content: GuiObject?) -> ())?,
} & Types.CommonProps

local defaultProps = {
	size = InputSize.Medium,
	side = PopoverSide.Bottom,
	align = PopoverAlign.Start,
	testId = "--foundation-menu",
}

--- A BaseMenu in a popover next to its anchor: `children`, or the instance `anchorRef` names. Returns the anchor
--- and the popover content, as React renders them as a fragment.
local function Menu(menuProps: MenuProps): { any }
	local props = withDefaults(menuProps, defaultProps)
	local tokens = useTokens()

	local function buildMenu(hasMaxHeight: boolean): GuiObject
		return BaseMenu.Root({
			items = props.items,
			size = props.size,
			width = props.width,
			maxHeight = if hasMaxHeight then props.maxHeight else nil,
			onActivated = props.onActivated,
			onNestedLeafActivated = props.onPressedOutside,
			radius = Radius.Medium,
		})
	end

	--* React's Menu takes a plain maxHeight, and BaseMenu becomes a scroll container only while it is set.
	local maxHeight = props.maxHeight
	local hasMaxHeight: Value<boolean> = if type(maxHeight) == "function"
		then function()
			return Value.read(maxHeight) ~= nil
		end
		else maxHeight ~= nil

	return Popover.Root({
		isOpen = props.isOpen,
		testId = props.testId,
		children = function()
			return {
				Popover.Anchor(withCommonProps(props, {
					anchorRef = props.anchorRef,
					children = if props.anchorRef then nil else props.children,
				} :: Popover.PopoverAnchorProps)),
				Popover.Content({
					side = function()
						local current = tokens()
						return {
							position = Value.read(props.side),
							offset = current.Stroke.Standard + current.Padding.Small,
						}
					end,
					align = props.align,
					hasArrow = false,
					onPressedOutside = props.onPressedOutside,
					backgroundStyle = function(): ColorStyleValue
						return tokens().Color.Surface.Surface_200 :: ColorStyleValue
					end,
					radius = Radius.Medium,
					ref = props.ref,
					selection = props.selection,
					selectionGroup = props.selectionGroup,
					children = function()
						return named("Menu", rebuildOn<<boolean>>(hasMaxHeight, buildMenu))
					end,
				}),
			}
		end,
	})
end

return Menu
