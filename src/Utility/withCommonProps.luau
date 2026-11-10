local Types = require("../Components/Types")
type CommonProps = Types.CommonProps

--- Copies the props every Foundation component forwards into `baseProps`, for passing them on to another
--- Foundation component.
local function withCommonProps<T>(props: CommonProps, baseProps: T): T & CommonProps
	local target = baseProps :: any
	target.AnchorPoint = props.AnchorPoint
	target.LayoutOrder = props.LayoutOrder
	target.Position = props.Position
	target.Visible = props.Visible
	target.ZIndex = props.ZIndex
	target.onAbsoluteSizeChanged = props.onAbsoluteSizeChanged
	target.onAbsolutePositionChanged = props.onAbsolutePositionChanged
	target.testId = props.testId
	return target
end

return withCommonProps
