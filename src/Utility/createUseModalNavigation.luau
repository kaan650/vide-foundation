local Types = require("../Components/Types")
type Value<T> = Types.Value<T>

export type ModalNavigation = {
	-- The modal's close button, for `NextSelection*` props of the content.
	closeAffordanceRef: () -> GuiObject?,
	-- Tells the close button which instance gamepad navigation moves down to.
	setContentStartRef: (ref: Value<GuiObject?>) -> (),
}

type ModalNavigationContext = {
	closeAffordanceRef: () -> GuiObject?,
	setContentStartRef: (ref: Value<GuiObject?>) -> (),
}

--- A hook reading the close button and content start of a Dialog or Sheet from `context`.
local function createUseModalNavigation(context: () -> ModalNavigationContext): () -> ModalNavigation
	return function(): ModalNavigation
		local ctx = context()

		return {
			closeAffordanceRef = ctx.closeAffordanceRef,
			setContentStartRef = ctx.setContentStartRef,
		}
	end
end

return createUseModalNavigation
