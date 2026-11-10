local Vide = require("../../../Packages/Vide")

local Padding = require("../../Padding")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local useTile = require("../useTile")
local useTokens = require("../../../Providers/Style/useTokens")
local withDefaults = require("../../../Utility/withDefaults")

export type TileContentProps = {
	children: Types.Children?,
	LayoutOrder: Types.Value<number>?,
}

local defaultProps = {
	LayoutOrder = 2,
}

--- The tile's text column, padded when the tile is contained.
local function TileContent(tileContentProps: TileContentProps): GuiObject
	local props = withDefaults(tileContentProps, defaultProps)
	local tokens = useTokens()
	local tileContext = useTile()
	local testId = `{tileContext.testId}--content`

	local function padding(): UDim
		return UDim.new(0, tokens().Padding.Small)
	end

	local isContained = tileContext.isContained
	local reactivePadding = if type(isContained) == "function"
		then Vide.show(function()
			return Value.read(isContained) == true
		end, function()
			local instance = Padding({ value = padding, testId = `{testId}--padding` })
			instance.Name = "Padding"
			return instance
		end)
		else nil

	return View({
		tag = "col align-y-top gap-small size-full",
		flexItem = {
			FlexMode = Enum.UIFlexMode.Shrink,
		},
		padding = if isContained == true then padding else nil,
		LayoutOrder = props.LayoutOrder,
		testId = testId,
		children = { reactivePadding, props.children },
	})
end

return TileContent
