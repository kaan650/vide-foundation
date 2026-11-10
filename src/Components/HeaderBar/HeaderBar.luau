local Breakpoint = require("../../Enums/Breakpoint")
local HeaderBarContext = require("./HeaderBarContext")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local useViewportBreakpoint = require("../../Providers/Responsive/Hooks/useViewportBreakpoint")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type Breakpoint = Breakpoint.Breakpoint
type Value<T> = Types.Value<T>

local SIZE_TAG_BY_BREAKPOINT: { [Breakpoint]: string } = {
	[Breakpoint.XSmall] = "size-full-1400",
	[Breakpoint.Small] = "size-full-1400",
	[Breakpoint.Medium] = "size-full-1600",
	[Breakpoint.Large] = "size-full-1600",
	[Breakpoint.XLarge] = "size-full-1800",
	[Breakpoint.XXLarge] = "size-full-1800",
}

export type HeaderBarProps = {
	hasBackground: Value<boolean>?,
	-- Builds the bar's slots (`HeaderBar.Leading`, `HeaderBar.Content`, `HeaderBar.Trailing`), which must be created
	-- inside it.
	children: (() -> any)?,
} & Types.CommonProps

local defaultProps = {
	hasBackground = true,
	testId = "--foundation-header-bar",
}

--- A full-width top bar whose height follows the viewport breakpoint. Its slots read the bar's testId from context.
local function HeaderBar(headerBarProps: HeaderBarProps): GuiObject
	local props = withDefaults(headerBarProps, defaultProps)
	local breakpoint = useViewportBreakpoint()
	local children = props.children

	return View(withCommonProps(props, {
		tag = function()
			return {
				["row flex-between gap-small padding-medium"] = true,
				["bg-surface-0"] = Value.read(props.hasBackground) == true,
				[SIZE_TAG_BY_BREAKPOINT[breakpoint()]] = true,
			}
		end,
		children = if children then HeaderBarContext({ testId = props.testId }, children) else nil,
	}) :: any)
end

return HeaderBar
