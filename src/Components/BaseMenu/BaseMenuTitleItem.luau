local Vide = require("../../Packages/Vide")

local InputSize = require("../../Enums/InputSize")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local useBaseMenuItemVariants = require("./useBaseMenuItemVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")

type InputSize = InputSize.InputSize
type Value<T> = Types.Value<T>

export type BaseMenuTitleItemProps = {
	text: Value<string>,
	size: Value<InputSize>,
	menuHasLeading: Value<boolean?>?,
	menuHasCheck: Value<boolean?>?,
} & Types.CommonProps

--- A group's title row, aligned with the item texts below it.
local function BaseMenuTitleItem(props: BaseMenuTitleItemProps): GuiObject
	local tokens = useTokens()

	local variantProps = Vide.derive(function()
		return useBaseMenuItemVariants(tokens(), Value.read(props.size), false)
	end)

	local text = Text({
		Text = props.text,
		tag = function()
			return variantProps().title.tag
		end,
	})
	text.Name = "Children"

	return View(withCommonProps(props, {
		tag = function()
			return `row align-y-center {variantProps().container.tag}`
		end,
		padding = {
			left = function()
				local variant = variantProps()
				local offset = if Value.read(props.menuHasCheck) == true
					then (variant.container.paddingLeftWithCheck or 0) + (variant.title.checkColumnWidth or 0)
					else variant.container.paddingLeftWithoutCheck or 0
				return UDim.new(0, offset)
			end,
			right = function()
				return UDim.new(0, variantProps().container.paddingRight or 0)
			end,
		},
		children = text,
	}) :: any)
end

return BaseMenuTitleItem
