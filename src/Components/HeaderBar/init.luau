local HeaderBarActions = require("@self/Actions")
local HeaderBarContent = require("@self/Content")
local HeaderBarLeading = require("@self/Leading")
local HeaderBarRoot = require("@self/HeaderBar")
local HeaderBarTrailing = require("@self/Trailing")

local HeaderBar = {
	Root = HeaderBarRoot,
	Leading = HeaderBarLeading,
	Trailing = HeaderBarTrailing,
	Content = HeaderBarContent,
	Actions = HeaderBarActions,
}

export type HeaderBarProps = HeaderBarRoot.HeaderBarProps
export type HeaderBarLeadingProps = HeaderBarLeading.HeaderBarLeadingProps
export type HeaderBarTrailingProps = HeaderBarTrailing.HeaderBarTrailingProps
export type HeaderBarContentProps = HeaderBarContent.HeaderBarContentProps
export type HeaderBarActionsProps = HeaderBarActions.HeaderBarActionsProps
export type HeaderBarAction = HeaderBarActions.HeaderBarAction

return HeaderBar
