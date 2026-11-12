local Vide = require("../../Packages/Vide")

local Dash = require("../../Utility/Dash")
local Text = require("../Text")
local Types = require("../Types")
local ValidNumericVariants = require("./ValidNumericVariants")
local Value = require("../../Utility/Value")
local View = require("../View")
local devAssert = require("../../Utility/devAssert")
local useStatusIndicatorVariants = require("./useStatusIndicatorVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local StatusIndicatorSize = require("../../Enums/StatusIndicatorSize")
type StatusIndicatorSize = StatusIndicatorSize.StatusIndicatorSize
local StatusIndicatorVariant = require("../../Enums/StatusIndicatorVariant")
type StatusIndicatorVariant = StatusIndicatorVariant.StatusIndicatorVariant
local StatusIndicatorShape = require("../../Enums/StatusIndicatorShape")
type StatusIndicatorShape = StatusIndicatorShape.StatusIndicatorShape

type ColorStyle = Types.ColorStyle
type ColorStyleValue = Types.ColorStyleValue
type FontStyle = Types.FontStyle
type Value<T> = Types.Value<T>

export type StatusIndicatorNumericVariant =
	typeof(StatusIndicatorVariant.Emphasis)
	| typeof(StatusIndicatorVariant.Standard)
	| typeof(StatusIndicatorVariant.Alert)
	| typeof(StatusIndicatorVariant.Contrast_Experiment)

export type StatusIndicatorProps = {
	-- With a `value`, only Emphasis and Standard are supported.
	variant: Value<StatusIndicatorVariant>?,
	-- Ignored while `value` is set: a numeric indicator is always a circle.
	shape: Value<StatusIndicatorShape>?,
	size: Value<StatusIndicatorSize>?,
	-- Color of a stroke around the indicator, to cut it out of what it overlaps.
	mask: ColorStyle?,
	-- The number shown. Without it the indicator is a dot.
	value: Value<number?>?,
	-- Values above `max` show as "max+".
	max: Value<number>?,
} & Types.CommonProps

local defaultProps = {
	variant = StatusIndicatorVariant.Standard,
	shape = StatusIndicatorShape.Circle,
	size = StatusIndicatorSize.Small,
	max = math.huge,
	testId = "--foundation-status-indicator",
}

--- A status dot, ring or square, or a count in a pill.
local function StatusIndicator(statusIndicatorProps: StatusIndicatorProps): GuiObject
	local props = withDefaults(statusIndicatorProps, defaultProps)
	local tokens = useTokens()

	local function value(): number?
		return Value.read(props.value)
	end
	local hasValue = Vide.derive(function()
		return value() ~= nil
	end)
	local shape = Vide.derive(function(): StatusIndicatorShape
		return if hasValue() then StatusIndicatorShape.Circle else Value.read(props.shape)
	end)

	local variantProps = Vide.derive(function()
		local variant: StatusIndicatorVariant = Value.read(props.variant)
		if hasValue() then
			devAssert(
				ValidNumericVariants[variant],
				`{variant} is not a supported numeric variant. The following are valid numeric variants: {table.concat(
					Dash.keys(ValidNumericVariants),
					","
				)}`
			)
		end
		return useStatusIndicatorVariants(tokens(), variant, hasValue(), shape(), Value.read(props.size), props.mask)
	end)

	local function formatValue(): string
		local current = value()
		if current == nil then
			return ""
		end
		local max: number = Value.read(props.max)
		return if current > max then `{max}+` else tostring(current)
	end

	local text = Vide.show(function()
		return hasValue() and variantProps().content.style ~= nil
	end, function()
		local label = Text({
			Text = formatValue,
			textStyle = function(): ColorStyleValue
				return variantProps().content.style :: ColorStyleValue
			end,
			fontStyle = function(): FontStyle
				local content = variantProps().content
				return {
					Font = content.font,
					FontSize = content.typography.FontSize,
					LineHeight = content.typography.LineHeight,
				}
			end,
			tag = function()
				return variantProps().content.tag
			end,
			testId = `{props.testId}--text`,
		})
		label.Name = "Text"
		return label
	end)

	local innerRing = Vide.show(function()
		return shape() == StatusIndicatorShape.Ring and variantProps().ring ~= nil
	end, function()
		local ring = View({
			tag = function()
				local current = variantProps().ring
				return if current then current.tag else nil
			end,
			Size = function()
				local current = variantProps().ring
				return if current and current.size then current.size else UDim2.new()
			end,
			testId = `{props.testId}--ring`,
		})
		ring.Name = "InnerRing"
		return ring
	end)

	return View(withCommonProps(props, {
		tag = function()
			return variantProps().container.tag
		end,
		backgroundStyle = function(): ColorStyleValue?
			return variantProps().container.backgroundStyle
		end,
		stroke = if props.mask ~= nil
			then function()
				return variantProps().stroke
			end
			else nil,
		children = {
			Value.bindProperty("Size", function()
				return variantProps().container.size
			end),
			text,
			innerRing,
		},
	}) :: any)
end

return StatusIndicator
