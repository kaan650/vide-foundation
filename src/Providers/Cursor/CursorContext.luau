local Vide = require("../../Packages/Vide")

local Logger = require("../../Utility/Logger")

export type CursorContextValue = {
	-- Returns a source of the cursor instance for `key`, creating the cursor on first use.
	requestCursor: (key: string) -> () -> GuiObject?,
}

local warned = false
local function missingProvider(_key: string): () -> GuiObject?
	if not warned then
		warned = true
		Logger:warning("No CursorProvider found")
	end
	return function()
		return nil
	end
end

return Vide.context({
	requestCursor = missingProvider,
} :: CursorContextValue)
