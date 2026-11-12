local Vide = require("../../Packages/Vide")

local function findClippingAncestor(gui: GuiObject): GuiObject?
	local current = gui.Parent
	while current do
		if current:IsA("GuiObject") and current.ClipsDescendants then
			return current
		end
		current = current.Parent
	end
	return nil
end

--- The bounds `gui`'s content can visibly spill to, relative to `gui`'s top-left: its nearest clipping ancestor, or
--- `gui`'s own bounds when nothing clips. Callers position against `Min` rather than assume `gui` is centered in them.
--- Also returns whether a clipping ancestor was found: without one nothing bounds the spill, so the caller clips to
--- its own bounds. Call it while the component is being created.
local function useClippingRect(gui: () -> GuiObject?): (() -> Rect, () -> boolean)
	local rect = Vide.source(Rect.new(Vector2.zero, Vector2.zero))
	local hasClippingAncestor = Vide.source(true)
	local ancestry = Vide.source(0)

	Vide.effect(function()
		local current = gui()
		ancestry()
		if not current then
			return
		end
		local target: GuiObject = current

		Vide.untrack(function()
			--* Foundation measures once mounted; here the instance gets its ancestors after creation, so the search
			--* runs again whenever they change.
			Vide.cleanup(target.AncestryChanged:Connect(function()
				--! This fires inside whatever scope parents the instance. A tracked read would subscribe that scope,
				--! and strict mode then errors when the write asks it to rerun while it is still active.
				ancestry(Vide.untrack(ancestry) + 1)
			end))

			--* Assumed until the search proves otherwise, so a caller that clips itself in response has stopped
			--* clipping when the search runs again, and is not found as the ancestor.
			hasClippingAncestor(true)
			local clipping = findClippingAncestor(target)
			hasClippingAncestor(clipping ~= nil)
			local ancestor: GuiObject = clipping or target

			local function update()
				local origin = target.AbsolutePosition
				rect(
					Rect.new(
						ancestor.AbsolutePosition - origin,
						ancestor.AbsolutePosition + ancestor.AbsoluteSize - origin
					)
				)
			end

			Vide.cleanup(target:GetPropertyChangedSignal("AbsolutePosition"):Connect(update))
			Vide.cleanup(ancestor:GetPropertyChangedSignal("AbsolutePosition"):Connect(update))
			Vide.cleanup(ancestor:GetPropertyChangedSignal("AbsoluteSize"):Connect(update))
			update()
		end)
	end)

	return rect, hasClippingAncestor
end

return useClippingRect
