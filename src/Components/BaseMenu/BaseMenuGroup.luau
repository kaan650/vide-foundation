local Vide = require("../../Packages/Vide")

local BaseMenuContext = require("./BaseMenuContext")
local BaseMenuDivider = require("./BaseMenuDivider")
local BaseMenuTitleItem = require("./BaseMenuTitleItem")
local InputSize = require("../../Enums/InputSize")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")

type InputSize = InputSize.InputSize
type Value<T> = Types.Value<T>

local SIZE_TO_PADDING: { [InputSize]: string } = {
	[InputSize.XSmall] = "padding-xsmall",
	[InputSize.Small] = "padding-small",
	[InputSize.Medium] = "padding-small",
	[InputSize.Large] = "padding-small",
}

export type BaseMenuGroupProps = {
	title: Value<string?>?,
	children: Types.Children?,
	-- The group's 1-based position in the menu. Groups after the first get a divider above them.
	LayoutOrder: Value<number>,
	menuHasLeading: Value<boolean?>?,
	menuHasCheck: Value<boolean?>?,
}

--- A run of menu items with an optional title, separated from the previous group by a divider. Returns the divider
--- and the group, as React renders it as a fragment.
local function BaseMenuGroup(props: BaseMenuGroupProps): { any }
	local context = BaseMenuContext()

	local function groupIndex(): number
		return Value.read(props.LayoutOrder)
	end

	local divider = Vide.show(function()
		return groupIndex() ~= 1
	end, function()
		local divider = BaseMenuDivider({
			LayoutOrder = function()
				return groupIndex() * 2 - 1
			end,
		})
		divider.Name = "Divider"
		return divider
	end)

	local title = Vide.show(function()
		return Value.read(props.title) ~= nil
	end, function()
		local title = BaseMenuTitleItem({
			text = function()
				return Value.read(props.title) or ""
			end,
			size = context.size,
			menuHasLeading = props.menuHasLeading,
			menuHasCheck = props.menuHasCheck,
		})
		title.Name = "Title"
		return title
	end)

	local group = View({
		LayoutOrder = function()
			return groupIndex() * 2
		end,
		tag = function()
			return `col gap-xxsmall size-full-0 auto-y {SIZE_TO_PADDING[context.size()]}`
		end,
		children = { title, props.children },
	})
	group.Name = "Group"

	return { divider, group }
end

return BaseMenuGroup
