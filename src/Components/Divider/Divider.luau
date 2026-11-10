local Vide = require("../../Packages/Vide")

local DividerVariant = require("../../Enums/DividerVariant")
local Orientation = require("../../Enums/Orientation")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local useDividerVariants = require("./useDividerVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type DividerVariant = DividerVariant.DividerVariant
type Orientation = Orientation.Orientation
type Value<T> = Types.Value<T>

export type DividerProps = {
	variant: Value<DividerVariant>?,
	orientation: Value<Orientation>?,
} & Types.CommonProps

local defaultProps = {
	variant = DividerVariant.Default,
	orientation = Orientation.Horizontal,
	testId = "--foundation-divider",
}

--- A thin line separating content, horizontal or vertical.
local function Divider(dividerProps: DividerProps): GuiObject
	local props = withDefaults(dividerProps, defaultProps)
	local tokens = useTokens()

	local function variant(): DividerVariant
		return Value.read(props.variant)
	end
	local function orientation(): Orientation
		return Value.read(props.orientation)
	end

	local variantProps = Vide.derive(function()
		return useDividerVariants(tokens(), variant(), orientation())
	end)

	local function isHeavy(): boolean
		return variant() == DividerVariant.Heavy and orientation() ~= Orientation.Vertical
	end

	local stroke = View({
		Size = function()
			return variantProps().stroke.Size
		end,
		backgroundStyle = function()
			return variantProps().stroke.backgroundStyle
		end,
	})
	stroke.Name = "DividerStroke"

	return View(withCommonProps(props, {
		tag = function()
			return variantProps().container.tag
		end,
		children = {
			stroke,
			Vide.show(isHeavy, function()
				local line = View({
					tag = function()
						return variantProps().line.tag
					end,
					Position = function()
						return variantProps().line.position
					end,
					backgroundStyle = function()
						return variantProps().line.backgroundStyle
					end,
				})
				line.Name = "DividerLine"
				return line
			end),
		},
	}) :: any)
end

return Divider
