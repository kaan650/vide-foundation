local TileContext = require("./TileContext")

export type TileConfiguration = TileContext.TileConfiguration

--- The enclosing `Tile.Root`'s configuration. Call it while the part is being created.
local function useTile(): TileConfiguration
	return TileContext()
end

return useTile
