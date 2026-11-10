local Icon = require("../Icon")
local IconSize = require("../../Enums/IconSize")
local Types = require("../Types")
local View = require("../View")
local useRotation = require("../../Utility/useRotation")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type IconSize = IconSize.IconSize
type Value<T> = Types.Value<T>

export type LoadingProps = {
	size: Value<IconSize>?,
} & Types.CommonProps

local defaultProps = {
	size = IconSize.Large,
	testId = "--foundation-loading",
}

--- A spinning loading indicator.
local function Loading(loadingProps: LoadingProps): GuiObject
	local props = withDefaults(loadingProps, defaultProps)
	local rotation = useRotation()
	local tokens = useTokens()

	local icon = Icon({
		name = "icons/graphic/loadingspinner",
		size = props.size,
		style = function()
			return tokens().DarkMode.Content.Emphasis :: any
		end,
		Rotation = rotation,
		testId = `{props.testId}--icon`,
	})
	icon.Name = "Icon"

	return View(withCommonProps(props, {
		tag = "auto-xy",
		children = icon,
	}) :: any)
end

return Loading
