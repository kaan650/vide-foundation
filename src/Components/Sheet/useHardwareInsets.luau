local Vide = require("../../Packages/Vide")

local getHardwareSafeAreaInsets = require("./getHardwareSafeAreaInsets")
type HardwareInsets = getHardwareSafeAreaInsets.HardwareInsets

--- The device's safe-area insets as a source, checked again whenever the overlay resizes.
local function useHardwareInsets(overlay: () -> GuiBase2d?): () -> HardwareInsets
	local insets = Vide.source(getHardwareSafeAreaInsets())

	Vide.effect(function()
		local current = overlay()
		if not current then
			return
		end
		Vide.cleanup(current:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local prev = Vide.untrack(insets)
			local newInsets = getHardwareSafeAreaInsets()
			if
				newInsets.bottom ~= prev.bottom
				or newInsets.top ~= prev.top
				or newInsets.left ~= prev.left
				or newInsets.right ~= prev.right
			then
				insets(newInsets)
			end
		end))
	end)

	return function()
		return insets()
	end
end

return useHardwareInsets
