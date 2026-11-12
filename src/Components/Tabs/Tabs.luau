local Vide = require("../../Packages/Vide")

local FillBehavior = require("../../Enums/FillBehavior")
local InputSize = require("../../Enums/InputSize")
local OverflowScrollContainer = require("../OverflowScrollContainer")
local TabItem = require("./TabItem")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local useAnimatedHighlight = require("../../Utility/useAnimatedHighlight")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InputSize = InputSize.InputSize
type FillBehavior = FillBehavior.FillBehavior
type ItemId = Types.ItemId
type Value<T> = Types.Value<T>
export type TabItem = TabItem.TabItem

export type TabsProps = {
	-- Default active tab id for uncontrolled component. Active tab is tracked inside the component. Read once, when
	-- the component is created.
	defaultActiveTabId: ItemId?,
	-- Active tab id for controlled component. Active tab is tracked by the user. Shouldn't be used along with defaultActiveTabId
	activeTabId: Value<ItemId?>?,
	-- Callback function when a tab is activated
	onActivated: ((id: ItemId) -> ())?,
	-- List of tabs to display
	tabs: Value<{ TabItem }>,
	size: Value<InputSize>?,
	-- Whether tabs fill the whole width growing to the equal size (Fill) or take minmum space (Fit)
	fillBehavior: Value<FillBehavior>?,
} & Types.CommonProps

local defaultProps = {
	fillBehavior = FillBehavior.Fill,
	size = InputSize.Medium,
	testId = "--foundation-tabs",
	ZIndex = 1,
}

type Entry = { tab: TabItem, index: number }
type ContentBuilder = () -> Types.Children

--- A row of tabs with a bar under the active one that slides to the next, and the active tab's content below.
local function Tabs(tabsProps: TabsProps): GuiObject
	local props = withDefaults(tabsProps, defaultProps)
	local tokens = useTokens()
	local testId = props.testId

	local function tabs(): { TabItem }
		return Value.read(props.tabs :: Value<{ TabItem }>)
	end
	local function size(): InputSize
		return Value.read(props.size)
	end
	local function fillBehavior(): FillBehavior
		return Value.read(props.fillBehavior)
	end
	local function isFill(): boolean
		return fillBehavior() == FillBehavior.Fill
	end

	--! Foundation means to fall back to the first tab but reads `props[1].id` instead of `props.tabs[1].id`, so with
	--! neither id set no tab is active until one is activated. Kept to match.
	local internalActiveTabId = Vide.source(props.defaultActiveTabId)
	local getInternalActiveTabId: () -> ItemId? = internalActiveTabId :: any

	local function activeTabId(): ItemId?
		local controlled: ItemId? = Value.read(props.activeTabId)
		if controlled ~= nil then
			return controlled
		end
		return getInternalActiveTabId()
	end

	local function onActivated(id: ItemId)
		if props.onActivated then
			props.onActivated(id)
		end
		internalActiveTabId(id)
	end

	local tabInstances = Vide.source({} :: { [ItemId]: GuiObject })
	local containerInstance = Vide.source(nil :: GuiObject?)
	local getContainer: () -> GuiObject? = containerInstance :: any

	local highlight = useAnimatedHighlight(activeTabId, getContainer, tabInstances, function()
		size()
		fillBehavior()
	end)

	local function borderThickness(): number
		return tokens().Stroke.Thick
	end

	--* Keyed by id like Foundation's tabs, so a tab keeps its instance when the list changes.
	local entries = Vide.derive(function(): { [ItemId]: Entry }
		local byId: { [ItemId]: Entry } = {}
		for index, tab in tabs() do
			byId[tab.id] = { tab = tab, index = index }
		end
		return byId
	end)
	local isListStatic = type(props.tabs) ~= "function"

	local function createTab(entry: () -> Entry, id: ItemId): GuiObject | () -> GuiObject
		local function tab(): TabItem
			return entry().tab
		end
		local initial = Vide.untrack(tab)
		local isDisabled: Value<boolean> = if isListStatic and type(initial.isDisabled) ~= "function"
			then initial.isDisabled == true
			else function()
				return Value.read(tab().isDisabled) == true
			end
		local ref = Vide.derive(function()
			return tab().ref
		end)

		return named(
			tostring(id),
			TabItem({
				tab = tab,
				isActive = function()
					return activeTabId() == id
				end,
				isDisabled = isDisabled,
				onActivated = onActivated,
				size = size,
				fillBehavior = fillBehavior,
				interactiveRef = function(interactive: GuiObject)
					local instances = table.clone(Vide.untrack(tabInstances))
					instances[id] = interactive
					tabInstances(instances)
					Vide.cleanup(function()
						local remaining = table.clone(Vide.untrack(tabInstances))
						if remaining[id] == interactive then
							remaining[id] = nil
							tabInstances(remaining)
						end
					end)

					Vide.effect(function()
						local callback = ref()
						if callback then
							Vide.untrack(function()
								callback(interactive)
							end)
						end
					end)
				end,
				--* Foundation's TabItem drops its LayoutOrder, so React orders tabs by mount order and puts a reordered
				--* or remounted (disabled) tab out of place. Kept here: Vide.indexes mounts in no particular order.
				LayoutOrder = function()
					return entry().index
				end,
				testId = `{testId}--item-{id}`,
			})
		)
	end

	local tabListWidth = Vide.source(0)

	local tabList = View({
		onAbsoluteSizeChanged = function(rbx: GuiObject)
			tabListWidth(rbx.AbsoluteSize.X)
		end,
		tag = function()
			local currentSize = size()
			return {
				["row flex-y-fill auto-xy"] = true,
				["gap-large"] = not isFill() and (currentSize == InputSize.Small or currentSize == InputSize.XSmall),
			}
		end,
		testId = `{testId}--list`,
		children = {
			Value.bindProperty("Size", function()
				return if isFill() then UDim2.fromScale(1, 0) else nil
			end),
			Vide.indexes(entries :: () -> { [ItemId]: Entry }, createTab),
		},
	})
	tabList.Name = "TabList"

	local scrollContainer = OverflowScrollContainer({
		LayoutOrder = 1,
		size = size,
		scrimBottomInset = borderThickness,
		testId = `{testId}--scroll-container`,
		children = tabList,
	})
	scrollContainer.Name = "ScrollContainer"

	local border = View({
		LayoutOrder = 2,
		AnchorPoint = Vector2.new(0, 1),
		Size = function()
			return UDim2.new(1, 0, 0, borderThickness())
		end,
		Position = UDim2.fromScale(0, 1),
		backgroundStyle = function()
			return tokens().Color.Stroke.Default :: any
		end,
		testId = `{testId}--border`,
	})
	border.Name = "Border"

	local wrapper = View({
		LayoutOrder = 1,
		tag = "auto-y",
		Size = UDim2.fromScale(1, 0),
		testId = `{testId}--wrapper`,
		children = { scrollContainer, border },
	})
	wrapper.Name = "Wrapper"

	local activeContent = Vide.derive(function(): ContentBuilder?
		local id = activeTabId()
		for _, tab in tabs() do
			if tab.id == id then
				return tab.content
			end
		end
		return nil
	end)

	--* React keeps the Content view while the active tab has content and swaps what is inside it.
	local content = Vide.show(activeContent, function()
		local view = View({
			LayoutOrder = 2,
			tag = "auto-y",
			Size = UDim2.fromScale(1, 0),
			testId = `{testId}--content`,
			children = rebuildOn(activeContent, function(build: ContentBuilder?)
				return (if build then build() else nil) :: any
			end),
		})
		view.Name = "Content"
		return view
	end)

	local container = View({
		tag = "col auto-y",
		Size = UDim2.fromScale(1, 0),
		children = { wrapper, content },
	})
	container.Name = "Tabs"
	containerInstance(container)

	local animatedBorder = View({
		LayoutOrder = 0,
		ZIndex = function()
			return Value.read(props.ZIndex) + 1
		end,
		Size = function()
			return UDim2.fromOffset(highlight.highlightWidth(), borderThickness())
		end,
		AnchorPoint = Vector2.new(0, 1),
		Position = function()
			return UDim2.fromOffset(highlight.highlightPosition(), highlight.activeItemHeight())
		end,
		backgroundStyle = function()
			return tokens().Color.System.Contrast :: any
		end,
		testId = `{testId}--animated-border`,
	})
	animatedBorder.Name = "AnimatedBorder"

	local fitConstraint: Types.SizeConstraint = {
		MaxSize = function()
			return Vector2.new(tabListWidth(), math.huge)
		end,
	}

	return View(withCommonProps(props, {
		tag = "auto-y no-clip",
		Size = UDim2.fromScale(1, 0),
		sizeConstraint = function(): Types.SizeConstraint?
			return if isFill() then nil else fitConstraint
		end,
		children = { container, animatedBorder },
	}) :: any)
end

return Tabs
