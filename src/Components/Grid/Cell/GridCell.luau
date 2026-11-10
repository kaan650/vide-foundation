local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local getFormattedTags = require("../../../Utility/getFormattedTags")
local getGridSizeTag = require("../../../Utility/getGridSizeTag")
local withDefaults = require("../../../Utility/withDefaults")

type ResponsiveValue<T> = Types.ResponsiveValue<T>
type Value<T> = Types.Value<T>

export type GridCellProps = {
	-- Columns the cell spans: a number, or a map from breakpoint short names (xs, sm...) to numbers. 0 hides it.
	size: Value<number | ResponsiveValue<number>>?,
} & Types.GuiObjectProps & Types.CommonProps

local defaultProps = {
	size = 1,
	testId = "--foundation-grid--cell",
}

--- A View that spans `size` columns of the Grid it is in.
local function GridCell(gridCellProps: GridCellProps): GuiObject
	local props = withDefaults(gridCellProps, defaultProps)
	local viewProps: any = table.clone(props)
	viewProps.size = nil
	viewProps.tag = function(): string
		local sizeTag = getGridSizeTag(Value.read(props.size))
		local tag = getFormattedTags(Value.read(props.tag))
		return if tag then `{sizeTag} {tag}` else sizeTag
	end
	return View(viewProps)
end

return GridCell
