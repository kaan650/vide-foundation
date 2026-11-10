local BuilderIcons = require("../../Packages/BuilderIcons")
local IconName = BuilderIcons.Icon

local Button = require("../Button")
local Icon = require("../Icon")
local IconSize = require("../../Enums/IconSize")
local Text = require("../Text")
local Translator = require("../../Utility/Localization/Translator")
local Types = require("../Types")
local View = require("../View")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type IconSize = IconSize.IconSize
type Value<T> = Types.Value<T>

export type EmptyProps = {
	icon: {
		name: Value<string>?,
		size: Value<IconSize>?,
	}?,
	text: Value<string>?,
	-- The button shows only when `onActivated` is set.
	button: {
		text: Value<string?>?,
		icon: Value<string?>?,
		onActivated: (() -> ())?,
	}?,
} & Types.CommonProps

local defaultProps = {
	icon = {
		name = "icons/status/oof_xlarge",
		size = IconSize.Large,
	},
	text = Translator:FormatByKey("CommonUI.Controls.NoResultsFound"),
	button = {
		icon = IconName.TwoArrowsSpinClockwise,
		text = Translator:FormatByKey("CommonUI.Controls.Action.Refresh"),
	},
	testId = "--foundation-empty",
}

--- The placeholder for an empty list or failed load: an icon, a message and an optional retry button.
local function Empty(emptyProps: EmptyProps): GuiObject
	local props = withDefaults(emptyProps, defaultProps)
	local tokens = useTokens()

	local icon = Icon({
		name = props.icon.name :: Value<string>,
		size = props.icon.size,
		style = function()
			return tokens().Color.Content.Default :: any
		end,
		LayoutOrder = 1,
	})
	icon.Name = "Icon"

	local text = Text({
		Text = props.text,
		LayoutOrder = 2,
		tag = "size-full-0 auto-y text-body-large text-wrap text-align-x-center content-default",
		testId = `{props.testId}--text`,
	})
	text.Name = "Text"

	local button: GuiObject? = nil
	local onActivated = props.button.onActivated
	if onActivated then
		button = Button({
			text = props.button.text,
			icon = props.button.icon,
			onActivated = onActivated,
			LayoutOrder = 3,
		})
		;(button :: GuiObject).Name = "Button"
	end

	return View(withCommonProps(props, {
		tag = "col align-x-center align-y-center gap-small size-full auto-xy",
		children = { icon, text, button },
	}) :: any)
end

return Empty
