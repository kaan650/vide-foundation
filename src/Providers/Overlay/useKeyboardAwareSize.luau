local Vide = require("../../Packages/Vide")

local Wrappers = require("../../Utility/Wrappers")
local GuiService = Wrappers.Services.GuiService
local UserInputService = Wrappers.Services.UserInputService

--- The screen's size minus the part covered by the on-screen keyboard, as a source.
local function useKeyboardAwareSize(screen: GuiBase2d): () -> UDim2
	local safeAreaSize = Vide.source(UDim2.fromScale(1, 1))

	local function updateSafeAreaSize()
		if not UserInputService.OnScreenKeyboardVisible then
			safeAreaSize(UDim2.fromScale(1, 1))
			return
		end
		local topLeftInset = GuiService:GetGuiInset()
		local keyboardPositionY = UserInputService.OnScreenKeyboardPosition.Y - topLeftInset.Y
		local bottomY = screen.AbsolutePosition.Y + screen.AbsoluteSize.Y
		local newSafeAreaSize = UDim2.new(1, 0, 1, -(bottomY - keyboardPositionY))
		if Vide.untrack(safeAreaSize) ~= newSafeAreaSize then
			safeAreaSize(newSafeAreaSize)
		end
	end

	updateSafeAreaSize()
	Vide.cleanup(UserInputService:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(updateSafeAreaSize))
	Vide.cleanup(UserInputService:GetPropertyChangedSignal("OnScreenKeyboardPosition"):Connect(updateSafeAreaSize))
	Vide.cleanup(screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSafeAreaSize))

	return safeAreaSize
end

return useKeyboardAwareSize
