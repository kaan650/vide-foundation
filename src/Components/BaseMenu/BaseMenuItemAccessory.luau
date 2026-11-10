local Vide = require("../../Packages/Vide")

local Avatar = require("../Avatar")
local Badge = require("../Badge")
local ColorNamespace = require("../../Enums/ColorNamespace")
local Icon = require("../Icon")
local InputSize = require("../../Enums/InputSize")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local Text = require("../Text")
local Types = require("../Types")
local View = require("../View")
local useTokens = require("../../Providers/Style/useTokens")

type InputSize = InputSize.InputSize
type ColorStyleValue = Types.ColorStyleValue

type IconAccessoryConfig = Types.IconAccessoryConfig
type AvatarAccessoryConfig = Types.AvatarAccessoryConfig
type HintAccessoryConfig = Types.HintAccessoryConfig
type BadgeAccessoryConfig = Types.BadgeAccessoryConfig

export type LeadingAccessory = IconAccessoryConfig | AvatarAccessoryConfig
export type TrailingAccessory = HintAccessoryConfig | BadgeAccessoryConfig
export type Accessory = LeadingAccessory | TrailingAccessory

export type IconVariantTag = { tag: string, style: any, size: number }

local SLOT_ALIGN = "align-x-center align-y-center"

local ICON_PRESENTATION: PresentationContext.PresentationContextValue = {
	colorNamespace = ColorNamespace.Color,
	isIconSize = true,
}
local HINT_TAG = "row align-y-center auto-xy padding-x-xsmall radius-small bg-shift-200"
local HINT_TEXT_TAG = "auto-xy text-caption-medium content-muted"

type Kind = "Avatar" | "Hint" | "Badge" | "Icon"

export type AccessoryProps = {
	LayoutOrder: number,
	-- The accessory to show. A nil read keeps the last one, for the moment before the caller removes the slot.
	accessory: () -> Accessory?,
	iconVariant: () -> IconVariantTag,
	size: () -> InputSize,
	testId: string?,
}

local function kindOf(accessory: Accessory): Kind
	local accessoryType = (accessory :: any).type
	return if accessoryType == "Avatar"
			or accessoryType == "Hint"
			or accessoryType == "Badge"
		then accessoryType
		else "Icon"
end

--- A menu item's leading or trailing slot: an icon, an avatar, a hint or a badge. Returns a source of the instance,
--- rebuilt when the accessory changes kind.
local function BaseMenuItemAccessory(props: AccessoryProps): () -> any
	local tokens = useTokens()
	local lastAccessory: Accessory = assert(Vide.untrack(props.accessory), "BaseMenuItemAccessory needs an accessory")

	local function accessory(): Accessory
		local current = props.accessory()
		if current ~= nil then
			lastAccessory = current
		end
		return lastAccessory
	end

	local function slotTag(): string
		return `{SLOT_ALIGN} {props.iconVariant().tag}`
	end

	--! Bindings can read a new accessory once before the switch removes their branch, so each branch keeps the
	--! last accessory of its own kind.
	local function latest(kind: Kind): () -> any
		local last: any = Vide.untrack(accessory)
		return function()
			local current = accessory()
			if kindOf(current) == kind then
				last = current
			end
			return last
		end
	end

	return Vide.switch(function(): Kind
		return kindOf(accessory())
	end)({
		Avatar = function()
			local accessory = latest("Avatar")
			local avatar = PresentationContext.context(ICON_PRESENTATION, function()
				return Avatar({
					userId = function(): number
						return accessory().userId
					end,
					backplateStyle = function(): ColorStyleValue
						return tokens().Color.Shift.Shift_200 :: ColorStyleValue
					end,
					size = props.size,
				})
			end)
			avatar.Name = "Avatar"
			return View({
				LayoutOrder = props.LayoutOrder,
				tag = slotTag,
				testId = props.testId,
				children = avatar,
			})
		end,
		Hint = function()
			local accessory = latest("Hint")
			local text = Text({
				Text = function(): string
					return accessory().text
				end,
				tag = HINT_TEXT_TAG,
			})
			text.Name = "Text"
			return View({
				LayoutOrder = props.LayoutOrder,
				tag = HINT_TAG,
				testId = props.testId,
				children = text,
			})
		end,
		Badge = function()
			local accessory = latest("Badge")
			return Badge({
				LayoutOrder = props.LayoutOrder,
				text = function(): string?
					return accessory().text
				end,
				icon = function(): string?
					return accessory().icon
				end,
				variant = function()
					return accessory().variant
				end,
				testId = props.testId,
			})
		end,
		Icon = function()
			local accessory = latest("Icon")
			local icon = Icon({
				name = function(): string
					return accessory().iconName
				end,
				variant = function()
					return accessory().iconVariant
				end,
				style = function()
					return props.iconVariant().style
				end,
				size = function()
					return props.iconVariant().size
				end,
			})
			icon.Name = "Icon"
			return View({
				LayoutOrder = props.LayoutOrder,
				tag = slotTag,
				testId = props.testId,
				children = icon,
			})
		end,
	})
end

return BaseMenuItemAccessory
