local GuiService = game:GetService("GuiService")

local success, scale = pcall(GuiService.GetResolutionScale, GuiService)

local FoundationImages = script.Parent
local GetImageSetData = require(FoundationImages.Generated.GetImageSetData)

if not success then
	--* GetResolutionScale is RobloxScript-only, so every game lands here. Roblox's CoreGui picks 2x sprites on most
	--* displays, and a 1x sprite drawn past 100% shows jagged edges (VideTopbar's tooltip caret), so default to 2x.
	scale = 2
end

-- Both this and the resolution scale should probably be provided to Foundation via some
-- prop or context, maybe even token, rather than us calling GuiService directly.
if GuiService:IsTenFootInterface() then
	scale = 3
end

local function getResolutionScale(): number
	local _, imageScale = GetImageSetData(scale)
	return imageScale
end

return getResolutionScale
