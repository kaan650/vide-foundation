local UserInputService = require("../../Utility/Wrappers").Services.UserInputService

export type KeyVisual = {
	keyVisualType: "Image" | "String",
	size: UDim2,
	key: string,
}

local keyCodeMap: { [Enum.KeyCode]: KeyVisual } = {}

--- How a key is drawn: the platform's image for it when there is one, otherwise its name on a keycap.
return function(keyCode: Enum.KeyCode): KeyVisual
	if keyCodeMap[keyCode] then
		return keyCodeMap[keyCode]
	end

	local key = UserInputService:GetImageForKeyCode(keyCode)
	if key and key ~= "" then
		return {
			keyVisualType = "Image",
			size = UDim2.fromScale(0.7, 0.7),
			key = key,
		}
	end

	local keyVisual: KeyVisual = {
		keyVisualType = "String",
		size = UDim2.fromScale(0.8, 0.8),
		key = UserInputService:GetStringForKeyCode(keyCode) or "",
	}
	keyCodeMap[keyCode] = keyVisual
	return keyVisual
end
