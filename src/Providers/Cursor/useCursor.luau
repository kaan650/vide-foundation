local ColorNamespace = require("../../Enums/ColorNamespace")
local CursorContext = require("./CursorContext")
local KeyUtilities = require("./KeyUtilities")
local PresentationContext = require("../Style/PresentationContext")
local Types = require("../../Components/Types")
local useTokens = require("../Style/useTokens")

type ColorNamespace = ColorNamespace.ColorNamespace

--- The selection cursor for `cursor` as a source, for a GuiObject's `SelectionImageObject`.
local function useCursor(cursor: Types.Cursor?): () -> GuiObject?
	local tokens = useTokens()
	local colorNamespace = PresentationContext.usePresentationContext().colorNamespace or ColorNamespace.Color
	local context = CursorContext()

	return function()
		local key
		if typeof(cursor) == "table" then
			key = KeyUtilities.encodeKey(tokens(), cursor.radius, cursor.offset, cursor.borderWidth, colorNamespace)
		elseif cursor == nil then
			key = KeyUtilities.encodeKey(tokens(), nil, nil, nil, colorNamespace)
		else
			key = KeyUtilities.encodeCursorTypeKey(cursor, colorNamespace)
		end
		return context.requestCursor(key)()
	end
end

return useCursor
