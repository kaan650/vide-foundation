local Vide = require("../../Packages/Vide")

local Motion = require("../../Utility/Motion")
local useTokens = require("../../Providers/Style/useTokens")

export type PaginationAnimatedHighlight = {
	activeItemHeight: () -> number,
	highlightPosition: () -> number,
	highlightWidth: () -> number,
	isVisible: () -> boolean,
	-- Snaps to the active item where it is now, or once a page change animation ends.
	syncSameItemHighlight: () -> (),
}

--- The highlight behind the current page. Unlike `Utility/useAnimatedHighlight`, page slots reflow when ellipses come
--- and go, so while a page change eases, snaps for layout changes wait until it ends. Hidden while the active slot is
--- missing or not laid out. Call it while the component is being created.
local function usePaginationAnimatedHighlight(
	activeItemId: () -> string?,
	container: () -> GuiObject?,
	items: () -> { [string]: GuiObject },
	dependencies: () -> ()
): PaginationAnimatedHighlight
	local tokens = useTokens()
	local function easeDuration(): number
		return Vide.untrack(tokens).Time.Time_100
	end

	local highlightPosition, setHighlightPosition = Motion.useAnimatedBinding(0)
	local highlightWidth, setHighlightWidth = Motion.useAnimatedBinding(0)
	local activeItemHeight = Vide.source(0)
	local isVisible = Vide.source(false)

	local previousItemId: string? = Vide.untrack(activeItemId)
	local blockInstantSync = false
	local pendingInstantSync = false
	local transitionUnlockThread: thread? = nil

	local function cancelTransitionUnlock()
		if transitionUnlockThread then
			task.cancel(transitionUnlockThread)
			transitionUnlockThread = nil
		end
	end
	Vide.cleanup(cancelTransitionUnlock)

	local activeItem = Vide.derive(function(): GuiObject?
		local id = activeItemId()
		return if id ~= nil then items()[id] else nil
	end)

	local syncSameItemHighlight: () -> ()

	local function scheduleTransitionUnlock()
		cancelTransitionUnlock()
		blockInstantSync = true
		transitionUnlockThread = task.delay(easeDuration(), function()
			transitionUnlockThread = nil
			blockInstantSync = false
			if pendingInstantSync then
				pendingInstantSync = false
				syncSameItemHighlight()
			end
		end)
	end

	local function updateHighlight(item: GuiObject, sameItem: boolean)
		local containerInstance = Vide.untrack(container)
		if not containerInstance then
			isVisible(false)
			return
		end

		local positionOffset = item.AbsolutePosition.X - containerInstance.AbsolutePosition.X
		local itemSize = item.AbsoluteSize.X
		local itemHeight = item.AbsoluteSize.Y
		if itemSize <= 0 or itemHeight <= 0 then
			isVisible(false)
			return
		end

		if sameItem and blockInstantSync then
			pendingInstantSync = true
			return
		end

		if sameItem then
			setHighlightWidth(Motion.instant(itemSize))
			setHighlightPosition(Motion.instant(positionOffset))
		else
			pendingInstantSync = false
			scheduleTransitionUnlock()
			local easeConfig: Motion.EaseOptions = {
				easingStyle = Enum.EasingStyle.Linear,
				duration = easeDuration(),
			}
			setHighlightPosition(Motion.ease(positionOffset, easeConfig))
			setHighlightWidth(Motion.ease(itemSize, easeConfig))
		end

		activeItemHeight(itemHeight)
		isVisible(true)
	end

	syncSameItemHighlight = function()
		local item = Vide.untrack(activeItem)
		if item then
			updateHighlight(item, true)
		end
	end

	Vide.effect(function()
		local id = activeItemId()
		local item = activeItem()
		local containerInstance = container()
		dependencies()
		Vide.untrack(function()
			if id == nil then
				isVisible(false)
				previousItemId = nil
				return
			end
			local isSameItem = id == previousItemId
			if not isSameItem then
				cancelTransitionUnlock()
				blockInstantSync = false
				pendingInstantSync = false
			end
			if item and containerInstance then
				updateHighlight(item, isSameItem)
			else
				isVisible(false)
			end
			--! Deferred so strict mode's second run of this effect still sees the previous item and eases too.
			task.defer(function()
				previousItemId = id
			end)
		end)
	end)

	Vide.effect(function()
		local item = activeItem()
		local containerInstance = container()
		Vide.untrack(function()
			if not item or not containerInstance then
				return
			end
			for _, instance: GuiObject in { item :: GuiObject, containerInstance :: GuiObject } do
				Vide.cleanup(instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncSameItemHighlight))
				Vide.cleanup(instance:GetPropertyChangedSignal("AbsolutePosition"):Connect(syncSameItemHighlight))
			end
		end)
	end)

	return {
		activeItemHeight = activeItemHeight,
		highlightPosition = highlightPosition,
		highlightWidth = highlightWidth,
		isVisible = isVisible,
		syncSameItemHighlight = syncSameItemHighlight,
	}
end

return usePaginationAnimatedHighlight
