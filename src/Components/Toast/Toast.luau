local Vide = require("../../Packages/Vide")

local Button = require("../Button")
local Dash = require("../../Utility/Dash")
local FillBehavior = require("../../Enums/FillBehavior")
local Image = require("../Image")
local InputSize = require("../../Enums/InputSize")
local Logger = require("../../Utility/Logger")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local useCursor = require("../../Providers/Cursor/useCursor")
local useScaledValue = require("../../Utility/useScaledValue")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ActionProps = Types.ActionProps
type Value<T> = Types.Value<T>

export type ToastProps = {
	title: Value<string?>?,
	text: Value<string?>?,
	icon: Value<string?>?,
	actions: Value<{ ActionProps }?>?,

	-- Width of the toast. If not defined, toast will be `400px` wide on desktop.
	width: Value<UDim?>?,
} & Types.CommonProps

local MAX_BUTTON_COUNT = 2
local DEFAULT_TOAST_WIDTH = 400

local defaultProps = {
	testId = "--foundation-toast",
}

local function isPresent(value: string?): boolean
	return value ~= nil and value ~= ""
end

local function warnIfTooMany(actions: { ActionProps }?)
	if actions and #actions > MAX_BUTTON_COUNT then
		Logger:warning(`Toast only supports up to {MAX_BUTTON_COUNT} actions`)
	end
end

--- A notification card with an optional image, title, body and up to two action buttons.
local function Toast(toastProps: ToastProps): GuiObject
	local props = withDefaults(toastProps, defaultProps)
	local tokens = useTokens()
	local testId = props.testId
	local defaultWidth = useScaledValue(DEFAULT_TOAST_WIDTH)
	local cursor = useCursor(function()
		return {
			radius = UDim.new(0, tokens().Radius.Medium),
			offset = tokens().Size.Size_200,
			borderWidth = tokens().Stroke.Thicker,
		}
	end)

	local function hasTitle(): boolean
		return isPresent(Value.read(props.title))
	end
	local function hasBody(): boolean
		return isPresent(Value.read(props.text))
	end
	local function hasText(): boolean
		return hasTitle() or hasBody()
	end

	local function actionButton(buttonProps: { [string]: any }, index: number, layoutOrder: Value<number>): GuiObject
		local button = Button(Dash.union(buttonProps, {
			LayoutOrder = layoutOrder,
			size = InputSize.Medium,
			fillBehavior = FillBehavior.Fill,
		}) :: any)
		button.Name = `ToastButton{index}`
		return button
	end

	local actions = props.actions
	local buttons: any
	if type(actions) == "function" then
		local readActions: () -> { ActionProps }? = actions
		Vide.effect(function()
			warnIfTooMany(readActions())
		end)
		local function shownActions(): { ActionProps }
			local list = readActions() or {}
			return if #list > MAX_BUTTON_COUNT then table.move(list, 1, MAX_BUTTON_COUNT, 1, {}) else list
		end
		buttons = Vide.indexes(shownActions, function(action: () -> ActionProps, index: number)
			return actionButton(
				{
					text = function()
						return action().text
					end,
					variant = function()
						return action().variant
					end,
					onActivated = function()
						action().onActivated()
					end,
				},
				index,
				function()
					return #(readActions() or {}) - index
				end
			)
		end)
	else
		warnIfTooMany(actions)
		buttons = {}
		for index, action in actions or {} do
			if index > MAX_BUTTON_COUNT then
				break
			end
			table.insert(buttons, actionButton(action, index, #(actions :: { ActionProps }) - index))
		end
	end

	local function named(name: string, instance: GuiObject): GuiObject
		instance.Name = name
		return instance
	end

	local content = View({
		LayoutOrder = 2,
		tag = function()
			return {
				["fill self-center auto-y"] = true,
				["col gap-xxsmall"] = hasText(),
			}
		end,
		testId = `{testId}--content`,
		children = {
			Vide.show(hasTitle, function()
				return named(
					"Header",
					Text({
						LayoutOrder = 1,
						Text = function()
							return Value.read(props.title) or ""
						end,
						tag = "size-full-0 auto-y text-title-small text-align-x-left text-truncate-end content-emphasis",
						testId = `{testId}--header`,
					})
				)
			end),
			Vide.show(hasBody, function()
				return named(
					"Body",
					Text({
						LayoutOrder = 2,
						Text = function()
							return Value.read(props.text) or ""
						end,
						tag = "size-full-0 auto-y text-body-small text-wrap text-align-x-left content-default",
						testId = `{testId}--body`,
					})
				)
			end),
			Vide.show(function()
				local list: { ActionProps }? = Value.read(props.actions)
				return list ~= nil and #list > 0
			end, function()
				return named(
					"Actions",
					View({
						LayoutOrder = 3,
						tag = function()
							return {
								["row gap-small size-full-0 auto-y"] = true,
								["padding-top-small"] = hasText(),
							}
						end,
						testId = `{testId}--actions`,
						children = buttons,
					})
				)
			end),
		},
	})
	content.Name = "Content"

	--* No Position here: Foundation sets one, but withCommonProps overwrites it with the caller's.
	return View(withCommonProps(props, {
		Size = function()
			local width: UDim = Value.read(props.width) or UDim.new(0, defaultWidth())
			return UDim2.new(width, UDim.new())
		end,
		selection = {
			Selectable = false,
			SelectionImageObject = cursor,
		},
		tag = "row gap-small auto-y padding-medium radius-medium bg-over-media-0",
		children = {
			Vide.show(function()
				return isPresent(Value.read(props.icon))
			end, function()
				return named(
					"Media",
					Image({
						LayoutOrder = 1,
						Image = function()
							return Value.read(props.icon) or ""
						end,
						tag = "size-1200-1200",
						testId = `{testId}--media`,
					})
				)
			end),
			content,
		},
	}) :: any)
end

return Toast
