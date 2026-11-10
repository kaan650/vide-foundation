local Vide = require("../../Packages/Vide")

local Types = require("../Types")
type ItemId = Types.ItemId

export type UseMenuItemHoverOptions = {
	item: () -> GuiObject?,
	id: ItemId,
	depth: number,
	isSubmenu: boolean,
	isDisabled: () -> boolean,
	hoverOpenAtDepth: ((depth: number, id: ItemId, immediate: boolean?) -> ())?,
	hoverCloseAtDepth: ((depth: number) -> ())?,
}

--- Wires an item's hover to the menu's submenu state: hovering a submenu item opens it and leaving closes it;
--- hovering a leaf closes the open sibling submenu. Disabled submenu items are ignored.
local function useMenuItemHover(options: UseMenuItemHoverOptions)
	Vide.effect(function()
		local item = options.item()
		if item == nil then
			return
		end

		Vide.cleanup(item:GetPropertyChangedSignal("GuiState"):Connect(function()
			local isHovered = item.GuiState == Enum.GuiState.Hover
			if options.isSubmenu then
				if Vide.untrack(options.isDisabled) then
					return
				end
				if isHovered then
					if options.hoverOpenAtDepth then
						options.hoverOpenAtDepth(options.depth, options.id)
					end
				elseif options.hoverCloseAtDepth then
					options.hoverCloseAtDepth(options.depth)
				end
			elseif isHovered and options.hoverCloseAtDepth then
				options.hoverCloseAtDepth(options.depth)
			end
		end))
	end)
end

return useMenuItemHover
