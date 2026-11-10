local Vide = require("../../Packages/Vide")

local Types = require("../Types")
local useTokens = require("../../Providers/Style/useTokens")
type ItemId = Types.ItemId

export type SubmenuHoverState = {
	-- The ids of the open submenu chain, indexed by depth (1-based)
	openPath: () -> { ItemId },
	-- Opens a submenu at `depth`, closing deeper ones. `immediate` opens without the hover delay (click, tap).
	openAtDepth: (depth: number, id: ItemId, immediate: boolean?) -> (),
	-- Closes the submenus at and below `depth`, after the hover delay.
	closeAtDepth: (depth: number) -> (),
	-- Closes every submenu now (outside press, leaf activation).
	reset: () -> (),
}

local function truncatePath(path: { ItemId }, toLength: number): { ItemId }
	local newPath = {}
	for i = 1, toLength do
		if path[i] then
			newPath[i] = path[i]
		end
	end
	return newPath
end

local function buildPath(prev: { ItemId }, depth: number, id: ItemId): { ItemId }
	local newPath = truncatePath(prev, depth - 1)
	newPath[depth] = id
	return newPath
end

--- The open path of a menu's nested submenus, with hover delays. Call it while the menu is being created.
local function useSubmenuHover(): SubmenuHoverState
	local tokens = useTokens()
	local openPath = Vide.source({} :: { ItemId })
	local openTimer: thread? = nil
	local closeTimer: thread? = nil

	local function current(): { ItemId }
		return Vide.untrack(openPath)
	end

	local function cancelTimers()
		if openTimer then
			task.cancel(openTimer)
			openTimer = nil
		end
		if closeTimer then
			task.cancel(closeTimer)
			closeTimer = nil
		end
	end

	local function openAtDepth(depth: number, id: ItemId, immediate: boolean?)
		cancelTimers()

		if current()[depth] == id then
			return
		end

		if immediate then
			openPath(buildPath(current(), depth, id))
			return
		end

		openTimer = task.delay(Vide.untrack(tokens).Time.Time_100, function()
			openTimer = nil
			openPath(buildPath(current(), depth, id))
		end)
	end

	local function closeAtDepth(depth: number)
		cancelTimers()

		if #current() < depth then
			return
		end

		closeTimer = task.delay(Vide.untrack(tokens).Time.Time_300, function()
			closeTimer = nil
			local prev = current()
			if #prev >= depth then
				openPath(truncatePath(prev, depth - 1))
			end
		end)
	end

	local function reset()
		cancelTimers()
		openPath({})
	end

	Vide.cleanup(cancelTimers)

	return {
		openPath = function()
			return openPath()
		end,
		openAtDepth = openAtDepth,
		closeAtDepth = closeAtDepth,
		reset = reset,
	}
end

return useSubmenuHover
