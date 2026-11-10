local DialogActions = require("@self/Actions")
local DialogContent = require("@self/Content")
local DialogHeroMedia = require("@self/HeroMedia")
local DialogRoot = require("@self/Dialog")
local DialogText = require("@self/Text")
local DialogTitle = require("@self/Title")

export type DialogProps = DialogRoot.DialogProps
export type DialogAction = DialogActions.DialogAction
export type DialogActionsProps = DialogActions.DialogActionsProps
export type DialogContentProps = DialogContent.DialogContentProps
export type DialogTextProps = DialogText.DialogTextProps
export type DialogHeroMediaProps = DialogHeroMedia.DialogHeroMediaProps
export type DialogTitleProps = DialogTitle.DialogTitleProps

return {
	Root = DialogRoot,
	Actions = DialogActions,
	Content = DialogContent,
	Text = DialogText,
	HeroMedia = DialogHeroMedia,
	Title = DialogTitle,
}
