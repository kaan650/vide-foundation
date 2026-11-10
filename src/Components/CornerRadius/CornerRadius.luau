local Types = require("../Types")
local create = require("../../Utility/create")
local getTestIdTag = require("../../Utility/getTestIdTag")
local tags = require("../../Utility/tags")

type CornerRadius = Types.CornerRadius
type CornerRadiusValue = Types.CornerRadiusValue
type CornerRadiusTable = Types.CornerRadiusTable
type Value<T> = Types.Value<T>

local function numberToUDim(value: number | UDim): UDim
	return if typeof(value) == "number" then UDim.new(0, value) else value
end

local function toUDim(value: CornerRadiusValue?): Value<UDim>?
	if value == nil then
		return nil
	elseif type(value) == "function" then
		local source = value :: () -> number | UDim
		return function()
			return numberToUDim(source())
		end
	end
	return numberToUDim(value :: number | UDim)
end

local function getCornerRadius(cornerRadius: CornerRadius): {
	TopLeftRadius: Value<UDim>?,
	TopRightRadius: Value<UDim>?,
	BottomRightRadius: Value<UDim>?,
	BottomLeftRadius: Value<UDim>?,
}
	if type(cornerRadius) == "table" then
		local corners = cornerRadius :: CornerRadiusTable
		return {
			TopLeftRadius = toUDim(corners.topLeft),
			TopRightRadius = toUDim(corners.topRight),
			BottomRightRadius = toUDim(corners.bottomRight),
			BottomLeftRadius = toUDim(corners.bottomLeft),
		}
	end
	local radius = toUDim(cornerRadius :: CornerRadiusValue)
	return {
		TopLeftRadius = radius,
		TopRightRadius = radius,
		BottomRightRadius = radius,
		BottomLeftRadius = radius,
	}
end

export type CornerRadiusProps = {
	value: CornerRadius,
	testId: string?,
}

local function CornerRadius(props: CornerRadiusProps): UICorner
	local cornerRadius = getCornerRadius(props.value)
	return create("UICorner")({
		TopLeftRadius = cornerRadius.TopLeftRadius,
		TopRightRadius = cornerRadius.TopRightRadius,
		BottomRightRadius = cornerRadius.BottomRightRadius,
		BottomLeftRadius = cornerRadius.BottomLeftRadius,
		tags(getTestIdTag(props.testId)),
	}) :: UICorner
end

return CornerRadius
