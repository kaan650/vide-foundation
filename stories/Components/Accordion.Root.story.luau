local foundation = require("../foundation")
local StoryIcons = require("../Shared/StoryIcons")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local BuilderIcons = require("@game/ReplicatedStorage/Packages/VideFoundation/Packages/BuilderIcons")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local Types = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Types")

type AccordionItemIcon = { name: string, variant: BuilderIcons.IconVariant }
type ItemId = Types.ItemId

local Accordion = VF.Accordion.Root
local AccordionItem = VF.Accordion.Item

local ACCORDION_WIDTH = UDim.new(0, 400)

local function itemContent(text: string)
	return VF.Text({
		Text = text,
		tag = "auto-xy padding-y-small text-body-medium text-wrap text-align-x-left",
	})
end

local function content()
	local padding = Vide.source(false)

	return VF.View({
		tag = "col size-full-0 auto-y",
		children = {
			VF.Text({
				Text = "Our flagship product combines cutting-edge technology with sleek design.",
				tag = "auto-xy padding-y-small text-body-medium text-wrap text-align-x-left text-align-y-center",
			}),
			VF.Button({
				LayoutOrder = 2,
				text = "Click to expand!",
				onActivated = function()
					padding(not padding())
				end,
			}),
			foundation.create("UIPadding")({
				Name = "UIPadding",
				PaddingBottom = function()
					return UDim.new(0, if padding() then 50 else 0)
				end,
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local expandedItem = Vide.source(1)

	local function leadingIcon(): AccordionItemIcon?
		local icon = StoryIcons.parseIconControl(controls.icon())
		return if icon then { name = icon, variant = controls.iconVariant() } else nil
	end

	local function handleActivated(item: ItemId, isExpanded: boolean?)
		return function()
			expandedItem(if isExpanded then -1 else item :: number)
		end
	end

	local function controlledItem(id: number, text: string, body: string)
		return AccordionItem({
			text = text,
			LayoutOrder = id,
			id = id,
			isExpanded = function()
				return expandedItem() == id
			end,
			leadingIcon = leadingIcon,
			children = itemContent(body),
		})
	end

	--* Controlled and uncontrolled items are different trees in Foundation's story, so switching builds them again.
	return foundation.rebuildOn(controls.controlled, function(controlled: boolean)
		if controlled then
			return Accordion({
				width = ACCORDION_WIDTH,
				size = controls.size,
				onActivated = handleActivated,
				children = function()
					return {
						controlledItem(
							1,
							"Controlled item 1",
							"Only one item expands at a time when Root.onActivated is wired."
						),
						controlledItem(2, "Controlled item 2", "Root.onActivated coordinates expansion across items."),
						controlledItem(
							3,
							"Controlled item 3",
							"Toggle controlled mode off to let items manage their own state."
						),
					}
				end,
			})
		end

		return Accordion({
			width = ACCORDION_WIDTH,
			size = controls.size,
			children = function()
				return {
					AccordionItem({
						text = "First accordion item",
						LayoutOrder = 1,
						id = 1,
						isExpanded = true,
						leadingIcon = leadingIcon,
						children = itemContent("Content for the first item."),
					}),
					AccordionItem({
						text = "Second accordion item",
						LayoutOrder = 2,
						id = 2,
						leadingIcon = leadingIcon,
						children = itemContent("Content for the second item."),
					}),
					AccordionItem({
						text = "Third accordion item",
						LayoutOrder = 3,
						id = 3,
						leadingIcon = leadingIcon,
						children = itemContent("Content for the third item."),
					}),
				}
			end,
		})
	end)
end

local function ControlledStory()
	local expandedItem = Vide.source(1)

	local function handleActivated(item: ItemId, isExpanded: boolean?)
		return function()
			expandedItem(if isExpanded then -1 else item :: number)
		end
	end

	local function item(id: number)
		return AccordionItem({
			text = `Controlled Item {id}`,
			LayoutOrder = id,
			id = id,
			isExpanded = function()
				return expandedItem() == id
			end,
			children = content(),
		})
	end

	return Accordion({
		width = ACCORDION_WIDTH,
		onActivated = handleActivated,
		children = function()
			return { item(1), item(2), item(3) }
		end,
	})
end

local function ComplexControlledStory()
	local expandedItems = Vide.source({ 1, 2, 3 } :: { ItemId })

	local function handleActivated(item: ItemId, isExpanded: boolean?)
		return function()
			if isExpanded then
				expandedItems(Dash.filter(expandedItems(), function(expandedItem)
					return expandedItem ~= item
				end))
			else
				expandedItems({ item })
			end
		end
	end

	local function isExpanded(id: number): () -> boolean
		return function()
			return table.find(expandedItems(), id) ~= nil
		end
	end

	return Accordion({
		width = ACCORDION_WIDTH,
		onActivated = handleActivated,
		children = function()
			return {
				AccordionItem({
					text = "All Controlling Item",
					LayoutOrder = 1,
					id = 1,
					onActivated = function()
						if table.find(expandedItems(), 1) then
							expandedItems({})
						else
							expandedItems({ 1, 2, 3 })
						end
					end,
					isExpanded = isExpanded(1),
					children = content(),
				}),
				AccordionItem({
					text = "Controlled Item 2",
					LayoutOrder = 2,
					id = 2,
					isExpanded = isExpanded(2),
					children = content(),
				}),
				AccordionItem({
					text = "Controlled Item 3",
					LayoutOrder = 3,
					id = 3,
					isExpanded = isExpanded(3),
					children = content(),
				}),
			}
		end,
	})
end

local function PartiallyControlledStory()
	local expandedItem = Vide.source(1)

	local function onActivated(item: number)
		return function()
			expandedItem(if expandedItem() == item then 0 else item)
		end
	end

	local function isExpanded(id: number): () -> boolean
		return function()
			return expandedItem() == id
		end
	end

	return Accordion({
		width = ACCORDION_WIDTH,
		children = function()
			return {
				AccordionItem({
					text = "Controlled Item 1",
					LayoutOrder = 1,
					id = 1,
					isExpanded = isExpanded(1),
					onActivated = onActivated(1),
					children = content(),
				}),
				AccordionItem({
					text = "Default Item 1",
					LayoutOrder = 2,
					id = 2,
					children = content(),
				}),
				AccordionItem({
					text = "Default Item 2",
					LayoutOrder = 3,
					id = 3,
					children = content(),
				}),
				AccordionItem({
					text = "Controlled Item 2",
					LayoutOrder = 4,
					id = 4,
					isExpanded = isExpanded(4),
					onActivated = onActivated(4),
					children = content(),
				}),
			}
		end,
	})
end

return foundation.sections({
	summary = "Accordion",
	controls = {
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		controlled = false,
		icon = UILabs.Choose(StoryIcons.buildIconControlOptions()),
		iconVariant = UILabs.Choose(Dash.values(VF.Enums.IconVariant :: any)),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Controlled (one expanded item at a time)", story = ControlledStory },
		{ name = "Complex Controlled with unique onActivated", story = ComplexControlledStory },
		{ name = "Partially Controlled", story = PartiallyControlledStory },
	},
})
