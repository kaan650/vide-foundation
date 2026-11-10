local Vide = require("../../Packages/Vide")

local BaseMenu = require("../BaseMenu")
local Popover = require("../Popover")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local InputSize = require("../../Enums/InputSize")
local InputVariant = require("../../Enums/InputVariant")
local PopoverAlign = require("../../Enums/PopoverAlign")
local PopoverSide = require("../../Enums/PopoverSide")
local Radius = require("../../Enums/Radius")
type InputVariant = InputVariant.InputVariant
type InputSize = InputSize.InputSize

local DropdownControl = require("./DropdownControl")
local markSelectedItem = require("./markSelectedItem")

type ItemId = Types.ItemId
type OnItemActivated = Types.OnItemActivated
type Value<T> = Types.Value<T>
type BaseMenuItem = BaseMenu.BaseMenuItem
type BaseMenuItems<Item> = BaseMenu.BaseMenuItems<Item>
type BaseMenuItemGroup<Item> = BaseMenu.BaseMenuItemGroup<Item>
export type LeadingAccessory = BaseMenu.LeadingAccessory
export type TrailingAccessory = BaseMenu.TrailingAccessory
export type DropdownItem = {
	id: ItemId,
	icon: string?,
	leading: (string | LeadingAccessory)?,
	trailing: TrailingAccessory?,
	isDisabled: boolean?,
	isChecked: boolean?,
	text: string,
}
export type DropdownItemGroup = BaseMenuItemGroup<DropdownItem>
export type DropdownItems = BaseMenuItems<DropdownItem>

export type DropdownProps = {
	-- The value of the currently selected dropdown item.
	-- If `nil`, the dropdown will be considered uncontrolled.
	value: Value<ItemId?>?,
	placeholder: Value<string?>?,
	items: Value<DropdownItems>,
	onItemChanged: OnItemActivated,
	-- Whether the dropdown is in an error state
	hasError: Value<boolean?>?,
	-- Style variant of the dropdown
	variant: Value<InputVariant>?,
	-- Whether the dropdown is disabled
	isDisabled: Value<boolean?>?,
	-- Width of the component
	width: Value<UDim>?,
	-- A label for the dropdown. To omit, set it to an empty string.
	label: Value<string>,
	hint: Value<string?>?,
	size: Value<InputSize>?,
	-- Maximum height after which the menu starts scrolling
	maxHeight: Value<number?>?,
	-- Receives the open menu's scrolling frame while the menu is open and scrollable; lets callers scroll it, e.g. to
	-- the selection.
	scrollingFrameRef: ((ScrollingFrame) -> ())?,
	-- Selection behavior applied to the open menu's popover surface (focus trap configuration).
	selection: Types.Selection?,
	selectionGroup: (Value<boolean> | Types.SelectionGroup)?,
	-- Receives the clickable control, the instance React's ref points to.
	ref: ((GuiObject) -> ())?,
} & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	variant = InputVariant.Standard,
	width = UDim.new(0, 400),
	size = InputSize.Medium,
	testId = "--foundation-dropdown",
}

local SIDE_CONFIG: { position: PopoverSide.PopoverSide, offset: number } = { position = PopoverSide.Bottom, offset = 5 }

type Marked = { items: BaseMenuItems<DropdownItem>, selected: DropdownItem? }

--- A form field that opens a menu of items and shows the selected one. Returns the field and the menu's popover
--- content, as React renders them as a fragment.
local function Dropdown(dropdownProps: DropdownProps): { any }
	local props = withDefaults(dropdownProps, defaultProps)
	local isMenuOpen = Vide.source(false)
	local inputInstance = Vide.source(nil :: GuiObject?)
	local getInputInstance: () -> GuiObject? = inputInstance :: any

	--* Starts at `width` and follows the field's measured width, so the menu is at least as wide as the field.
	local absoluteWidth = Vide.source(Vide.untrack(function(): UDim
		return Value.read(props.width)
	end))

	local marked = Vide.derive(function(): Marked
		local items, selected = markSelectedItem<<DropdownItem>>(Value.read(props.items) :: DropdownItems, Value.read(props.value))
		return { items = items, selected = selected }
	end)

	local function closeMenu()
		isMenuOpen(false)
	end

	local function onActivated(id: ItemId)
		isMenuOpen(false)
		props.onItemChanged(id)
	end

	local onAbsoluteSizeChanged = dropdownProps.onAbsoluteSizeChanged
	local controlProps = withCommonProps(props, {
		variant = props.variant,
		onActivated = function()
			isMenuOpen(not Vide.untrack(isMenuOpen))
		end,
		hasError = props.hasError,
		isDisabled = props.isDisabled,
		item = function(): BaseMenuItem?
			return marked().selected :: any
		end,
		placeholder = props.placeholder,
		isMenuOpen = function()
			return isMenuOpen()
		end,
		width = props.width,
		size = props.size,
		label = props.label,
		hint = props.hint,
		inputRef = function(instance: GuiObject)
			inputInstance(instance)
			if props.ref then
				props.ref(instance)
			end
		end,
		Selectable = props.Selectable,
		NextSelectionUp = props.NextSelectionUp,
		NextSelectionDown = props.NextSelectionDown,
		NextSelectionLeft = props.NextSelectionLeft,
		NextSelectionRight = props.NextSelectionRight,
	} :: DropdownControl.DropdownControlProps)
	controlProps.onAbsoluteSizeChanged = function(frame: GuiObject)
		if onAbsoluteSizeChanged then
			onAbsoluteSizeChanged(frame)
		end
		absoluteWidth(UDim.new(0, frame.AbsoluteSize.X))
	end

	local function buildMenu(hasMaxHeight: boolean): GuiObject
		return BaseMenu.Root({
			size = props.size,
			couldGrow = true,
			width = function(): UDim?
				return absoluteWidth()
			end,
			items = function()
				return marked().items :: any
			end,
			maxHeight = if hasMaxHeight then props.maxHeight else nil,
			onActivated = onActivated,
			radius = Radius.Medium,
			scrollingFrameRef = props.scrollingFrameRef,
			testId = `{props.testId}--menu`,
		})
	end

	--* React's Dropdown takes a plain maxHeight, and BaseMenu becomes a scroll container only while it is set.
	local maxHeight = props.maxHeight
	local hasMaxHeight: Value<boolean> = if type(maxHeight) == "function"
		then function()
			return Value.read(maxHeight) ~= nil
		end
		else maxHeight ~= nil

	return Popover.Root({
		isOpen = function()
			return isMenuOpen()
		end,
		children = function()
			return {
				named("DropdownControl", DropdownControl(controlProps)),
				--* The anchor is the control, not the whole field, so the menu lines up with it when it opens upward.
				Popover.Anchor({ anchorRef = getInputInstance }),
				Popover.Content({
					hasArrow = false,
					align = PopoverAlign.End,
					side = SIDE_CONFIG,
					onPressedOutside = closeMenu,
					radius = Radius.Medium,
					selection = props.selection,
					selectionGroup = props.selectionGroup,
					name = "Menu",
					children = function()
						return named("Children", rebuildOn<<boolean>>(hasMaxHeight, buildMenu))
					end,
				}),
			}
		end,
	})
end

return Dropdown
