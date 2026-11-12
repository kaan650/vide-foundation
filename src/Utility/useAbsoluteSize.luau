local Vide = require("../Packages/Vide")

type OnAbsoluteSizeChanged = ((instance: GuiObject) -> ())?

--- The AbsoluteSize of the GuiObject given the returned handler as `onAbsoluteSizeChanged`, as a source starting at
--- zero. The handler also calls `onAbsoluteSizeChanged`, so a component can measure itself and still forward the prop.
local function useAbsoluteSize(onAbsoluteSizeChanged: OnAbsoluteSizeChanged): (() -> Vector2, (GuiObject) -> ())
	local size = Vide.source(Vector2.zero)

	local function handleAbsoluteSizeChanged(instance: GuiObject)
		size(instance.AbsoluteSize)
		if onAbsoluteSizeChanged then
			onAbsoluteSizeChanged(instance)
		end
	end

	return size, handleAbsoluteSizeChanged
end

return useAbsoluteSize
