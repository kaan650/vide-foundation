local Types = require("../Types")
local create = require("../../Utility/create")
local getTestIdTag = require("../../Utility/getTestIdTag")
local tags = require("../../Utility/tags")

type Padding = Types.Padding
type PaddingTable = Types.PaddingTable
type Value<T> = Types.Value<T>

type Sides = {
	PaddingTop: Value<UDim>?,
	PaddingBottom: Value<UDim>?,
	PaddingLeft: Value<UDim>?,
	PaddingRight: Value<UDim>?,
}

local function getPadding(padding: Padding): Sides
	if type(padding) == "function" then
		local source = padding :: () -> UDim
		return { PaddingTop = source, PaddingBottom = source, PaddingLeft = source, PaddingRight = source }
	elseif type(padding) == "table" then
		local sides = padding :: PaddingTable
		return {
			PaddingTop = sides.top,
			PaddingBottom = sides.bottom,
			PaddingLeft = sides.left,
			PaddingRight = sides.right,
		}
	elseif typeof(padding) == "number" then
		local udim = UDim.new(0, padding :: number)
		return { PaddingTop = udim, PaddingBottom = udim, PaddingLeft = udim, PaddingRight = udim }
	elseif typeof(padding) == "Vector2" then
		local vector = padding :: Vector2
		return {
			PaddingTop = UDim.new(0, vector.Y),
			PaddingBottom = UDim.new(0, vector.Y),
			PaddingLeft = UDim.new(0, vector.X),
			PaddingRight = UDim.new(0, vector.X),
		}
	elseif typeof(padding) == "UDim" then
		local udim = padding :: UDim
		return { PaddingTop = udim, PaddingBottom = udim, PaddingLeft = udim, PaddingRight = udim }
	elseif typeof(padding) == "UDim2" then
		local udim2 = padding :: UDim2
		return { PaddingTop = udim2.Y, PaddingBottom = udim2.Y, PaddingLeft = udim2.X, PaddingRight = udim2.X }
	end
	return {}
end

export type PaddingProps = {
	value: Padding,
	testId: string?,
}

local function Padding(props: PaddingProps): UIPadding
	local padding = getPadding(props.value)
	return create("UIPadding")({
		PaddingTop = padding.PaddingTop,
		PaddingBottom = padding.PaddingBottom,
		PaddingLeft = padding.PaddingLeft,
		PaddingRight = padding.PaddingRight,
		tags(getTestIdTag(props.testId)),
	}) :: UIPadding
end

return Padding
