local Types = require("../../Types")
local View = require("../../View")
local useTile = require("../useTile")

export type TileFooterProps = {
	children: Types.Children?,
}

--- The tile's footer, below its header.
local function TileFooter(props: TileFooterProps): GuiObject
	local tileContext = useTile()

	return View({
		LayoutOrder = 2,
		tag = "shrink size-full-0 auto-y",
		testId = `{tileContext.testId}--footer`,
		children = props.children,
	})
end

return TileFooter
