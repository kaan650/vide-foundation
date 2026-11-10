local Types = require("../Types")
local create = require("../../Utility/create")
local getTestIdTag = require("../../Utility/getTestIdTag")
local tags = require("../../Utility/tags")

type AspectRatio = Types.AspectRatio

export type AspectRatioProps = {
	value: AspectRatio,
	testId: string?,
}

local function AspectRatio(props: AspectRatioProps): UIAspectRatioConstraint
	local value = props.value
	local isTable = type(value) == "table"

	return create("UIAspectRatioConstraint")({
		AspectRatio = if isTable then (value :: Types.AspectRatioTable).AspectRatio else value :: Types.Value<number>,
		AspectType = if isTable then (value :: Types.AspectRatioTable).AspectType else nil,
		DominantAxis = if isTable then (value :: Types.AspectRatioTable).DominantAxis else nil,
		tags(getTestIdTag(props.testId)),
	}) :: UIAspectRatioConstraint
end

return AspectRatio
