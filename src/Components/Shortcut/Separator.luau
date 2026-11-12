local ShortcutSeparator = require("../../Enums/ShortcutSeparator")
local Text = require("../Text")
local useShortcutVariants = require("./useShortcutVariants")

type ShortcutSeparator = ShortcutSeparator.ShortcutSeparator
type ShortcutVariantProps = useShortcutVariants.ShortcutVariantProps

local GLYPHS: { [ShortcutSeparator]: string } = {
	[ShortcutSeparator.Or] = "/",
	[ShortcutSeparator.More] = "\u{2026}",
}

type SeparatorProps = {
	separator: ShortcutSeparator,
	variantProps: ShortcutVariantProps,
	LayoutOrder: number,
	testId: string,
}

--- The glyph between two keys of a Shortcut that are not a chord.
local function Separator(props: SeparatorProps): GuiObject
	return Text({
		Text = GLYPHS[props.separator],
		tag = props.variantProps.separator.tag,
		LayoutOrder = props.LayoutOrder,
		testId = props.testId,
	})
end

return Separator
