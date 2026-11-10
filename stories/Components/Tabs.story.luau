local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local FillBehavior = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/FillBehavior")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local PopoverAlign = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/PopoverAlign")
local PopoverSide = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/PopoverSide")
local StatusIndicatorShape = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/StatusIndicatorShape")
local StatusIndicatorVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/StatusIndicatorVariant")
local TabItemModule = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Tabs/TabItem")
local Types = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Types")

type TabItem = VideFoundation.TabItem
type TabItemIcon = TabItemModule.TabItemIcon
type InputSize = InputSize.InputSize
type ItemId = Types.ItemId

local IconName = VF.Enums.IconName
local IconVariant = VF.Enums.IconVariant

local builderIcon: TabItemIcon = {
	name = "star",
	variant = IconVariant.Filled,
}

--- A tab's content: text in a padded view.
local function TabContent(text: string, wrap: boolean?)
	return function()
		return VF.View({
			tag = "size-full-0 auto-y padding-xxlarge",
			children = VF.Text({
				tag = if wrap then "auto-xy text-wrap text-align-x-left" else "auto-xy text-align-x-left",
				Text = text,
			}),
		})
	end
end

local function NestedControlledTabs(props: { size: () -> InputSize })
	local activeTabId = Vide.source("1" :: ItemId)

	local function NestedContent(id: ItemId, layoutOrder: number)
		return VF.View({
			LayoutOrder = layoutOrder,
			tag = "size-full-0 auto-y padding-xxlarge",
			Visible = function()
				return activeTabId() == id
			end,
			children = VF.Text({
				tag = "auto-xy text-wrap text-align-x-left",
				Text = `Content of nested tab {id}`,
			}),
		})
	end

	return VF.View({
		tag = "col size-full-0 auto-y",
		children = {
			VF.Tabs({
				LayoutOrder = 1,
				activeTabId = activeTabId,
				onActivated = function(id: ItemId)
					activeTabId(id)
				end,
				tabs = {
					{ id = "1", text = "Nested tab 1" },
					{ id = "2", text = "Nested tab 2" },
				},
				size = props.size,
				fillBehavior = FillBehavior.Fill,
			}),
			NestedContent("1", 2),
			NestedContent("2", 2),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local tabs: { TabItem } = {
		{
			id = "1",
			text = "lll",
			content = TabContent(
				"You fully controll how content is rendered. No padding or other styles are applied by default",
				true
			),
		},
		{
			id = "2",
			text = "A big one",
			content = TabContent("The Jurassic ranges from 200 million years to 145 million years ago."),
		},
		{
			id = "3",
			text = "With builder icon",
			icon = "star",
			content = TabContent("You are perfect!"),
		},
		{
			id = "4",
			text = "With filled builder icon",
			icon = builderIcon,
			content = TabContent("You are still perfect!"),
		},
		{
			id = "5",
			text = "With icon",
			icon = IconName.Shirt,
			isDisabled = true,
		},
		{
			id = "6",
			text = "With indicator",
			indicator = function()
				local value: number = controls.indicatorValue()
				return {
					value = if value > 0 then value else nil,
					variant = controls.indicatorVariant(),
					shape = controls.indicatorShape(),
				}
			end,
			content = TabContent("This tab shows a StatusIndicator."),
		},
	}

	return VF.View({
		tag = "col size-full-0 auto-y",
		children = VF.Tabs({
			defaultActiveTabId = "1",
			tabs = tabs,
			size = controls.size,
			fillBehavior = controls.fillBehavior,
		}),
	})
end

local function NestedStory(controls: { [string]: any })
	local tabs: { TabItem } = {
		{
			id = "1",
			text = "With nested tabs",
			content = function()
				return NestedControlledTabs({ size = controls.size })
			end,
		},
		{
			id = "2",
			text = "Regular tab",
			content = TabContent("Regular tab content."),
		},
		{
			id = "3",
			text = "With builder icon",
			icon = "star",
			content = TabContent("You are perfect!"),
		},
		{
			id = "4",
			text = "With filled builder icon",
			icon = builderIcon,
			content = TabContent("You are still perfect!"),
		},
		{
			id = "5",
			text = "With icon",
			icon = IconName.Shirt,
			isDisabled = true,
			-- A disabled tab may still have content.
			content = TabContent("You are still perfect!"),
		},
	}

	return VF.View({
		tag = "col size-full-0 auto-y",
		children = VF.Tabs({
			defaultActiveTabId = "1",
			onActivated = function(id: ItemId)
				print(`Tab {id} activated`)
			end,
			tabs = tabs,
			size = controls.size,
			fillBehavior = controls.fillBehavior,
		}),
	})
end

local function avatarTabs(bodyRef: ((GuiObject) -> ())?): { TabItem }
	return {
		{
			id = "hair",
			text = "Hair",
			icon = { name = "head-male", variant = IconVariant.Filled },
			content = TabContent("Browse hairstyles for your avatar.", true),
		},
		{
			id = "body",
			text = "Body",
			icon = { name = "torso", variant = IconVariant.Filled },
			ref = bodyRef,
			content = TabContent("Customize your avatar's body type and proportions.", true),
		},
		{
			id = "accessories",
			text = "Accessories",
			icon = { name = "bow-tie", variant = IconVariant.Filled },
			content = TabContent("Pick accessories to complete the look!", true),
		},
	}
end

local function WithCoachmarkStory(controls: { [string]: any })
	local bodyTab = Vide.source(nil :: GuiObject?)
	local getBodyTab: () -> GuiObject? = bodyTab :: any
	local isCoachmarkOpen = Vide.source(true)

	return VF.View({
		tag = "col size-full-0 auto-y",
		children = {
			VF.Tabs({
				LayoutOrder = 1,
				defaultActiveTabId = "hair",
				tabs = avatarTabs(function(instance: GuiObject)
					bodyTab(instance)
				end),
				size = controls.size,
				fillBehavior = controls.fillBehavior,
			}),
			VF.Coachmark({
				LayoutOrder = 2,
				title = "Heads have moved here!",
				text = "Find all head customization options under Body.",
				isOpen = isCoachmarkOpen,
				side = PopoverSide.Bottom,
				align = PopoverAlign.Center,
				anchorRef = getBodyTab,
				onClose = function()
					isCoachmarkOpen(false)
				end,
				actions = {
					{
						text = "Got it!",
						onActivated = function()
							isCoachmarkOpen(false)
						end,
						variant = ButtonVariant.Emphasis,
					},
				},
			}),
		},
	})
end

local function AsChildStory(controls: { [string]: any })
	local tabs = avatarTabs()
	table.remove(tabs, 3)

	return VF.View({
		tag = "col size-full-0 auto-y",
		children = {
			VF.Text({
				LayoutOrder = 1,
				Text = "I go first!",
				Size = UDim2.fromOffset(50, 50),
			}),
			VF.Tabs({
				LayoutOrder = 2,
				defaultActiveTabId = "hair",
				tabs = tabs,
				size = controls.size,
				fillBehavior = controls.fillBehavior,
			}),
			VF.Text({
				LayoutOrder = 3,
				Text = "I go last!",
				Size = UDim2.fromOffset(50, 50),
			}),
		},
	})
end

return foundation.sections({
	summary = "Tabs",
	controls = {
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		fillBehavior = UILabs.Choose(Dash.values(FillBehavior :: any)),
		indicatorValue = 0,
		indicatorVariant = UILabs.Choose(Dash.keys(StatusIndicatorVariant :: any)),
		indicatorShape = UILabs.Choose(Dash.keys(StatusIndicatorShape :: any)),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Uncontrolled with nested controlled tabs", story = NestedStory },
		{ name = "With Coachmark", story = WithCoachmarkStory },
		{ name = "As Child", story = AsChildStory },
	},
})
