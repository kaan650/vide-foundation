local Vide = require("../../Packages/Vide")

local DialogSize = require("../../Enums/DialogSize")
local Types = require("../Types")
type DialogSize = DialogSize.DialogSize
type Value<T> = Types.Value<T>

export type DialogContextValue = {
	size: () -> DialogSize,
	responsiveSize: () -> DialogSize,
	setResponsiveSize: (size: DialogSize) -> (),
	hasHeroMedia: () -> boolean,
	setHasHeroMedia: (hasHeroMedia: boolean) -> (),
	testId: string,
	closeAffordanceRef: () -> GuiObject?,
	setCloseAffordanceRef: (instance: GuiObject?) -> (),
	contentStartRef: () -> GuiObject?,
	setContentStartRef: (ref: Value<GuiObject?>) -> (),
}

local function small(): DialogSize
	return DialogSize.Small
end

local function none(): GuiObject?
	return nil
end

return Vide.context({
	size = small,
	responsiveSize = small,
	setResponsiveSize = function(_size: DialogSize) end,
	hasHeroMedia = function()
		return false
	end,
	setHasHeroMedia = function(_hasHeroMedia: boolean) end,
	testId = "",
	closeAffordanceRef = none,
	setCloseAffordanceRef = function(_instance: GuiObject?) end,
	contentStartRef = none,
	setContentStartRef = function(_ref: Value<GuiObject?>) end,
} :: DialogContextValue)
