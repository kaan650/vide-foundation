local Vide = require("../../../Packages/Vide")

local BuilderIcons = require("../../../Packages/BuilderIcons")
type IconVariant = BuilderIcons.IconVariant

local AccessoryType = require("../../../Enums/AccessoryType")
local Avatar = require("../../Avatar")
local Icon = require("../../Icon")
local Image = require("../../Image")
local InputSize = require("../../../Enums/InputSize")
local StateLayerAffordance = require("../../../Enums/StateLayerAffordance")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local getTestIdTag = require("../../../Utility/getTestIdTag")
local iconMigrationUtils = require("../../../Utility/iconMigrationUtils")
local named = require("../../../Utility/named")
local useListAccessoryVariants = require("./useListAccessoryVariants")
local useTokens = require("../../../Providers/Style/useTokens")

type AccessoryType = AccessoryType.AccessoryType
type InputSize = InputSize.InputSize
type Value<T> = Types.Value<T>
type IconAccessoryConfig = Types.IconAccessoryConfig
type AvatarAccessoryConfig = Types.AvatarAccessoryConfig

export type ListAccessory = IconAccessoryConfig | AvatarAccessoryConfig

type Config = string | ListAccessory

export type ListAccessoryProps = {
	-- An icon name or image, or a config for an Avatar, Builder Icon or image.
	config: Value<Config>,
	size: Value<InputSize>,
	isDisabled: Value<boolean?>?,
	testId: Value<string>,
	LayoutOrder: Value<number?>?,
}

type Element = "Avatar" | "Icon" | "Image"

local STATE_LAYER: Types.StateLayer = { affordance = StateLayerAffordance.None }

local function toFullConfig(config: Config): ListAccessory
	return if type(config) == "string" then { iconName = config } :: IconAccessoryConfig else config
end

local function elementOf(config: ListAccessory): Element
	if config.type == AccessoryType.Avatar then
		return "Avatar"
	end
	return if iconMigrationUtils.isBuilderOrMigratedIcon((config :: IconAccessoryConfig).iconName)
		then "Icon"
		else "Image"
end

--- A list item's leading Avatar, Builder Icon or image, centered in a square sized by the list.
local function ListAccessory(accessoryProps: ListAccessoryProps): GuiObject
	local tokens = useTokens()

	local function config(): Config
		return Value.read(accessoryProps.config)
	end
	local function fullConfig(): ListAccessory
		return toFullConfig(config())
	end
	local function size(): InputSize
		return Value.read(accessoryProps.size)
	end

	--* A plain-string image name sizes like an icon here but still renders as an Image (elementOf).
	local function accessoryType(): AccessoryType
		local current = config()
		if type(current) == "table" and current.type == AccessoryType.Avatar then
			return AccessoryType.Avatar
		elseif type(current) == "string" or iconMigrationUtils.isBuilderOrMigratedIcon(current.iconName) then
			return AccessoryType.Icon
		end
		return AccessoryType.Media
	end

	local function element(): Element
		return elementOf(fullConfig())
	end

	--! The old element's bindings update before the switch replaces it, so each element only sees configs of its
	--! own kind (an Icon reading an Avatar config would set its Text to nil).
	local function configOf(kind: Element): () -> ListAccessory
		local filtered = Vide.source(Vide.untrack(fullConfig))
		Vide.effect(function()
			local current = fullConfig()
			if elementOf(current) == kind then
				filtered(current)
			end
		end)
		return filtered
	end

	local variants = Vide.derive(function()
		return useListAccessoryVariants(tokens(), size(), accessoryType())
	end)

	local builders: { [Element]: () -> GuiObject } = {
		Avatar = function()
			local avatarConfig = configOf("Avatar")
			return Avatar({
				userId = function()
					return (avatarConfig() :: AvatarAccessoryConfig).userId
				end,
				backplateStyle = function()
					return tokens().Color.Shift.Shift_200 :: any
				end,
				size = size,
			})
		end,
		Icon = function()
			local iconConfig = configOf("Icon")
			local function normalized()
				return iconMigrationUtils.normalizeIconName((iconConfig() :: IconAccessoryConfig).iconName)
			end
			return Icon({
				name = function()
					return normalized().name
				end,
				variant = function(): IconVariant?
					local current = iconConfig() :: IconAccessoryConfig
					return if iconMigrationUtils.isMigrated(current.iconName)
						then normalized().variant
						else current.iconVariant
				end :: any,
				size = function()
					return variants().accessory.Size.Y.Offset
				end,
			})
		end,
		Image = function()
			local imageConfig = configOf("Image")
			return Image({
				Image = function()
					return (imageConfig() :: IconAccessoryConfig).iconName
				end,
				Size = function()
					return variants().accessory.Size
				end,
				cornerRadius = function()
					return variants().accessory.cornerRadius
				end,
			})
		end,
	}

	return View({
		Size = function()
			return variants().container.Size
		end,
		tag = function()
			return `align-x-center align-y-center {getTestIdTag(Value.read(accessoryProps.testId))}`
		end,
		stateLayer = STATE_LAYER,
		isDisabled = accessoryProps.isDisabled :: any,
		LayoutOrder = accessoryProps.LayoutOrder :: any,
		children = named("Children", Vide.switch(element)(builders :: any)),
	})
end

return ListAccessory
