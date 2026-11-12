local Vide = require("../../Packages/Vide")

local Breakpoint = require("../../Enums/Breakpoint")
local BreakpointConfig = require("../../Utility/Responsive/BreakpointConfig")
local Divider = require("../Divider")
local NavigationBarTab = require("./NavigationBarTab")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local named = require("../../Utility/named")
local useAnimatedHighlight = require("../../Utility/useAnimatedHighlight")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ColorStyleValue = Types.ColorStyleValue
type ItemId = Types.ItemId
type Value<T> = Types.Value<T>

export type NavigationBarItem = NavigationBarTab.NavigationBarItem

export type NavigationBarProps = {
	-- Destinations to show, one tab each. Use 3 to 5 items
	items: Value<{ NavigationBarItem }>,
	-- Active item id for a controlled component. Shouldn't be used along with defaultActiveItemId
	activeItemId: Value<ItemId?>?,
	-- Initial active item id for an uncontrolled component. Read once, when the component is created.
	defaultActiveItemId: ItemId?,
	-- Called with the item id when a tab is activated
	onActivated: ((id: ItemId) -> ())?,
} & Types.CommonProps

type Entry = { item: NavigationBarItem, index: number }

local MAX_TABS_WIDTH = BreakpointConfig.widths[Breakpoint.Small]

local defaultProps = {
	testId = "--foundation-navigation-bar",
}

--- A bottom bar of 3 to 5 destination tabs, with an indicator along the top edge that slides to the active one.
local function NavigationBar(navigationBarProps: NavigationBarProps): GuiObject
	local props = withDefaults(navigationBarProps, defaultProps)
	local tokens = useTokens()
	local testId = props.testId

	local function items(): { NavigationBarItem }
		return Value.read(props.items :: Value<{ NavigationBarItem }>)
	end

	local initialItems = Vide.untrack(items)
	local internalActiveItemId =
		Vide.source(props.defaultActiveItemId or (if initialItems[1] then initialItems[1].id else nil))
	local getInternalActiveItemId: () -> ItemId? = internalActiveItemId :: any

	local function activeItemId(): ItemId?
		local controlled: ItemId? = Value.read(props.activeItemId)
		if controlled ~= nil then
			return controlled
		end
		return getInternalActiveItemId()
	end

	local function onActivated(id: ItemId)
		internalActiveItemId(id)
		if props.onActivated then
			props.onActivated(id)
		end
	end

	local tabInstances = Vide.source({} :: { [ItemId]: GuiObject })
	local containerInstance = Vide.source(nil :: GuiObject?)
	local getContainer: () -> GuiObject? = containerInstance :: any

	local highlight = useAnimatedHighlight(activeItemId, getContainer, tabInstances, function()
		items()
	end)

	local function hasActiveItem(): boolean
		local id = activeItemId()
		for _, item in items() do
			if item.id == id then
				return true
			end
		end
		return false
	end

	--* Keyed by id like Foundation's tabs, so a tab keeps its instance when the list changes.
	local entries = Vide.derive(function(): { [ItemId]: Entry }
		local byId: { [ItemId]: Entry } = {}
		for index, item in items() do
			byId[item.id] = { item = item, index = index }
		end
		return byId
	end)

	local function createTab(entry: () -> Entry, id: ItemId): GuiObject
		local tab = NavigationBarTab({
			item = function()
				return entry().item
			end,
			isActive = function()
				return activeItemId() == id
			end,
			onActivated = onActivated,
			LayoutOrder = function()
				return entry().index
			end,
			testId = `{testId}--item-{id}`,
		})
		tab.Name = tostring(id)

		local instances = table.clone(Vide.untrack(tabInstances))
		instances[id] = tab
		tabInstances(instances)
		Vide.cleanup(function()
			local remaining = table.clone(Vide.untrack(tabInstances))
			if remaining[id] == tab then
				remaining[id] = nil
				tabInstances(remaining)
			end
		end)

		return tab
	end

	local activeIndicator = View({
		tag = "radius-circle bg-system-contrast",
		Size = function()
			return UDim2.fromOffset(highlight.highlightWidth(), tokens().Size.Size_50)
		end,
		Position = function()
			return UDim2.fromOffset(highlight.highlightPosition(), 0)
		end,
		Visible = hasActiveItem,
		ZIndex = 3,
		testId = `{testId}--active-indicator`,
	})
	activeIndicator.Name = "ActiveIndicator"

	local tabs = View({
		tag = "row gap-small size-full-0 auto-y margin-x-small",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		sizeConstraint = { MaxSize = Vector2.new(MAX_TABS_WIDTH, math.huge) },
		ZIndex = 2,
		testId = `{testId}--tabs`,
		children = Vide.indexes(entries :: () -> { [ItemId]: Entry }, createTab),
	})
	tabs.Name = "Tabs"

	local container = View(withCommonProps(props, {
		tag = "size-full-0 auto-y",
		backgroundStyle = function(): ColorStyleValue
			return tokens().Color.Common.NavigationBar :: ColorStyleValue
		end,
		onActivated = function() end,
		stateLayer = { affordance = StateLayerAffordance.None },
		selection = { Selectable = false },
		children = {
			activeIndicator,
			named("Divider", Divider({ testId = `{testId}--divider` })),
			tabs,
		},
	}) :: any)
	containerInstance(container)

	return container
end

return NavigationBar
