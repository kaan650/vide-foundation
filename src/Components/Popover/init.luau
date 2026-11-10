local Popover = require("@self/Popover")
local PopoverAnchor = require("@self/Anchor")
local PopoverContent = require("@self/Content")

export type PopoverProps = Popover.PopoverProps
export type PopoverAnchorProps = PopoverAnchor.PopoverAnchorProps
export type PopoverContentProps = PopoverContent.PopoverContentProps

--* Foundation picks a plugin-panel Content for elevated (internal) plugins; that path needs the StudioPanels and
--* StudioWidgets providers, which are not ported, so Content is always the overlay one.
return {
	Root = Popover,
	Anchor = PopoverAnchor,
	Content = PopoverContent,
}
