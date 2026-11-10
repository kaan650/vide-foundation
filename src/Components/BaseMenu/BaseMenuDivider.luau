local Types = require("../Types")
local View = require("../View")
local useTokens = require("../../Providers/Style/useTokens")

type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

local function BaseMenuDivider(props: { LayoutOrder: Value<number> }): GuiObject
	local tokens = useTokens()

	local line = View({
		tag = "grow size-0-full",
		backgroundStyle = function(): ColorStyleValue
			return tokens().Color.Stroke.Default :: ColorStyleValue
		end,
	})
	line.Name = "Children"

	return View({
		LayoutOrder = props.LayoutOrder,
		Size = function()
			return UDim2.new(1, 0, 0, tokens().Stroke.Standard)
		end,
		tag = "row flex-x-fill",
		testId = "--foundation-menu-divider-item",
		children = line,
	})
end

return BaseMenuDivider
