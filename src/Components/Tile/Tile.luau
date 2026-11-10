local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local TileContext = require("./TileContext")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type Value<T> = Types.Value<T>

export type TileProps = {
	isContained: Value<boolean>?,
	onStateChanged: Types.StateChangedCallback?,
	FillDirection: Value<Enum.FillDirection>?,
	Size: Value<UDim2>,
	-- Builds the tile's parts (`Tile.Media`, `Tile.Content`...), which must be created inside it to read its
	-- configuration.
	children: (() -> any)?,
} & Types.CommonProps

local defaultProps = {
	FillDirection = Enum.FillDirection.Vertical,
	isContained = false,
	testId = "--foundation-tile",
}

--- A card laid out vertically or horizontally from `Tile.Media`, `Tile.Content`, `Tile.Header`, `Tile.Footer` and
--- `Tile.Actions`.
local function Tile(tileProps: TileProps): GuiObject
	local props = withDefaults(tileProps, defaultProps)
	local buildChildren = props.children

	local children = if buildChildren
		then TileContext({
			isContained = props.isContained,
			fillDirection = props.FillDirection,
			testId = props.testId,
		}, buildChildren)
		else nil

	return View(withCommonProps(props, {
		tag = function()
			local isContained = Value.read(props.isContained) == true
			return {
				["bg-shift-200"] = isContained,
				["gap-small"] = not isContained,
				["radius-medium"] = true,
			}
		end,
		stateLayer = {
			affordance = StateLayerAffordance.None,
		},
		onStateChanged = props.onStateChanged,
		layout = {
			FillDirection = props.FillDirection,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		Size = props.Size,
		children = children,
	}) :: any)
end

return Tile
