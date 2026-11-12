local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")

local AvatarIcon = require("../AvatarIcon")
local AvatarIconSize = require("../../Enums/AvatarIconSize")
local Icon = require("../Icon")
local IconSize = require("../../Enums/IconSize")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local StatusIndicator = require("../StatusIndicator")
local StatusIndicatorSize = require("../../Enums/StatusIndicatorSize")
local StatusIndicatorVariant = require("../../Enums/StatusIndicatorVariant")
local Text = require("../Text")
local Types = require("../Types")
local View = require("../View")
local useTokens = require("../../Providers/Style/useTokens")

type ColorStyleValue = Types.ColorStyleValue
type IconVariant = BuilderIcons.IconVariant
type ItemId = Types.ItemId
type Value<T> = Types.Value<T>

type NavigationBarIndicator = {
	-- Count to show. Leave unset for a dot
	value: number?,
	-- Counts above this show as "{max}+". Defaults to 99
	max: number?,
}

export type NavigationBarItem = {
	-- Unique id passed to onActivated and matched against activeItemId
	id: ItemId,
	-- Label shown under the icon
	text: string,
	-- A BuilderIcons name, or { type = "Avatar", userId } for an avatar
	icon: string | Types.AvatarAccessoryConfig,
	-- Shows a dot or a count on the icon
	indicator: NavigationBarIndicator?,
}

export type NavigationBarTabProps = {
	item: () -> NavigationBarItem,
	isActive: () -> boolean,
	onActivated: (id: ItemId) -> (),
	LayoutOrder: Value<number>,
	testId: string,
}

type IconKind = "Avatar" | "Icon"

local DEFAULT_INDICATOR_MAX = 99

local function getIconKind(item: NavigationBarItem): IconKind?
	local icon = item.icon
	if typeof(icon) == "table" and icon.type == "Avatar" then
		return "Avatar"
	elseif typeof(icon) == "string" then
		return "Icon"
	end
	return nil
end

--- One tab of NavigationBar: an icon or avatar with an optional indicator, over a label.
local function NavigationBarTab(props: NavigationBarTabProps): GuiObject
	local tokens = useTokens()
	local item = props.item
	local testId = props.testId

	local iconKind = Vide.derive(function()
		return getIconKind(item())
	end)

	--! Effects can run once with a new icon before the switch removes this branch, so it keeps its own kind's item.
	local function latest(kind: IconKind): () -> NavigationBarItem
		local last = Vide.untrack(item)
		return function()
			local current = item()
			if getIconKind(current) == kind then
				last = current
			end
			return last
		end
	end

	local icon = Vide.switch(iconKind)({
		Avatar = function()
			local avatarItem = latest("Avatar")
			local avatar = AvatarIcon({
				userId = function()
					return (avatarItem().icon :: Types.AvatarAccessoryConfig).userId
				end,
				size = AvatarIconSize.Large,
				testId = `{testId}--avatar`,
			})
			avatar.Name = "Avatar"

			local ring = View({
				tag = function()
					local isActive = props.isActive()
					return {
						["auto-xy radius-circle"] = true,
						["stroke-thick stroke-system-contrast"] = isActive,
						["stroke-standard stroke-emphasis"] = not isActive,
					}
				end,
				testId = `{testId}--avatar-ring`,
				children = avatar,
			})
			ring.Name = "Icon"
			return ring
		end,
		Icon = function()
			local iconItem = latest("Icon")
			local glyph = Icon({
				name = function()
					return iconItem().icon :: string
				end,
				variant = function(): IconVariant
					return if props.isActive()
						then BuilderIcons.IconVariant.Filled
						else BuilderIcons.IconVariant.Regular
				end,
				size = IconSize.Large,
				style = function(): ColorStyleValue
					return tokens().Color.Content.Emphasis :: ColorStyleValue
				end,
				testId = `{testId}--icon`,
			})
			glyph.Name = "Icon"
			return glyph
		end,
	})

	local function indicator(): NavigationBarIndicator?
		return item().indicator
	end

	local status = Vide.show(indicator, function(current: () -> NavigationBarIndicator)
		local function hasValue(): boolean
			return current().value ~= nil
		end
		local statusIndicator = StatusIndicator({
			value = function()
				return current().value
			end,
			max = function()
				return if hasValue() then current().max or DEFAULT_INDICATOR_MAX else math.huge
			end,
			variant = StatusIndicatorVariant.Emphasis,
			size = StatusIndicatorSize.Small,
			mask = function(): ColorStyleValue
				return tokens().Color.Common.NavigationBar :: ColorStyleValue
			end,
			AnchorPoint = function()
				return if hasValue() then Vector2.new(0, 0.5) else Vector2.new(0.5, 0.5)
			end,
			Position = function()
				local size = tokens().Size
				return if hasValue()
					then UDim2.new(1, -size.Size_150, 0, size.Size_50)
					else UDim2.new(1, -size.Size_50, 0, size.Size_50)
			end,
			ZIndex = 2,
			testId = `{testId}--status`,
		})
		statusIndicator.Name = "Status"
		return statusIndicator
	end)

	local media = View({
		LayoutOrder = 1,
		tag = "size-600",
		children = { icon, status },
	})
	media.Name = "Media"

	local label = Text({
		LayoutOrder = 2,
		Text = function()
			return item().text
		end,
		tag = "size-full-0 auto-y text-caption-small text-align-x-center text-truncate-end content-emphasis",
		testId = `{testId}--label`,
	})
	label.Name = "Label"

	local function verticalPadding(): UDim
		local padding = tokens().Padding
		return UDim.new(0, padding.XXSmall + padding.Small)
	end

	local content = View({
		tag = "col align-x-center gap-xxsmall size-full-0 auto-y",
		padding = {
			top = verticalPadding,
			bottom = verticalPadding,
		},
		testId = `{testId}--content`,
		children = { media, label },
	})
	content.Name = "Content"

	return View({
		LayoutOrder = props.LayoutOrder,
		tag = "fill auto-y",
		onActivated = function()
			props.onActivated(Vide.untrack(item).id)
		end,
		stateLayer = { affordance = StateLayerAffordance.None },
		testId = testId,
		children = content,
	})
end

return NavigationBarTab
