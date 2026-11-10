local Vide = require("../../Packages/Vide")

local function findClippingAncestor(gui: GuiObject): GuiBase2d?
	local current = gui.Parent
	while current do
		if current:IsA("GuiObject") and current.ClipsDescendants then
			return current
		end
		current = current.Parent
	end
	local layerCollector = gui:FindFirstAncestorWhichIsA("LayerCollector")
	if layerCollector and layerCollector:IsA("GuiBase2d") then
		return layerCollector
	end
	return nil
end

--- The bounds `gui`'s content can visibly spill to, relative to `gui`'s top-left: its nearest clipping ancestor, or
--- the screen when nothing clips. Callers position against `Min` rather than assume `gui` is centered in them.
--- Call it while the component is being created.
local function useClippingRect(gui: () -> GuiObject?): () -> Rect
	local rect = Vide.source(Rect.new(Vector2.zero, Vector2.zero))
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

			local ancestor = findClippingAncestor(target)
			local function update()
				if ancestor then
					local origin = target.AbsolutePosition
					rect(
						Rect.new(
							ancestor.AbsolutePosition - origin,
							ancestor.AbsolutePosition + ancestor.AbsoluteSize - origin
						)
					)
				end
			end

			Vide.cleanup(target:GetPropertyChangedSignal("AbsolutePosition"):Connect(update))
			if ancestor then
				Vide.cleanup(ancestor:GetPropertyChangedSignal("AbsolutePosition"):Connect(update))
				Vide.cleanup(ancestor:GetPropertyChangedSignal("AbsoluteSize"):Connect(update))
			end
			update()
		end)
	end)

	return rect
end

return useClippingRect
