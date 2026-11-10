local Vide = require("../../Packages/Vide")

local ColorNamespace = require("../../Enums/ColorNamespace")
local Cursor = require("./Cursors/Cursor")
local CursorComponent = require("./CursorComponent")
local CursorContext = require("./CursorContext")
local CursorType = require("../../Enums/CursorType")
local KeyUtilities = require("./KeyUtilities")
local create = require("../../Utility/create")

type CursorType = CursorType.CursorType
type ColorNamespace = ColorNamespace.ColorNamespace

type Props = {
	children: (() -> any)?,
}

--- Owns the selection cursors (SelectionImageObject targets). A cursor is made the first time a component asks for
--- its key and lives in a hidden frame until the provider is destroyed.
local function CursorProvider(props: Props)
	local mountedKeys = Vide.source({} :: { [string]: boolean })
	local instances: { [string]: Vide.Source<GuiObject?> } = {}

	local function instanceSource(key: string): Vide.Source<GuiObject?>
		local source = instances[key]
		if not source then
			source = Vide.source(nil :: GuiObject?)
			instances[key] = source
		end
		return source
	end

	local function requestCursor(key: string): () -> GuiObject?
		local source = instanceSource(key)
		local mounted = Vide.untrack(mountedKeys)
		if not mounted[key] then
			local nextMounted = table.clone(mounted)
			nextMounted[key] = true
			mountedKeys(nextMounted)
		end
		--! Calling a nullable source with no arguments is ambiguous to the type checker (centau/vide#71).
		return source :: any
	end

	local function renderCursor(key: string): GuiObject
		local keyParts = string.split(key, " ")
		local cursor
		if #keyParts == 2 then
			local cursorType, colorNamespace = KeyUtilities.decodeCursorTypeKey(keyParts)
			cursor = Cursor({ cursorType = cursorType, colorNamespace = colorNamespace })
		else
			local cornerRadius, offset, borderWidth, colorNamespace = KeyUtilities.decodeKey(keyParts)
			cursor = CursorComponent({
				cornerRadius = cornerRadius,
				offset = offset,
				borderWidth = borderWidth,
				colorNamespace = colorNamespace,
			})
		end
		cursor.Name = key
		instanceSource(key)(cursor)
		Vide.cleanup(function()
			instanceSource(key)(nil)
		end)
		return cursor
	end

	return CursorContext({ requestCursor = requestCursor }, function()
		return {
			if props.children then props.children() else nil,
			create("Frame")({
				Name = "FoundationCursorContainer",
				Size = UDim2.new(0, 0, 0, 0),
				Visible = false,

				Vide.indexes(mountedKeys, function(_, key: string)
					return renderCursor(key)
				end),
			}),
		}
	end)
end

return CursorProvider
