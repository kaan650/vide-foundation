local Types = require("../../Types")
local View = require("../../View")
local useTile = require("../useTile")

export type TileActionsProps = {
	Visible: Types.Value<boolean>?,
	children: Types.Children?,
}

--- The tile's action row, below its content.
local function TileActions(props: TileActionsProps): GuiObject
	local tileContext = useTile()

	return View({
		Visible = props.Visible,
		LayoutOrder = 3,
		tag = "shrink size-full-0 auto-y",
		testId = `{tileContext.testId}--actions`,
		children = props.children,
	})
end

return TileActions
