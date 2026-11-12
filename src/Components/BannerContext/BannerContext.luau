local Vide = require("../../Packages/Vide")

local BannerContextPresentation = require("../../Enums/BannerContextPresentation")
local BannerContextVariant = require("../../Enums/BannerContextVariant")
local InternalNotice = require("../InternalNotice")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local useBannerContextVariants = require("./useBannerContextVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type BannerContextPresentation = BannerContextPresentation.BannerContextPresentation
type BannerContextVariant = BannerContextVariant.BannerContextVariant
type IconConfig = Types.IconConfig
type InternalNoticeLink = InternalNotice.InternalNoticeLink
type Value<T> = Types.Value<T>

export type BannerContextProps = {
	-- Bordered (Standard) or filled (Emphasis)
	variant: Value<BannerContextVariant>?,
	-- In-flow (Inline) or full-bleed with edge borders for sticky positioning (Affixed)
	presentation: Value<BannerContextPresentation>?,
	-- Message shown in the banner
	text: Value<string>,
	-- Optional leading icon: a Builder icon name, or `{ name, variant }`
	icon: Value<IconConfig?>?,
	-- Optional trailing text link
	link: Value<InternalNoticeLink?>?,
	-- Close affordance. Dismissal is consumer-owned.
	onClose: (() -> ())?,
} & Types.CommonProps

local defaultProps = {
	variant = BannerContextVariant.Standard,
	presentation = BannerContextPresentation.Inline,
	testId = "--foundation-banner-context",
}

--- A one-line banner with contextual information: an icon, a message, a link and a close button.
local function BannerContext(bannerContextProps: BannerContextProps): GuiObject
	local props = withDefaults(bannerContextProps, defaultProps)
	local tokens = useTokens()

	local variantProps = Vide.derive(function()
		return useBannerContextVariants(tokens(), Value.read(props.presentation), Value.read(props.variant))
	end)

	return InternalNotice(withCommonProps(props, {
		text = props.text,
		icon = props.icon,
		link = props.link,
		onClose = props.onClose,
		truncation = true,
		variantProps = variantProps,
	}) :: any)
end

return BannerContext
