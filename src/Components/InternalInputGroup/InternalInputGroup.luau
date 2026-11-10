local Vide = require("../../Packages/Vide")

local InputGroupContext = require("./InputGroupContext")
local InputPlacement = require("../../Enums/InputPlacement")
local InputSize = require("../../Enums/InputSize")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local named = require("../../Utility/named")
local useInputGroupVariants = require("./useInputGroupVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type InternalInputGroupProps = Types.InternalInputGroupProps

local defaultProps = {
	size = InputSize.Medium,
	placement = InputPlacement.Start,
	testId = "--foundation-internal-input-group",
}

--- A column of inputs under an optional legend. The inputs inside take their size and placement from the group.
local function InternalInputGroup(groupProps: InternalInputGroupProps): GuiObject
	local props = withDefaults(groupProps, defaultProps)
	local tokens = useTokens()
	local variantProps = Vide.derive(function()
		return useInputGroupVariants(tokens(), props.size)
	end)

	return View(withCommonProps(props, {
		tag = function()
			return variantProps().container.tag
		end,
		children = InputGroupContext({
			size = props.size,
			placement = props.placement,
		}, function()
			return {
				Vide.show(function()
					local legend: string? = Value.read(props.legend)
					return legend ~= nil and legend ~= ""
				end, function()
					return named(
						"GroupLabel",
						Text({
							Text = function()
								return Value.read(props.legend) or ""
							end,
							tag = function()
								return variantProps().legend.tag
							end,
							testId = `{props.testId}--label`,
							LayoutOrder = 0,
						})
					)
				end),
				named(
					"Children",
					View({
						tag = function()
							return variantProps().children.tag
						end,
						LayoutOrder = 1,
						children = props.children,
					})
				),
			}
		end),
	}) :: any)
end

return InternalInputGroup
