local Vide = require("../../Packages/Vide")

local useScreen = require("../../Providers/Overlay/useScreen")

--- The overlay screen's size as a source.
local function useScreenSize(): () -> Vector2
	local screen = useScreen()
	local size = Vide.source(Vide.untrack(function(): Vector2
		local current = screen()
		return if current then current.AbsoluteSize else Vector2.new(0, 0)
	end))

	Vide.effect(function()
		local current = screen()
		if not current then
			return
		end
		Vide.untrack(function()
			size(current.AbsoluteSize)
		end)
		Vide.cleanup(current:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			size(current.AbsoluteSize)
		end))
	end)

	return function()
		return size()
	end
end

return useScreenSize
