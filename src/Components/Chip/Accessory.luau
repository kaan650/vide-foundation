local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
type IconVariant = BuilderIcons.IconVariant

local AvatarGroup = require("../AvatarGroup")
local AvatarGroupType = require("../../Enums/AvatarGroupType")
local BackgroundStyleContext = require("../../Providers/Style/BackgroundStyleContext")
local ChipSize = require("../../Enums/ChipSize")
local Icon = require("../Icon")
local Image = require("../Image")
local Types = require("../Types")
local View = require("../View")
local iconMigrationUtils = require("../../Utility/iconMigrationUtils")
local rebuildOn = require("../../Utility/rebuildOn")
local useAccessoryVariants = require("./useAccessoryVariants")
local useCumulativeBackground = require("../../Utility/useCumulativeBackground")
local useTokens = require("../../Providers/Style/useTokens")

type AvatarGroupType = AvatarGroupType.AvatarGroupType
type ChipSize = ChipSize.ChipSize
type ColorStyleValue = Types.ColorStyleValue

type IconConfig = {
	iconName: string,
	iconVariant: IconVariant?,
	isCircular: boolean?,
	onActivated: (() -> ())?,
	type: nil,
}

export type AvatarGroupConfig = {
	type: "AvatarGroup",
	-- Only a subset of the AvatarGroup props; the rest come from the Chip.
	props: {
		avatars: { { userId: number } | number },
		type: AvatarGroupType?,
		max: number?,
	},
	onActivated: nil,
	isCircular: nil,
}

export type Accessory = IconConfig | AvatarGroupConfig

export type AccessoryProps = {
	isLeading: boolean,
	-- A string config is turned into an IconConfig by the Chip.
	config: () -> Accessory,
	size: () -> ChipSize,
	contentStyle: () -> ColorStyleValue,
	chipBackgroundStyle: () -> ColorStyleValue,
	isDisabled: boolean,
	testId: string,
}

type Kind = "AvatarGroup" | "Glyph" | "Image"

local function getKind(config: Accessory): Kind
	if config.type == "AvatarGroup" then
		return "AvatarGroup"
	end
	return if iconMigrationUtils.isBuilderOrMigratedIcon(config.iconName) then "Glyph" else "Image"
end

--* What the accessory's instances depend on: its element and whether its View handles input.
local function getBuildKey(config: Accessory): string
	return `{getKind(config)}:{config.onActivated ~= nil}`
end

local function AvatarGroupWrapper(props: AccessoryProps, config: () -> AvatarGroupConfig): GuiObject
	local backgroundStyle = BackgroundStyleContext.useBackgroundStyle()
	return AvatarGroup({
		avatars = function()
			return config().props.avatars :: any
		end,
		type = function()
			return config().props.type :: any
		end,
		max = function()
			return config().props.max :: any
		end,
		size = props.size :: any,
		backplateStyle = useCumulativeBackground(backgroundStyle, props.chipBackgroundStyle),
	})
end

--- A Chip's leading or trailing icon, image or avatar group. Returns a source of the instance, rebuilt when the
--- config changes what it renders.
local function Accessory(props: AccessoryProps): () -> GuiObject
	local tokens = useTokens()

	local variants = Vide.derive(function()
		local config = props.config()
		local isCircular = config.type == "AvatarGroup" or config.isCircular == true
		return useAccessoryVariants(tokens(), props.size(), props.isLeading, isCircular)
	end)

	local buildKey = Vide.derive(function()
		return getBuildKey(props.config())
	end)

	local function build(key: string): GuiObject
		--! Effects in this build can run once more after the config changed kind, before it is rebuilt.
		local last = Vide.untrack(props.config)
		local function config(): any
			local current = props.config()
			if getBuildKey(current) == key then
				last = current
			end
			return last
		end

		local kind = getKind(last)
		local element: GuiObject
		if kind == "AvatarGroup" then
			element = AvatarGroupWrapper(props, config)
		elseif kind == "Glyph" then
			local function normalized(): iconMigrationUtils.NormalizedIconName
				local current = config()
				return if iconMigrationUtils.isMigrated(current.iconName)
					then iconMigrationUtils.normalizeIconName(current.iconName)
					else { name = current.iconName, variant = current.iconVariant }
			end
			element = Icon({
				name = function()
					return normalized().name
				end,
				variant = function()
					return normalized().variant :: any
				end,
				size = function()
					return variants().accessory.Size.Y.Offset
				end,
				style = props.contentStyle,
			})
		else
			element = Image({
				Image = function()
					return config().iconName
				end,
				Size = function()
					return variants().accessory.Size
				end,
				imageStyle = props.contentStyle,
			})
		end

		--* React names a lone child element "Children".
		element.Name = "Children"

		return View({
			tag = "auto-xy",
			padding = {
				left = function()
					return variants().accessory.padding.left
				end,
				right = function()
					return variants().accessory.padding.right
				end,
			},
			onActivated = if last.onActivated
				then function()
					local handler: (() -> ())? = config().onActivated
					if handler then
						handler()
					end
				end
				else nil,
			--* No transparency here when disabled; the Chip fades as a whole.
			isDisabled = props.isDisabled,
			LayoutOrder = if props.isLeading then 1 else 3,
			testId = props.testId,
			children = element,
		})
	end

	return (rebuildOn :: any)(buildKey, build)
end

return Accessory
