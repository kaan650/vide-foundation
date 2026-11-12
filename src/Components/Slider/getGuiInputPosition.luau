local GuiService = require("../../Utility/Wrappers/Services").GuiService

--- A UIDragDetector input position in the space of `guiObject.AbsolutePosition`: the two can differ with the app
--- nav-rail, the in-game topbar or Storybook screen insets.
local function getGuiInputPosition(inputPosition: Vector2, guiObject: GuiObject): Vector2
	local screenGui = guiObject:FindFirstAncestorWhichIsA("ScreenGui")
	if screenGui then
		if not screenGui.IgnoreGuiInset then
			return inputPosition
		end

		local inputInsets = if screenGui.ScreenInsets == Enum.ScreenInsets.DeviceSafeInsets
			then Enum.ScreenInsets.DeviceSafeInsets
			else Enum.ScreenInsets.None
		local inputArea = GuiService:GetInsetArea(inputInsets)
		return inputPosition + inputArea.Min
	else
		return inputPosition
	end
end

return getGuiInputPosition
