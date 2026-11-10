local Vide = require("../../Packages/Vide")

local Types = require("../Types")
local Value = require("../../Utility/Value")

type SelectionProps = Types.SelectionProps

export type PaginationSlotBindings = {
	Selectable: () -> boolean,
	NextSelectionLeft: () -> GuiObject?,
	NextSelectionRight: () -> GuiObject?,
	NextSelectionUp: () -> GuiObject?,
	NextSelectionDown: () -> GuiObject?,
}

export type PaginationSelectionChain = {
	-- The instance of the first selectable slot.
	firstSlot: () -> GuiObject?,
	-- The slot's selection props, following the slot order.
	getSlotBindings: (slotId: string) -> PaginationSlotBindings,
	-- Records `instance` as the slot's instance until the calling scope is cleaned up.
	registerSlot: (slotId: string, instance: GuiObject) -> (),
	-- Registers what a component returned, an instance or a source of one, and returns it.
	bindSlot: (slotId: string, child: any) -> any,
	slotInstances: () -> { [string]: GuiObject },
}

--- Gamepad navigation between the pagination's slots: each selectable slot points left and right to its neighbours
--- in `slotOrder`. Call it while the component is being created.
local function usePaginationSelectionChain(
	slotOrder: () -> { string },
	selectionProps: SelectionProps
): PaginationSelectionChain
	local slotInstances = Vide.source({} :: { [string]: GuiObject })

	local function registerSlot(slotId: string, instance: GuiObject)
		local instances = table.clone(Vide.untrack(slotInstances))
		instances[slotId] = instance
		slotInstances(instances)
		Vide.cleanup(function()
			local remaining = Vide.untrack(slotInstances)
			if remaining[slotId] == instance then
				remaining = table.clone(remaining)
				remaining[slotId] = nil
				slotInstances(remaining)
			end
		end)
	end

	local function bindSlot(slotId: string, child: any): any
		if type(child) == "function" then
			Vide.effect(function()
				local instance = (child :: () -> any)()
				Vide.untrack(function()
					if typeof(instance) == "Instance" then
						registerSlot(slotId, instance :: GuiObject)
					end
				end)
			end)
		else
			registerSlot(slotId, child)
		end
		return child
	end

	local function neighbour(slotId: string, offset: number): GuiObject?
		local order = slotOrder()
		local index = table.find(order, slotId)
		if index == nil then
			return nil
		end
		local neighbourId = order[index + offset]
		return if neighbourId then slotInstances()[neighbourId] else nil
	end

	local function getSlotBindings(slotId: string): PaginationSlotBindings
		local function isInOrder(): boolean
			return table.find(slotOrder(), slotId) ~= nil
		end
		return {
			Selectable = isInOrder,
			NextSelectionLeft = function()
				return neighbour(slotId, -1)
			end,
			NextSelectionRight = function()
				return neighbour(slotId, 1)
			end,
			NextSelectionUp = function(): GuiObject?
				return if isInOrder() then Value.read(selectionProps.NextSelectionUp) else nil
			end,
			NextSelectionDown = function(): GuiObject?
				return if isInOrder() then Value.read(selectionProps.NextSelectionDown) else nil
			end,
		}
	end

	return {
		firstSlot = function()
			local firstSlotId = slotOrder()[1]
			return if firstSlotId then slotInstances()[firstSlotId] else nil
		end,
		getSlotBindings = getSlotBindings,
		registerSlot = registerSlot,
		bindSlot = bindSlot,
		slotInstances = slotInstances,
	}
end

return usePaginationSelectionChain
