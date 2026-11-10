local Vide = require("../../../Packages/Vide")

local Breakpoint = require("../../../Enums/Breakpoint")
local Constants = require("../../../Constants")
local Dash = require("../../../Utility/Dash")
local ResponsiveContext = require("../ResponsiveContext")
local Types = require("../../../Components/Types")
local Value = require("../../../Utility/Value")
local useResponsive = require("../useResponsive")

type BreakpointConfig = ResponsiveContext.BreakpointConfig
type Breakpoint = Breakpoint.Breakpoint
type Value<T> = Types.Value<T>

export type UseBreakpointOptions = {
	-- Seconds to throttle AbsoluteSize changes by.
	throttleTime: number?,
}

--* Keeps the breakpoint from flickering when the width sits on a boundary.
local BUFFER = 5

local function calculateBreakpointFromWidth(breakpointConfig: BreakpointConfig, width: number): Breakpoint
	for _, breakpoint in breakpointConfig.order do
		if width <= breakpointConfig.widths[breakpoint] then
			return breakpoint
		end
	end
	return breakpointConfig.order[#breakpointConfig.order]
end

local function shouldChangeBreakpoint(
	breakpointConfig: BreakpointConfig,
	currentWidth: number,
	candidateBreakpoint: Breakpoint,
	previousBreakpoint: Breakpoint
): boolean
	if candidateBreakpoint == previousBreakpoint then
		return false
	end

	local previousIndex = table.find(breakpointConfig.order, previousBreakpoint) or 0
	local candidateIndex = table.find(breakpointConfig.order, candidateBreakpoint) or 0
	if candidateIndex > previousIndex then
		return currentWidth > breakpointConfig.widths[previousBreakpoint] + BUFFER
	end
	return currentWidth < breakpointConfig.widths[candidateBreakpoint] - BUFFER
end

--- The breakpoint for `instance`'s width and its AbsoluteSize, as sources. Before the instance exists the width is 0.
local function useBreakpoint(instance: Value<GuiBase2d?>, options: UseBreakpointOptions?): (() -> Breakpoint, () -> Vector2)
	local throttleTime = if options and options.throttleTime then options.throttleTime else Constants.DEFAULT_DELAY_TIME
	local responsive = useResponsive()
	local function breakpointConfig(): BreakpointConfig
		return responsive().config.breakpoint
	end

	local absoluteSize = Vide.source(Vector2.zero)
	local setAbsoluteSizeThrottled = Dash.throttle(function(size: Vector2)
		absoluteSize(size)
	end, throttleTime, { leading = true, trailing = true })

	Vide.effect(function()
		local target: GuiBase2d? = Value.read(instance)
		if target then
			Vide.cleanup(target:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				setAbsoluteSizeThrottled(target.AbsoluteSize)
			end))
			absoluteSize(target.AbsoluteSize)
		end
	end)

	local stableBreakpoint = Vide.source(Vide.untrack(function(): Breakpoint
		return calculateBreakpointFromWidth(breakpointConfig(), absoluteSize().X)
	end))
	Vide.effect(function()
		local config = breakpointConfig()
		local width = absoluteSize().X
		local candidate = calculateBreakpointFromWidth(config, width)
		Vide.untrack(function()
			if shouldChangeBreakpoint(config, width, candidate, stableBreakpoint()) then
				stableBreakpoint(candidate)
			end
		end)
	end)

	return function()
		return stableBreakpoint()
	end, function()
		return absoluteSize()
	end
end

return useBreakpoint
