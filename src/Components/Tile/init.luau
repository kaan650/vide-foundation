local Actions = require("@self/Actions")
local Content = require("@self/Content")
local Footer = require("@self/Footer")
local Header = require("@self/Header")
local Media = require("@self/Media")
local Tile = require("@self/Tile")

export type TileProps = Tile.TileProps
export type TileActionsProps = Actions.TileActionsProps
export type TileContentProps = Content.TileContentProps
export type TileFooterProps = Footer.TileFooterProps
export type TileHeaderProps = Header.TileHeaderProps
export type TileMediaProps = Media.TileMediaProps

return {
	Root = Tile,
	Actions = Actions,
	Content = Content,
	Footer = Footer,
	Header = Header,
	Media = Media,
}
