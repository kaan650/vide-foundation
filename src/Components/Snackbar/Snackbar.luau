local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
local CloseAffordance = require("../CloseAffordance")
local CloseAffordanceVariant = require("../../Enums/CloseAffordanceVariant")
local ColorNamespace = require("../../Enums/ColorNamespace")
local Icon = require("../Icon")
local InputSize = require("../../Enums/InputSize")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local StateLayerMode = require("../../Enums/StateLayerMode")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local useScaledValue = require("../../Utility/useScaledValue")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type IconVariant = BuilderIcons.IconVariant
type Value<T> = Types.Value<T>

type Icon = {
	name: string,
	variant: IconVariant?,
}

export type SnackbarAction = {
	onActivated: () -> (),
	text: string,
}

export type SnackbarProps = {
	action: Value<SnackbarAction?>?,
	icon: Value<(string | Icon)?>?,
	onClose: (() -> ())?,
	title: Value<string>,
} & Types.CommonProps

local SNACKBAR_DEFAULT_MAX_WIDTH = 272
local SNACKBAR_WITH_ICON_MAX_WIDTH = 304
local SNACKBAR_WITH_BUTTONS_FIXED_WIDTH = 371

local MAX_LINES = 2

local defaultProps = {
	testId = "--foundation-snackbar",
}

local IS_INVERSE: PresentationContext.PresentationContextValue = {
	isIconSize = false,
	colorNamespace = ColorNamespace.Inverse,
}

local function named(name: string, instance: GuiObject): GuiObject
	instance.Name = name
	return instance
end

--- A short message on an inverse background, with an optional icon, action and close button.
local function Snackbar(snackbarProps: SnackbarProps): GuiObject
	local props = withDefaults(snackbarProps, defaultProps)
	local tokens = useTokens()
	local testId = props.testId
	local onClose = props.onClose

	local scaledFixedWidth = useScaledValue(SNACKBAR_WITH_BUTTONS_FIXED_WIDTH)
	local scaledIconMaxWidth = useScaledValue(SNACKBAR_WITH_ICON_MAX_WIDTH)
	local scaledDefaultMaxWidth = useScaledValue(SNACKBAR_DEFAULT_MAX_WIDTH)

	local function icon(): (string | Icon)?
		return Value.read(props.icon)
	end
	local function action(): SnackbarAction?
		return Value.read(props.action)
	end
	local function hasIcon(): boolean
		local value = icon()
		return value ~= nil and value ~= ""
	end
	local function hasAction(): boolean
		local value = action()
		return value ~= nil and value.text ~= ""
	end
	local function hasButton(): boolean
		return hasAction() or onClose ~= nil
	end

	local function iconProps(): Icon?
		if not hasIcon() then
			return nil
		end
		local value = icon() :: string | Icon
		return if typeof(value) == "string" then { name = value, variant = BuilderIcons.IconVariant.Regular } else value
	end

	local function content(): GuiObject
		return named(
			"Content",
			View({
				LayoutOrder = 1,
				tag = "row align-y-center fill gap-small auto-xy padding-y-small",
				testId = `{testId}--content`,
				children = {
					Vide.show(iconProps, function(current: () -> Icon)
						return named(
							"Icon",
							Icon({
								name = function()
									return current().name
								end,
								variant = function()
									return current().variant or BuilderIcons.IconVariant.Regular
								end,
								style = function()
									return tokens().Inverse.Content.Emphasis :: any
								end,
								LayoutOrder = 1,
								testId = `{testId}--icon`,
							})
						)
					end),
					named(
						"Title",
						Text({
							LayoutOrder = 2,
							Text = props.title,
							sizeConstraint = function()
								local caption = tokens().Typography.CaptionLarge
								return {
									MinSize = Vector2.new(0, 0),
									MaxSize = Vector2.new(math.huge, caption.FontSize * caption.LineHeight * MAX_LINES),
								}
							end,
							tag = "fill auto-xy text-caption-large text-wrap text-align-x-left text-truncate-split content-inverse-emphasis",
							testId = `{testId}--title`,
						})
					),
				},
			})
		)
	end

	local function buttons(): GuiObject
		return named(
			"Buttons",
			View({
				LayoutOrder = 2,
				tag = "row align-y-center gap-xsmall auto-xy",
				testId = `{testId}--buttons`,
				children = {
					Vide.show(hasAction, function()
						return named(
							"Action",
							Text({
								LayoutOrder = 1,
								onActivated = function()
									local current = Vide.untrack(action)
									if current then
										current.onActivated()
									end
								end,
								stateLayer = {
									mode = StateLayerMode.Inverse,
								},
								Text = function()
									local current = action()
									return if current then current.text else ""
								end,
								tag = "auto-xy padding-small text-label-medium radius-medium content-inverse-link",
								testId = `{testId}--action`,
							})
						)
					end),
					if onClose
						then named(
							"CloseAffordance",
							CloseAffordance({
								LayoutOrder = 2,
								onActivated = onClose,
								size = InputSize.Small,
								variant = CloseAffordanceVariant.Utility,
								testId = `{testId}--close-affordance`,
							}) :: GuiObject
						)
						else nil,
				},
			})
		)
	end

	return View(withCommonProps(props, {
		Size = function()
			return if hasButton() then UDim2.fromOffset(scaledFixedWidth(), 0) else UDim2.fromOffset(0, 0)
		end,
		sizeConstraint = function(): Types.SizeConstraint?
			if hasButton() then
				return nil
			end
			local maxWidth = if hasIcon() then scaledIconMaxWidth() else scaledDefaultMaxWidth()
			return {
				MinSize = Vector2.new(0, 0),
				MaxSize = Vector2.new(maxWidth, math.huge),
			}
		end,
		tag = function()
			local iconOrButton = hasIcon() or hasButton()
			return {
				["row align-y-center gap-large padding-y-xsmall radius-medium bg-system-contrast"] = true,
				["padding-left-large"] = not iconOrButton,
				["padding-left-medium"] = iconOrButton,
				["auto-xy padding-right-large"] = not hasButton(),
				["auto-y padding-right-small"] = hasButton(),
			}
		end,
		children = PresentationContext.context(IS_INVERSE, function()
			return {
				content(),
				Vide.show(hasButton, buttons),
			}
		end),
	}) :: any)
end

return Snackbar
