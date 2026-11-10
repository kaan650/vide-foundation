local Vide = require("../../../Packages/Vide")

local Constants = require("../../../Constants")
local ControlState = require("../../../Enums/ControlState")
local StateLayerMode = require("../../../Enums/StateLayerMode")
local Text = require("../../Text")
local Types = require("../../Types")
local View = require("../../View")
local named = require("../../../Utility/named")
local rebuildOn = require("../../../Utility/rebuildOn")
local useTokens = require("../../../Providers/Style/useTokens")

type ControlState = ControlState.ControlState
type ColorStyleValue = Types.ColorStyleValue
type Tags = Types.Tags

export type CalendarGridDayLabelProps = {
	-- Connector band behind a selected range end, so its circle bridges into the in-range cells next to it.
	bandPosition: () -> UDim2?,
	bandRadiusTag: () -> string?,
	bandSize: () -> UDim2?,
	emphasizeText: () -> boolean?,
	highlight: boolean?,
	isSelectable: () -> boolean,
	isSelected: () -> boolean,
	LayoutOrder: number,
	onActivated: () -> (),
	onHoverEnter: (() -> ())?,
	testId: string?,
	label: string,
}

local function buildDayTags(isInRangeDay: boolean, bandRadiusTag: string?): { [string]: boolean }
	local dayTags: { [string]: boolean } = {
		["size-full text-title-small text-align-x-center text-align-y-center"] = true,
		["radius-circle"] = not isInRangeDay,
	}
	if isInRangeDay and bandRadiusTag and bandRadiusTag ~= "" then
		dayTags[bandRadiusTag] = true
	end
	return dayTags
end

--- One day of a calendar: a circular label, with a connector band behind it when it ends a selected range.
local function CalendarGridDayLabel(props: CalendarGridDayLabelProps): GuiObject
	local tokens = useTokens()
	local isSelected = props.isSelected
	local isSelectable = props.isSelectable

	local function dimmed(): boolean
		return not isSelectable() or not props.emphasizeText()
	end

	local onHoverEnter = props.onHoverEnter
	local onStateChanged = if onHoverEnter
		then function(newState: ControlState)
			if newState == ControlState.Hover then
				onHoverEnter()
			end
		end
		else nil

	local function activate()
		props.onActivated()
	end

	local function dayElement(selectable: boolean): GuiObject
		return Text({
			backgroundStyle = (function(): ColorStyleValue?
				local current = tokens()
				return if isSelected()
					then current.Color.System.Contrast :: any
					elseif props.highlight then current.Color.ActionStandard.Background :: any
					else nil
			end) :: any,
			onActivated = if selectable then activate else nil,
			onStateChanged = if selectable then onStateChanged else nil,
			RichText = not selectable,
			stateLayer = {
				mode = function()
					return if isSelected() then StateLayerMode.Inverse else StateLayerMode.Default
				end,
			},
			tag = function(): Tags
				return buildDayTags(props.highlight == true and not isSelected(), props.bandRadiusTag())
			end,
			testId = props.testId,
			Text = if selectable then props.label else `<s>{props.label}</s>`,
			textStyle = function(): ColorStyleValue
				local current = tokens()
				return {
					Color3 = if isSelected()
						then current.Inverse.Content.Emphasis.Color3
						elseif dimmed() then current.Color.Content.Muted.Color3
						else current.Color.Content.Emphasis.Color3,
					Transparency = if not isSelected() and dimmed() then Constants.DISABLED_TRANSPARENCY else 0,
				}
			end,
		})
	end

	local band = Vide.show(function()
		return props.bandPosition() ~= nil and props.bandSize() ~= nil
	end, function()
		local bandView = View({
			backgroundStyle = function(): ColorStyleValue
				return tokens().Color.ActionStandard.Background :: any
			end,
			Position = function()
				return props.bandPosition() or UDim2.new()
			end,
			Size = function()
				return props.bandSize() or UDim2.new()
			end,
			tag = function(): string?
				local radiusTag = props.bandRadiusTag()
				return if radiusTag and radiusTag ~= "" then radiusTag else nil
			end,
			ZIndex = 0,
		})
		bandView.Name = "Band"
		return bandView
	end)

	return View({
		LayoutOrder = props.LayoutOrder,
		tag = "size-full",
		children = {
			band,
			named("Day", rebuildOn<<boolean>>(isSelectable, dayElement)),
		},
	})
end

return CalendarGridDayLabel
