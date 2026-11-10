local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
local Font = BuilderIcons.Font
local IconVariant = BuilderIcons.IconVariant
type IconVariant = BuilderIcons.IconVariant

local IconSize = require("../../Enums/IconSize")
local Image = require("../Image")
local Logger = require("../../Utility/Logger")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local create = require("../../Utility/create")
local isBuilderIcon = require("../../Utility/isBuilderIcon")
local migrateFontSize = require("./migrateFontSize")
local migrateIconName = require("./migrateIconName")
local useIconSize = require("../../Utility/useIconSize")
local useTextSizeOffset = require("../../Providers/Style/useTextSizeOffset")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type IconSize = IconSize.IconSize
type ColorStyle = Types.ColorStyle
type Value<T> = Types.Value<T>

export type IconProps = {
	-- A Builder Icons name ("heart"), an old UIBlox icon key (migrated to Builder Icons), or a FoundationImages key.
	name: Value<string>,
	style: ColorStyle?,
	size: Value<IconSize | number>?,
	variant: Value<IconVariant>?,
	Rotation: Value<number>?,
	-- **DEPRECATED**
	children: Types.Children?,
} & Types.CommonProps

local defaultProps = {
	size = IconSize.Medium,
	variant = IconVariant.Regular,
	testId = "--foundation-icon",
}

--- A Builder Icons glyph, or a FoundationImages image for older icon keys.
local function Icon(iconProps: IconProps): GuiObject
	local props = withDefaults(iconProps, defaultProps)
	local tokens = useTokens()
	local textSizeOffset = useTextSizeOffset()

	--* Whether this is a Builder Icon or an image is decided from the first name; a later name keeps that kind.
	local initialName: string = Vide.untrack(function(): string
		return Value.read(props.name)
	end)
	local isGlyph = isBuilderIcon(initialName) or migrateIconName(initialName) ~= nil
	local size = useIconSize(props.size, isBuilderIcon(initialName))

	local style: ColorStyle = props.style or function()
		return tokens().Color.Content.Default :: any
	end

	if not isGlyph then
		if iconProps.variant ~= nil then
			Logger:warning("variant is not supported when using FoundationImages, consider using BuilderIcons")
		end
		return Image(withCommonProps(props, {
			imageStyle = style,
			Image = props.name,
			Size = size,
			Rotation = props.Rotation,
			children = props.children,
		}) :: any)
	end

	local function glyph(): (string, IconVariant, number?)
		local name: string = Value.read(props.name)
		local variant: IconVariant = Value.read(props.variant)
		local fontSize: number? = size().Y.Offset
		if not isBuilderIcon(name) then
			local migrated = migrateIconName(name)
			if migrated then
				variant = migrated.variant or variant
				name = migrated.name
				fontSize = migrateFontSize(fontSize :: number, tokens())
			end
		end
		return name, variant, fontSize
	end

	return Text(withCommonProps(props, {
		textStyle = style,
		Text = function()
			local name = glyph()
			return name
		end,
		fontStyle = function()
			local _, variant, fontSize = glyph()
			return {
				Font = (Font :: any)[variant],
				FontSize = fontSize,
			}
		end,
		TextScaled = false,
		Size = size,
		Rotation = props.Rotation,
		children = {
			Vide.show(function()
				local _, _, fontSize = glyph()
				return textSizeOffset() > 0 and fontSize ~= nil
			end, function()
				return create("UITextSizeConstraint")({
					MaxTextSize = function()
						local _, _, fontSize = glyph()
						return fontSize or 100
					end,
				})
			end),
			props.children,
		},
	}) :: any)
end

return Icon
