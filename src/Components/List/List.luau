local Vide = require("../../Packages/Vide")

local InputSize = require("../../Enums/InputSize")
local ListContext = require("./ListContext")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InputSize = InputSize.InputSize
type Value<T> = Types.Value<T>

export type ListDivider = boolean | { hasDivider: true, isInset: boolean }
export type ListContained = boolean | { isContained: false, hasMargin: boolean? }

export type ListProps = {
	-- Whether to render dividers between items, default is true. Can also be an object to specify inset or a
	-- full-width divider.
	hasDivider: Value<ListDivider?>?,
	-- Whether the list should have a border, default is false. Can also be an object to specify margin.
	isContained: Value<ListContained?>?,
	size: Value<InputSize?>?,
	-- Builds the `List.Item`s, which must be created inside the list to read its configuration.
	children: (() -> any)?,
} & Types.CommonProps

local defaultProps = {
	hasDivider = { hasDivider = true, isInset = true } :: ListDivider,
	isContained = { isContained = false, hasMargin = true } :: ListContained,
	testId = "--foundation-list",
}

--* React reads the LayoutOrder props of the List's child elements. The instances carry the same values, so their
--* highest LayoutOrder is watched instead; an item without one (0) counts like React's starting value.
local function watchLastLayoutOrder(view: GuiObject, lastLayoutOrder: (number) -> ())
	local connections: { [Instance]: RBXScriptConnection } = {}

	local function update()
		local highest = 0
		for _, child in view:GetChildren() do
			if child:IsA("GuiObject") then
				highest = math.max(highest, child.LayoutOrder)
			end
		end
		lastLayoutOrder(highest)
	end

	local function watch(child: Instance)
		if child:IsA("GuiObject") and not connections[child] then
			connections[child] = child:GetPropertyChangedSignal("LayoutOrder"):Connect(update)
		end
	end

	for _, child in view:GetChildren() do
		watch(child)
	end
	update()

	Vide.cleanup(view.ChildAdded:Connect(function(child)
		watch(child)
		update()
	end))
	Vide.cleanup(view.ChildRemoved:Connect(function(child)
		local connection = connections[child]
		if connection then
			connection:Disconnect()
			connections[child] = nil
		end
		update()
	end))
	Vide.cleanup(function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)
end

--- A column of `List.Item`s sharing a size, dividers and margins, optionally inside a rounded border.
local function List(listProps: ListProps): GuiObject
	local props = withDefaults(listProps, defaultProps)

	local function hasDividerProp(): ListDivider
		return Value.read(props.hasDivider) :: ListDivider
	end
	local function isContainedProp(): ListContained
		return Value.read(props.isContained) :: ListContained
	end
	local function isContained(): boolean
		local value = isContainedProp()
		return if type(value) == "boolean" then value else value.isContained
	end

	local highestLayoutOrder = Vide.source(0)
	local buildChildren = props.children

	local children = ListContext({
		--* A table always counts as having dividers, even `{ hasDivider = false }`, as in React.
		hasDivider = function()
			return hasDividerProp() ~= false
		end,
		isContained = isContained,
		isInset = function()
			local value = hasDividerProp()
			return if type(value) == "boolean" then value else value.isInset
		end,
		hasMargin = function()
			if isContained() then
				return true
			end
			local value = isContainedProp()
			return if type(value) == "table" then value.hasMargin == true else true
		end,
		lastLayoutOrder = function()
			local value = hasDividerProp()
			local hasDivider = if type(value) == "boolean" then value else value.hasDivider
			return if hasDivider then highestLayoutOrder() else 0
		end,
		size = function(): InputSize?
			return Value.read(props.size)
		end,
		testId = props.testId,
	}, function()
		return if buildChildren then buildChildren() else nil
	end)

	local view = View(withCommonProps(props, {
		tag = function()
			return {
				["col size-full-0 auto-y"] = true,
				["stroke-default radius-large"] = isContained(),
			}
		end,
		children = children,
	}) :: any)

	watchLastLayoutOrder(view, function(value)
		highestLayoutOrder(value)
	end)

	return view
end

return List
