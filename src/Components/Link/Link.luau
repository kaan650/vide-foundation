local Vide = require("../../Packages/Vide")

local ControlState = require("../../Enums/ControlState")
type ControlState = ControlState.ControlState

local InputSize = require("../../Enums/InputSize")
type InputSize = InputSize.InputSize

local LinkVariant = require("../../Enums/LinkVariant")
type LinkVariant = LinkVariant.LinkVariant

local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local TextOverflow = require("../../Enums/TextOverflow")
type TextOverflow = TextOverflow.TextOverflow

local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")

local escapeRichText = require("../../Utility/escapeRichText")
local useLinkVariants = require("./useLinkVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

local EMPHASIZED_STATES: { [string]: boolean } = {
	[ControlState.Hover] = true,
	[ControlState.Pressed] = true,
	[ControlState.Selected] = true,
	[ControlState.SelectedPressed] = true,
}

export type LinkProps = {
	-- Label shown for the link.
	text: Value<string>,
	-- Called when the link is activated.
	onActivated: () -> (),
	-- Visual style of the link. Defaults to `LinkVariant.Standard`.
	variant: Value<LinkVariant>?,
	-- Size of the link text. Defaults to `InputSize.Medium`.
	size: Value<InputSize>?,
	-- When true, the label is always underlined. Defaults to `false`.
	hasUnderline: Value<boolean>?,
	textOverflow: Value<TextOverflow>?,
} & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	variant = LinkVariant.Standard,
	size = InputSize.Medium,
	hasUnderline = false,
	textOverflow = TextOverflow.None,
	testId = "--foundation-link",
}

--- Interactive text that navigates elsewhere. It underlines while hovered, pressed or selected.
local function Link(linkProps: LinkProps): GuiObject
	local props = withDefaults(linkProps, defaultProps)
	local tokens = useTokens()

	local variantProps = Vide.derive(function()
		return useLinkVariants(
			tokens(),
			Value.read(props.size),
			Value.read(props.variant),
			Value.read(props.textOverflow)
		)
	end)

	local isEmphasized = Vide.source(false)
	local function isUnderlined(): boolean
		return Value.read(props.hasUnderline) == true or isEmphasized()
	end

	local label = Text({
		Text = function()
			local text: string = Value.read(props.text)
			return if isUnderlined() then `<u>{escapeRichText(text)}</u>` else text
		end,
		RichText = isUnderlined,
		tag = function()
			return variantProps().text.tag
		end,
		textStyle = function(): ColorStyleValue
			local style = variantProps().content.style
			return { Color3 = style.Color3, Transparency = style.Transparency }
		end,
		LayoutOrder = 1,
		testId = `{props.testId}--text`,
	})
	label.Name = "Text"

	return View(withCommonProps(props, {
		tag = function()
			return variantProps().container.tag
		end,
		cursor = function()
			local current = tokens()
			return {
				radius = UDim.new(0, current.Radius.XSmall),
				offset = current.Size.Size_50,
				borderWidth = current.Stroke.Standard,
			}
		end,
		stateLayer = { affordance = StateLayerAffordance.None },
		onActivated = function()
			props.onActivated()
		end,
		onStateChanged = function(state: ControlState)
			isEmphasized(EMPHASIZED_STATES[state] == true)
		end,
		selection = {
			Selectable = props.Selectable,
			NextSelectionUp = props.NextSelectionUp,
			NextSelectionDown = props.NextSelectionDown,
			NextSelectionLeft = props.NextSelectionLeft,
			NextSelectionRight = props.NextSelectionRight,
		},
		children = label,
	}) :: any)
end

return Link
