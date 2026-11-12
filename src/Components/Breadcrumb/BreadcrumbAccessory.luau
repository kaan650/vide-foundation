local AccessoryType = require("../../Enums/AccessoryType")
local AvatarIcon = require("../AvatarIcon")
local AvatarIconSize = require("../../Enums/AvatarIconSize")
local Icon = require("../Icon")
local IconSize = require("../../Enums/IconSize")
local Image = require("../Image")
local Types = require("../Types")
local iconMigrationUtils = require("../../Utility/iconMigrationUtils")

type AvatarIconSize = AvatarIconSize.AvatarIconSize
type IconSize = IconSize.IconSize
type ColorStyleValue = Types.ColorStyleValue
type IconAccessoryConfig = Types.IconAccessoryConfig
type AvatarAccessoryConfig = Types.AvatarAccessoryConfig

export type BreadcrumbAccessory = IconAccessoryConfig | AvatarAccessoryConfig

export type BreadcrumbAccessoryVariant = {
	iconSize: IconSize,
	avatarSize: AvatarIconSize,
	tag: string,
	style: ColorStyleValue,
}

type BreadcrumbAccessoryProps = {
	config: string | BreadcrumbAccessory,
	variant: BreadcrumbAccessoryVariant,
	LayoutOrder: number,
	testId: string,
}

--- A crumb's leading avatar, Builder icon or image.
local function BreadcrumbAccessory(props: BreadcrumbAccessoryProps): GuiObject
	local variant = props.variant
	local fullConfig: BreadcrumbAccessory = if type(props.config) == "string"
		then { iconName = props.config } :: BreadcrumbAccessory
		else props.config :: BreadcrumbAccessory

	if fullConfig.type == AccessoryType.Avatar then
		return AvatarIcon({
			userId = (fullConfig :: AvatarAccessoryConfig).userId,
			size = variant.avatarSize,
			LayoutOrder = props.LayoutOrder,
			testId = props.testId,
		})
	end

	local iconConfig = fullConfig :: IconAccessoryConfig
	local iconName = iconConfig.iconName
	if iconMigrationUtils.isBuilderOrMigratedIcon(iconName) then
		local normalized = if iconMigrationUtils.isMigrated(iconName)
			then iconMigrationUtils.normalizeIconName(iconName)
			else { name = iconName, variant = iconConfig.iconVariant }
		return Icon({
			name = normalized.name,
			variant = normalized.variant :: any,
			size = variant.iconSize,
			style = variant.style,
			LayoutOrder = props.LayoutOrder,
			testId = props.testId,
		})
	end

	return Image({
		Image = iconName,
		tag = variant.tag,
		LayoutOrder = props.LayoutOrder,
		testId = props.testId,
	})
end

return BreadcrumbAccessory
