local Vide = require("../../Packages/Vide")

local StatusBadgeShape = require("../../Enums/StatusBadgeShape")
type StatusBadgeShape = StatusBadgeShape.StatusBadgeShape
local StatusBadgeSize = require("../../Enums/StatusBadgeSize")
type StatusBadgeSize = StatusBadgeSize.StatusBadgeSize
local StatusBadgeVariant = require("../../Enums/StatusBadgeVariant")
type StatusBadgeVariant = StatusBadgeVariant.StatusBadgeVariant

local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local useScaledValue = require("../../Utility/useScaledValue")
local useStatusBadgeVariants = require("./useStatusBadgeVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ColorStyleValue = Types.ColorStyleValue
type ListLayout = Types.ListLayout
type Value<T> = Types.Value<T>

local MAX_CONTENT_WIDTH = 200

export type StatusBadgeProps = {
	text: Value<string>,
	variant: Value<StatusBadgeVariant>?,
	shape: Value<StatusBadgeShape>?,
	size: Value<StatusBadgeSize>?,
} & Types.CommonProps

local defaultProps = {
	variant = StatusBadgeVariant.Standard,
	shape = StatusBadgeShape.Utility,
	size = StatusBadgeSize.Small,
	testId = "--foundation-status-badge",
}

--- A short status text after a colored status dot.
local function StatusBadge(statusBadgeProps: StatusBadgeProps): GuiObject
	local props = withDefaults(statusBadgeProps, defaultProps)
	local tokens = useTokens()
	local maxWidth = useScaledValue(MAX_CONTENT_WIDTH)

	local variantProps = Vide.derive(function()
		return useStatusBadgeVariants(
			tokens(),
			Value.read(props.variant),
			Value.read(props.shape),
			Value.read(props.size)
		)
	end)

	local dot = View({
		tag = function()
			return variantProps().dot.tag
		end,
		LayoutOrder = 1,
		testId = `{props.testId}--dot`,
	})
	dot.Name = "Dot"

	local statusLight = View({
		tag = function()
			return variantProps().statusLight.tag
		end,
		LayoutOrder = 1,
		testId = `{props.testId}--status-light`,
		children = dot,
	})
	statusLight.Name = "StatusLight"

	local text = Text({
		Text = props.text,
		tag = function()
			return variantProps().text.tag
		end,
		textStyle = function(): ColorStyleValue
			return variantProps().text.style
		end,
		LayoutOrder = 2,
		sizeConstraint = {
			MaxSize = function()
				return Vector2.new(maxWidth(), math.huge)
			end,
		},
		testId = `{props.testId}--text`,
	})
	text.Name = "Text"

	local content = View({
		tag = function()
			return variantProps().content.tag
		end,
		layout = function(): ListLayout?
			local gap = variantProps().content.gap
			if not gap then
				return nil
			end
			return {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, gap),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}
		end,
		LayoutOrder = 1,
		testId = `{props.testId}--content`,
		children = { statusLight, text },
	})
	content.Name = "Content"

	return View(withCommonProps(props, {
		tag = function()
			return variantProps().container.tag
		end,
		children = content,
	}) :: any)
end

return StatusBadge
