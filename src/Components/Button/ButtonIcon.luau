local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")

local Image = require("../Image")
local Text = require("../Text")
local Types = require("../Types")
local create = require("../../Utility/create")
local getIconScale = require("../../Utility/getIconScale")
local iconMigrationUtils = require("../../Utility/iconMigrationUtils")
local useTextSizeOffset = require("../../Providers/Style/useTextSizeOffset")

type ColorStyleValue = Types.ColorStyleValue

export type ButtonIconProps = {
	icon: () -> string,
	-- Whether the icon is a Builder Icon (or a migrated UIBlox one); fixed for the life of this component.
	isGlyph: boolean,
	size: () -> string,
	iconSize: () -> UDim2,
	contentColor: () -> Color3?,
	disabledTransparency: () -> number,
	textTransparency: () -> number,
	testId: string,
}

--- The icon inside Button: a Builder Icons glyph, or a FoundationImages image at its intrinsic size.
local function ButtonIcon(props: ButtonIconProps): GuiObject
	local textSizeOffset = useTextSizeOffset()

	local function style(): ColorStyleValue
		return {
			Color3 = props.contentColor(),
			Transparency = props.textTransparency() + props.disabledTransparency(),
		}
	end

	local instance: GuiObject
	if props.isGlyph then
		local function normalized()
			return iconMigrationUtils.normalizeIconName(props.icon())
		end
		instance = Text({
			Text = function()
				return normalized().name
			end,
			fontStyle = function()
				return {
					Font = (BuilderIcons.Font :: any)[normalized().variant or BuilderIcons.IconVariant.Regular],
					FontSize = props.iconSize().Y.Offset,
				}
			end,
			tag = "position-center-center anchor-center-center",
			Size = props.iconSize,
			textStyle = style,
			testId = `{props.testId}--icon`,
			children = Vide.show(function()
				return textSizeOffset() > 0
			end, function()
				return create("UITextSizeConstraint")({
					MaxTextSize = function()
						return props.iconSize().Y.Offset
					end,
				})
			end),
		})
	else
		local function scale(): (Vector2?, number)
			return getIconScale(props.icon(), props.size() :: any)
		end
		instance = Image({
			tag = "position-center-center anchor-center-center",
			Image = props.icon,
			Size = function()
				local intrinsic = scale()
				return if intrinsic then UDim2.fromOffset(intrinsic.X, intrinsic.Y) else props.iconSize()
			end,
			imageStyle = style,
			scale = function()
				local _, iconScale = scale()
				return iconScale
			end,
			testId = `{props.testId}--icon`,
		})
	end

	instance.Name = "Icon"
	return instance
end

return ButtonIcon
