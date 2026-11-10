local Vide = require("../../Packages/Vide")

local CloseAffordance = require("../CloseAffordance")
local CloseAffordanceVariant = require("../../Enums/CloseAffordanceVariant")
local Constants = require("../../Constants")
local InputSize = require("../../Enums/InputSize")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local useInputChipVariants = require("./useInputChipVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InputSize = InputSize.InputSize
type Value<T> = Types.Value<T>

export type InputChipProps = {
	text: Value<string>,
	onClose: () -> (),
	size: Value<InputSize>?,
	isDisabled: Value<boolean>?,
} & Types.CommonProps

local defaultProps = {
	size = InputSize.Medium,
	isDisabled = false,
	testId = "--foundation-input-chip",
}

--- A removable tag: a label with a small close button. A source `isDisabled` returns a source of the instance: a
--- disabled chip is a CanvasGroup, so it is rebuilt when the value changes.
local function InputChip(inputChipProps: InputChipProps): GuiObject | () -> GuiObject
	local props = withDefaults(inputChipProps, defaultProps)
	local tokens = useTokens()
	local testId = props.testId

	local variantProps = Vide.derive(function()
		return useInputChipVariants(tokens(), Value.read(props.size))
	end)

	local function build(isDisabled: boolean): GuiObject
		local closeAffordance = CloseAffordance({
			onActivated = (if isDisabled then nil else props.onClose) :: () -> (),
			size = InputSize.XSmall,
			variant = CloseAffordanceVariant.Utility,
			hasPadding = false,
			Selectable = if isDisabled then false else nil,
			LayoutOrder = 1,
			testId = `{testId}--close`,
		})

		return View(withCommonProps(props, {
			tag = function()
				return variantProps().container.tag
			end,
			GroupTransparency = if isDisabled then Constants.DISABLED_TRANSPARENCY else nil,
			children = {
				named(
					"Text",
					Text({
						Text = props.text,
						textStyle = function()
							return variantProps().text.contentStyle
						end,
						tag = function()
							return variantProps().text.tag
						end,
						padding = {
							left = function()
								return variantProps().text.padding.left
							end,
							right = function()
								return variantProps().text.padding.right
							end,
						},
						LayoutOrder = 1,
						testId = `{testId}--text`,
					})
				),
				named(
					"Close",
					View({
						tag = function()
							return variantProps().close.tag
						end,
						padding = {
							right = function()
								return variantProps().close.padding.right
							end,
						},
						LayoutOrder = 2,
						testId = `{testId}--close-container`,
						children = named("CloseAffordance", closeAffordance),
					})
				),
			},
		}) :: any)
	end

	return rebuildOn(props.isDisabled, build)
end

return InputChip
