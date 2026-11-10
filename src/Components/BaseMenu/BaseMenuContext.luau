local Vide = require("../../Packages/Vide")

local InputSize = require("../../Enums/InputSize")
local Types = require("../Types")
type InputSize = InputSize.InputSize
type ItemId = Types.ItemId
type OnItemActivated = Types.OnItemActivated
type Value<T> = Types.Value<T>

export type BaseMenuContextType = {
	onActivated: OnItemActivated?,
	onNestedLeafActivated: (() -> ())?,
	size: () -> InputSize,
	hasLeading: (() -> boolean)?,
	setHasLeading: (() -> ())?,
	-- Centralized submenu state
	hoverOpenPath: () -> { ItemId },
	hoverOpenAtDepth: ((depth: number, id: ItemId, immediate: boolean?) -> ())?,
	hoverCloseAtDepth: ((depth: number) -> ())?,
	hoverReset: (() -> ())?,
	-- Current nesting depth (1-based, root menu items are at depth 1)
	depth: number,
	-- Maximum height after which submenus start scrolling. Inherited from the root menu.
	maxHeight: Value<number?>?,
}

local EMPTY_PATH: { ItemId } = {}

local function mediumSize(): InputSize
	return InputSize.Medium
end

local function emptyPath(): { ItemId }
	return EMPTY_PATH
end

return Vide.context({
	size = mediumSize,
	hoverOpenPath = emptyPath,
	depth = 1,
} :: BaseMenuContextType)
