local Vide = require("../../Packages/Vide")

local AlertConstants = require("./AlertConstants")
local Button = require("../Button")
local Dash = require("../../Utility/Dash")
local InputSize = require("../../Enums/InputSize")
local Logger = require("../../Utility/Logger")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local MAX_ACTION_COUNT = AlertConstants.MAX_ACTION_COUNT
type AlertAction = AlertConstants.AlertAction
type Value<T> = Types.Value<T>

export type AlertActionsProps = {
	actions: Value<{ AlertAction }?>?,
	tag: Value<Types.Tags?>?,
	padding: Types.Padding?,
	LayoutOrder: Value<number>?,
	testId: string?,
}

local defaultProps = {
	testId = "--foundation-alert-actions",
}

local DEFAULT_TAG = "auto-xy row gap-small"

local function warnIfTooMany(actions: { AlertAction }?)
	if actions and #actions > MAX_ACTION_COUNT then
		Logger:warning(`Alert components only support up to {MAX_ACTION_COUNT} actions`)
	end
end

local function hasActions(actions: { AlertAction }?): boolean
	return actions ~= nil and #actions > 0
end

--- The row of small Buttons under an alert. Nothing is rendered without actions; with a source `actions`, the
--- result is a source that holds the row only while there are actions.
local function AlertActions(alertActionsProps: AlertActionsProps): GuiObject? | () -> GuiObject?
	local props = withDefaults(alertActionsProps, defaultProps)
	local testId = props.testId

	local function buttonProps(action: any, index: number): Button.ButtonProps
		return Dash.join(action, {
			LayoutOrder = index,
			size = InputSize.Small,
			testId = `{testId}--action-{index}`,
		}) :: any
	end

	local function container(buttons: any): GuiObject
		return View(withCommonProps(props :: any, {
			tag = if type(props.tag) == "function"
				then function()
					return Value.read(props.tag) or DEFAULT_TAG
				end
				else props.tag or DEFAULT_TAG,
			padding = props.padding,
			children = buttons,
		}) :: any)
	end

	local actions = props.actions
	if type(actions) ~= "function" then
		warnIfTooMany(actions)
		if not hasActions(actions) then
			return nil
		end
		local buttons = {}
		for index, action in actions :: { AlertAction } do
			if index > MAX_ACTION_COUNT then
				break
			end
			local button = Button(buttonProps(action, index))
			button.Name = `ActionButton{index}`
			table.insert(buttons, button)
		end
		return container(buttons)
	end

	local readActions: () -> { AlertAction }? = actions
	Vide.effect(function()
		warnIfTooMany(readActions())
	end)
	local shownActions = function(): { AlertAction }
		local list = readActions() or {}
		return if #list > MAX_ACTION_COUNT then table.move(list, 1, MAX_ACTION_COUNT, 1, {}) else list
	end

	return Vide.show(function()
		return hasActions(readActions())
	end, function()
		return container(Vide.indexes(shownActions, function(action: () -> AlertAction, index: number)
			local button = Button(buttonProps({
				text = function()
					return action().text
				end,
				variant = function()
					return action().variant
				end,
				onActivated = function()
					action().onActivated()
				end,
			}, index))
			button.Name = `ActionButton{index}`
			return button
		end))
	end) :: any
end

return AlertActions
