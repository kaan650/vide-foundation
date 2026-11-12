local Vide = require("../../Packages/Vide")

local CardDensity = require("../../Enums/CardDensity")
local CardHeaderSize = require("../../Enums/CardHeaderSize")
local CardHeight = require("../../Enums/CardHeight")
local CardMediaAspectRatio = require("../../Enums/CardMediaAspectRatio")
local CardMediaPlacement = require("../../Enums/CardMediaPlacement")
local CardVariant = require("../../Enums/CardVariant")

local CardActions = require("./Subcomponents/CardActions")
local CardHeader = require("./Subcomponents/CardHeader")
local CardMedia = require("./Subcomponents/CardMedia")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local named = require("../../Utility/named")

local useCardVariants = require("./useCardVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type CardDensity = CardDensity.CardDensity
type CardHeaderSize = CardHeaderSize.CardHeaderSize
type CardHeight = CardHeight.CardHeight
type CardMediaAspectRatio = CardMediaAspectRatio.CardMediaAspectRatio
type CardMediaPlacement = CardMediaPlacement.CardMediaPlacement
type CardVariant = CardVariant.CardVariant
type CardVariantProps = useCardVariants.CardVariantProps
type Value<T> = Types.Value<T>

--- A string is an end image at the default width.
export type CardMedia = string | {
	-- Image asset or Foundation image key.
	image: string,
	-- Where the media sits. Defaults to end.
	placement: CardMediaPlacement?,
	-- End only. Defaults to 136.
	width: number?,
	-- Bottom only. Defaults to 2:1.
	aspectRatio: CardMediaAspectRatio?,
}

type CardLineClamp = {
	description: number,
}

export type CardProps = {
	-- Standard is bordered; Emphasis is filled. Defaults to Standard.
	variant: Value<CardVariant>?,
	-- Padding and corner radius: Compact, Default, or Comfortable. Defaults to Default.
	density: Value<CardDensity>?,
	-- Fit hugs content. Fill uses the height the parent layout assigns: leftover height in a column, or the row height in a row.
	height: Value<CardHeight>?,
	-- Header typography. Omit to inherit from density.
	headerSize: Value<CardHeaderSize?>?,
	-- Renders above the title, and only when title is set.
	eyebrow: Value<string?>?,
	-- Icon beside the title. Renders only when title is set.
	icon: Value<Types.IconConfig?>?,
	-- Primary heading shown in the card header.
	title: Value<string?>?,
	-- Supporting copy shown below the title.
	description: Value<string?>?,
	-- Caps description wrapping, for example `{ description = 2 }`. Omit for no limit.
	lineClamp: Value<CardLineClamp?>?,
	-- Shorthand image, or `{ image, placement?, width?, aspectRatio? }`. A string is an end image.
	media: Value<CardMedia?>?,
	-- Activates the whole card.
	onActivated: (() -> ())?,
	-- Shows the overflow button. Does not activate the card.
	onOverflow: (() -> ())?,
	-- Shows the close button. Does not activate the card.
	onClose: (() -> ())?,
	-- Receives the overflow button, for anchoring a menu to it.
	overflowRef: ((GuiObject) -> ())?,
	-- Slot below the header.
	children: Types.Children?,
} & Types.CommonProps

type ResolvedMedia = {
	src: string,
	placement: CardMediaPlacement,
	width: number,
	-- Width / height used to size bottom media.
	aspectRatio: number,
}

local DEFAULT_END_MEDIA_WIDTH = 136
local DEFAULT_ASPECT_RATIO: CardMediaAspectRatio = CardMediaAspectRatio.Ratio2x1

local ASPECT_RATIO_VALUE: { [CardMediaAspectRatio]: number } = {
	[CardMediaAspectRatio.Ratio1x1] = 1,
	[CardMediaAspectRatio.Ratio5x4] = 5 / 4,
	[CardMediaAspectRatio.Ratio4x3] = 4 / 3,
	[CardMediaAspectRatio.Ratio3x2] = 3 / 2,
	[CardMediaAspectRatio.Ratio16x9] = 16 / 9,
	[CardMediaAspectRatio.Ratio2x1] = 2,
}

local defaultProps = {
	variant = CardVariant.Standard :: CardVariant,
	density = CardDensity.Default :: CardDensity,
	height = CardHeight.Fit :: CardHeight,
	testId = "--foundation-card",
}

local defaultHeaderSizes: { [CardDensity]: CardHeaderSize } = {
	[CardDensity.Compact] = CardHeaderSize.Small,
	[CardDensity.Default] = CardHeaderSize.Medium,
	[CardDensity.Comfortable] = CardHeaderSize.Large,
}

local function resolveMedia(media: CardMedia?): ResolvedMedia?
	if typeof(media) == "string" then
		return {
			src = media,
			placement = CardMediaPlacement.End,
			width = DEFAULT_END_MEDIA_WIDTH,
			aspectRatio = ASPECT_RATIO_VALUE[DEFAULT_ASPECT_RATIO],
		}
	end

	if typeof(media) ~= "table" then
		return nil
	end

	local placement: CardMediaPlacement = media.placement or CardMediaPlacement.End
	local width = if placement == CardMediaPlacement.End and media.width ~= nil
		then media.width
		else DEFAULT_END_MEDIA_WIDTH
	local aspectRatio: CardMediaAspectRatio = if placement == CardMediaPlacement.Bottom
			and media.aspectRatio ~= nil
		then media.aspectRatio
		else DEFAULT_ASPECT_RATIO

	return {
		src = media.image,
		placement = placement,
		width = width,
		aspectRatio = ASPECT_RATIO_VALUE[aspectRatio],
	}
end

local function getBottomMediaHeight(media: ResolvedMedia?, bodyWidth: number): number
	if media == nil or media.placement ~= CardMediaPlacement.Bottom then
		return 0
	end

	return math.round(bodyWidth / media.aspectRatio)
end

--- A bordered or filled surface grouping a header (eyebrow, icon, title, description), a content slot and an
--- optional end or bottom image, with optional overflow and close buttons.
local function Card(cardProps: CardProps): GuiObject
	local props = withDefaults(cardProps, defaultProps)
	local tokens = useTokens()
	local testId = props.testId

	local function density(): CardDensity
		return Value.read(props.density)
	end
	local function height(): CardHeight
		return Value.read(props.height)
	end
	local function eyebrow(): string?
		return Value.read(props.eyebrow)
	end
	local function title(): string?
		return Value.read(props.title)
	end
	local function description(): string?
		return Value.read(props.description)
	end

	local hasHeader = Vide.derive(function()
		return title() ~= nil or description() ~= nil
	end)
	local resolvedMedia = Vide.derive(function()
		return resolveMedia(Value.read(props.media))
	end)
	local hasEndMedia = Vide.derive(function()
		local media = resolvedMedia()
		return media ~= nil and media.placement == CardMediaPlacement.End
	end)
	local hasActions = props.onOverflow ~= nil or props.onClose ~= nil
	local actionsAreInline = Vide.derive(function()
		return hasHeader() and not hasEndMedia()
	end)
	local isFillHeight = Vide.derive(function()
		return height() == CardHeight.Fill
	end)

	local variantProps = Vide.derive(function(): CardVariantProps
		local headerSize: CardHeaderSize = Value.read(props.headerSize) or defaultHeaderSizes[density()]
		local isSingleLine = (eyebrow() == nil or title() == nil) and description() == nil
		return useCardVariants(
			tokens(),
			Value.read(props.variant),
			density(),
			headerSize,
			height(),
			hasEndMedia(),
			isSingleLine,
			actionsAreInline()
		)
	end)

	local bodyWidth = Vide.source(0)
	local contentHeight = Vide.source(0)
	local bottomMediaHeight = Vide.derive(function()
		return getBottomMediaHeight(resolvedMedia(), bodyWidth())
	end)

	local function actions(isInline: boolean): GuiObject
		return named(
			"Actions",
			CardActions({
				testId = testId,
				variantProps = variantProps,
				onOverflow = props.onOverflow,
				onClose = props.onClose,
				overflowRef = props.overflowRef,
				isOverMedia = hasEndMedia,
				isInline = isInline,
			})
		)
	end

	local header = Vide.show(hasHeader, function()
		return named(
			"Header",
			CardHeader({
				testId = testId,
				variantProps = variantProps,
				eyebrow = eyebrow,
				icon = function()
					return Value.read(props.icon)
				end,
				title = title,
				description = description,
				descriptionLineClamp = function(): number?
					local lineClamp = Value.read(props.lineClamp)
					return if lineClamp then lineClamp.description else nil
				end,
				actions = if hasActions
					then function()
						return Vide.show(actionsAreInline, function()
							return actions(true)
						end)
					end
					else nil,
			})
		)
	end)

	local slot: GuiObject? = nil
	if props.children ~= nil then
		slot = named(
			"Children",
			View({
				tag = function()
					return variantProps().children.tag
				end,
				LayoutOrder = 2,
				testId = `{testId}--content`,
				children = props.children,
			})
		)
	end

	local content = named(
		"Content",
		View({
			tag = function()
				return variantProps().content.tag
			end,
			onAbsoluteSizeChanged = function(rbx: GuiObject)
				contentHeight(rbx.AbsoluteSize.Y)
			end,
			LayoutOrder = 1,
			children = { header, slot },
		})
	)

	local media = Vide.show(resolvedMedia, function(current: () -> ResolvedMedia)
		return named(
			"Media",
			CardMedia({
				image = function()
					return current().src
				end,
				width = function()
					return current().width
				end,
				isEnd = hasEndMedia,
				isFillHeight = isFillHeight,
				bottomHeight = bottomMediaHeight,
				tag = function()
					return variantProps().media.tag
				end,
				testId = testId,
			})
		)
	end)

	--* Bottom media needs a pixel height; AbsoluteSize only reports changes, so the width is tracked even before
	--* media exists.
	local body = named(
		"Body",
		View({
			tag = function()
				return variantProps().body.tag
			end,
			onAbsoluteSizeChanged = function(rbx: GuiObject)
				bodyWidth(rbx.AbsoluteSize.X)
			end,
			children = { content, media },
		})
	)

	local outerActions = if hasActions
		then Vide.show(function()
			return not actionsAreInline()
		end, function()
			return actions(false)
		end)
		else nil

	--* Fill uses a measured min height so the body can size-full while stretching with siblings.
	return View(withCommonProps(props, {
		tag = function()
			return variantProps().container.tag
		end,
		sizeConstraint = function(): Types.SizeConstraint?
			return if isFillHeight() then { MinSize = Vector2.new(0, contentHeight() + bottomMediaHeight()) } else nil
		end,
		onActivated = props.onActivated,
		children = { body, outerActions },
	}) :: any)
end

return Card
