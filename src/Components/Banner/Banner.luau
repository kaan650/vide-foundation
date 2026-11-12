local Button = require("../Button")
local Card = require("../Card")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local named = require("../../Utility/named")

local BannerSize = require("../../Enums/BannerSize")
local ButtonVariant = require("../../Enums/ButtonVariant")
local CardDensity = require("../../Enums/CardDensity")
local CardHeaderSize = require("../../Enums/CardHeaderSize")
local CardVariant = require("../../Enums/CardVariant")
local InputSize = require("../../Enums/InputSize")

local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local Thumbnail = require("./Subcomponents/Thumbnail")
local UpsellContent = require("./Subcomponents/UpsellContent")

type CardProps = Card.CardProps
type CardMedia = Card.CardMedia
type BannerSize = BannerSize.BannerSize
type CardHeaderSize = CardHeaderSize.CardHeaderSize
type Value<T> = Types.Value<T>

export type BannerDensity = Thumbnail.BannerDensity

export type BannerThumbnail = Thumbnail.BannerThumbnail

--- End image. A string uses the default width. A table can set width.
export type BannerMedia = string | {
	-- Image asset or Foundation image key.
	image: string,
	-- End-image width in pixels. Defaults to the card end width (136) when omitted.
	width: number?,
}

--! Foundation types these props as a Medium | Small union keyed by `size`. The new solver rejects table literals
--! against that union, so they are merged here: Small ignores `media` and `actions.secondary`, Medium ignores
--! `thumbnail`.
export type BannerProps = {
	-- Medium (default) supports `media` and a secondary action; Small supports a `thumbnail`. Read once.
	size: BannerSize?,
	-- Padding density of the banner card. Defaults to `CardDensity.Default`.
	density: Value<BannerDensity>?,
	-- Primary heading of the banner.
	title: Value<string?>?,
	-- Supporting copy under the title.
	description: Value<string?>?,
	-- Shows a close button. Medium uses Card's close button and keeps it when actions are set. On Small it is vertically centered and ignored when a primary action is set.
	onClose: (() -> ())?,
	-- Medium only: end media image.
	media: Value<BannerMedia?>?,
	-- Small only: leading thumbnail.
	thumbnail: Value<BannerThumbnail?>?,
	-- Optional primary and secondary actions.
	actions: {
		-- Primary action. Activates the banner.
		primary: {
			-- Called when the primary action is activated.
			onActivated: () -> (),
		}?,
		-- Medium only: optional secondary button.
		secondary: {
			-- Label shown on the secondary button.
			text: Value<string>,
			-- Called when the secondary action is activated.
			onActivated: () -> (),
		}?,
	}?,
} & Types.CommonProps

local defaultProps = {
	density = CardDensity.Default :: BannerDensity,
	testId = "--foundation-banner",
}

local function toCardMedia(media: BannerMedia?): CardMedia?
	return if typeof(media) == "table" then { image = media.image, width = media.width } else media
end

--- A filled card that highlights a message: Medium has a title, description, end image and secondary button;
--- Small is a single row with a thumbnail. A primary action activates the whole banner. `size` picks the layout once.
local function Banner(bannerProps: BannerProps): GuiObject
	local props = withDefaults(bannerProps, defaultProps)
	local testId = props.testId
	local actions = props.actions
	local primaryAction = if actions then actions.primary else nil

	local function density(): BannerDensity
		return Value.read(props.density)
	end
	local function isCompact(): boolean
		return density() == CardDensity.Compact
	end

	local cardProps: CardProps = {
		variant = CardVariant.Emphasis,
		density = props.density,
		headerSize = function(): CardHeaderSize
			return if isCompact() then CardHeaderSize.Small else CardHeaderSize.Medium
		end,
		onActivated = if primaryAction then primaryAction.onActivated else nil,
	}

	if props.size == BannerSize.Small then
		cardProps.children = named(
			"UpsellContent",
			UpsellContent({
				density = density,
				title = function()
					return Value.read(props.title)
				end,
				description = function()
					return Value.read(props.description)
				end,
				thumbnail = function(): BannerThumbnail?
					return Value.read(props.thumbnail)
				end,
				onActivated = if primaryAction then primaryAction.onActivated else nil,
				onClose = if primaryAction then nil else props.onClose,
				testId = testId,
			})
		)
	else
		local secondaryAction = if actions then actions.secondary else nil
		cardProps.onClose = props.onClose
		cardProps.title = props.title
		cardProps.description = props.description
		cardProps.lineClamp = function()
			return { description = if isCompact() then 2 else 3 }
		end
		local media = props.media
		cardProps.media = if type(media) == "function"
			then function()
				return toCardMedia(media())
			end
			else toCardMedia(media)
		if secondaryAction then
			cardProps.children = named(
				"SecondaryAction",
				Button({
					text = secondaryAction.text,
					onActivated = secondaryAction.onActivated,
					variant = ButtonVariant.SoftEmphasis,
					size = InputSize.Small,
					LayoutOrder = 1,
					testId = `{testId}--secondary-action`,
				})
			)
		end
	end

	return Card(withCommonProps(props, cardProps))
end

return Banner
