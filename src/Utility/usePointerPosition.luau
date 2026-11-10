local Vide = require("../Packages/Vide")

local Types = require("../Components/Types")
local Value = require("./Value")

--- The last pointer position seen over `guiObject`, as a source. Call it while the component is being created.
local function usePointerPosition(guiObject: Types.Value<GuiObject?>): () -> Vector2
	local position = Vide.source(Vector2.zero)

	Vide.effect(function()
		local target: GuiObject? = Value.read(guiObject)
		if not target then
			return
		end

		local function setPositionFromInput(input: InputObject)
			if input.Position.X > 0 or input.Position.Y > 0 then
				position(Vector2.new(input.Position.X, input.Position.Y))
			end
		end

		Vide.cleanup(target.InputBegan:Connect(setPositionFromInput))
		Vide.cleanup(target.InputChanged:Connect(setPositionFromInput))
		Vide.cleanup(target.InputEnded:Connect(setPositionFromInput))
	end)

	return position
end

return usePointerPosition
