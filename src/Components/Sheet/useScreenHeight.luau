local Vide = require("../../Packages/Vide")

local useScreen = require("../../Providers/Overlay/useScreen")

--- The overlay screen's height as a source.
local function useScreenHeight(): () -> number
	local screen = useScreen()
	local height = Vide.source(Vide.untrack(function(): number
		local current = screen()
		return if current then current.AbsoluteSize.Y else 0
	end))

	Vide.effect(function()
		local current = screen()
		if not current then
			return
		end
		Vide.untrack(function()
			height(current.AbsoluteSize.Y)
		end)
		Vide.cleanup(current:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			height(current.AbsoluteSize.Y)
		end))
	end)

	return function()
		return height()
	end
end

return useScreenHeight
