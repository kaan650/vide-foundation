local Vide = require("../../Packages/Vide")

local AlertActions = require("../AlertActions")
local AlertConstants = require("../AlertActions/AlertConstants")
local AlertSeverity = require("../../Enums/AlertSeverity")
local AlertVariant = require("../../Enums/AlertVariant")
local Breakpoint = require("../../Enums/Breakpoint")
local BuilderIcons = require("../../Packages/BuilderIcons")
local CloseAffordance = require("../CloseAffordance")
local CloseAffordanceVariant = require("../../Enums/CloseAffordanceVariant")
local ColorNamespace = require("../../Enums/ColorNamespace")
local Icon = require("../Icon")
local IconSize = require("../../Enums/IconSize")
local InputSize = require("../../Enums/InputSize")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local named = require("../../Utility/named")
local useBreakpoint = require("../../Providers/Responsive/Hooks/useBreakpoint")
local useSystemBannerVariants = require("./useSystemBannerVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type AlertAction = AlertConstants.AlertAction
type AlertSeverity = AlertSeverity.AlertSeverity
type AlertVariant = AlertVariant.AlertVariant
type ColorNamespace = ColorNamespace.ColorNamespace
type Value<T> = Types.Value<T>

export type SystemBannerProps = {
	variant: Value<AlertVariant?>?,
	severity: Value<AlertSeverity>,
	title: Value<string>,
	description: Value<string?>?,
	actions: Value<{ AlertAction }?>?,
	onClose: (() -> ())?,
} & Types.CommonProps

local defaultProps = {
	variant = AlertVariant.Standard,
	testId = "--foundation-system-banner",
}

-- SystemBanner renders Standard and Emphasis only; the Alert values collapse onto the default.
local VARIANT_FALLBACKS: { [AlertVariant]: AlertVariant } = {
	[AlertVariant.System] = AlertVariant.Standard,
	[AlertVariant.Feedback] = AlertVariant.Standard,
}

--- A full-width banner with a severity icon, title, description, actions and close button. Below the XSmall
--- breakpoint of its own width the actions wrap under the text.
local function SystemBanner(systemBannerProps: SystemBannerProps): GuiObject
	local props = withDefaults(systemBannerProps, defaultProps)
	local tokens = useTokens()
	local testId = props.testId
	local onClose = props.onClose

	local function variant(): AlertVariant
		local value: AlertVariant = Value.read(props.variant)
		return VARIANT_FALLBACKS[value] or value
	end
	local function severity(): AlertSeverity
		return Value.read(props.severity)
	end
	local function title(): string
		return Value.read(props.title)
	end
	local function description(): string?
		return Value.read(props.description)
	end

	local variantProps = Vide.derive(function()
		return useSystemBannerVariants(tokens(), variant(), severity())
	end)

	local container = Vide.source(nil :: GuiObject?)
	local breakpoint = useBreakpoint(container)
	local shouldWrapActions = Vide.derive(function()
		return breakpoint() == Breakpoint.XSmall
	end)

	local function actions(wrap: boolean): any
		return named(
			"Actions",
			AlertActions({
				actions = props.actions,
				testId = `{testId}--actions`,
				LayoutOrder = 3,
				tag = {
					["row gap-small auto-xy"] = true,
					["align-x-left"] = wrap,
					["align-x-right"] = not wrap,
				},
				padding = if wrap
					then {
						top = function()
							return UDim.new(0, tokens().Gap.Small)
						end,
					}
					else nil,
			})
		)
	end

	local function content(): { any }
		local text = View({
			LayoutOrder = 2,
			tag = "col auto-xy",
			children = {
				Vide.show(function()
					return title() ~= ""
				end, function()
					return named(
						"Title",
						Text({
							Text = title,
							textStyle = function()
								return variantProps().title.style
							end,
							tag = function()
								return variantProps().title.tag
							end,
							LayoutOrder = 1,
							testId = `{testId}--title`,
						})
					)
				end),
				Vide.show(description, function(current: () -> string)
					return named(
						"Description",
						Text({
							Text = current,
							textStyle = function()
								return variantProps().description.style
							end,
							tag = function()
								return variantProps().description.tag
							end,
							LayoutOrder = 2,
							testId = `{testId}--description`,
						})
					)
				end),
				Vide.show(shouldWrapActions, function()
					return actions(true)
				end),
			},
		})
		text.Name = "Text"

		return {
			named(
				"Icon",
				Icon({
					LayoutOrder = 1,
					name = function()
						return AlertConstants.SEVERITY_TO_ICON[severity()]
					end,
					size = IconSize.Large,
					variant = BuilderIcons.IconVariant.Filled,
					style = function()
						return variantProps().icon.style
					end,
					testId = `{testId}--icon`,
				})
			),
			named(
				"Content",
				View({
					LayoutOrder = 2,
					tag = function()
						local wrap = shouldWrapActions()
						return {
							["fill auto-xy"] = true,
							["col"] = wrap,
							["row"] = not wrap,
						}
					end,
					testId = `{testId}--content`,
					children = text,
				})
			),
			Vide.show(function()
				return not shouldWrapActions()
			end, function()
				return actions(false)
			end),
			if onClose
				then named(
					"Close",
					CloseAffordance({
						onActivated = onClose,
						size = InputSize.Small,
						variant = CloseAffordanceVariant.Utility,
						LayoutOrder = 4,
						testId = `{testId}--close`,
					})
				)
				else nil,
		}
	end

	--* The color namespace is a plain context value, so the content is rebuilt when it changes.
	local colorNamespace = Vide.derive(function(): ColorNamespace
		return variantProps().container.colorNamespace
	end)
	local contentFor = setmetatable({}, {
		__index = function(_, namespace: ColorNamespace)
			return function()
				return PresentationContext.context({ colorNamespace = namespace, isIconSize = false }, content)
			end
		end,
	})

	local root = View(withCommonProps(props, {
		tag = function()
			local hasTitle = title() ~= ""
			local hasDescription = description() ~= nil
			return {
				[variantProps().container.tag] = true,
				["align-y-center"] = not hasTitle or not hasDescription,
				["align-y-top"] = hasTitle and hasDescription,
			}
		end,
		children = Vide.switch(colorNamespace)(contentFor :: any),
	}) :: any)
	container(root)
	return root
end

return SystemBanner
