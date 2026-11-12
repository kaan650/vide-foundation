local Vide = require("../../../Packages/Vide")

local BuilderIcons = require("../../../Packages/BuilderIcons")

local ButtonVariant = require("../../../Enums/ButtonVariant")
local InputSize = require("../../../Enums/InputSize")

local Icon = require("../../Icon")
local IconButton = require("../../IconButton")
local Text = require("../../Text")
local View = require("../../View")
local named = require("../../../Utility/named")

local useTokens = require("../../../Providers/Style/useTokens")

local Thumbnail = require("./Thumbnail")
local useUpsellContentVariants = require("./useUpsellContentVariants")

type BannerDensity = Thumbnail.BannerDensity
type BannerThumbnail = Thumbnail.BannerThumbnail
type UpsellContentVariantProps = useUpsellContentVariants.UpsellContentVariantProps

local IconName = BuilderIcons.Icon

export type UpsellContentProps = {
	density: () -> BannerDensity,
	title: () -> string?,
	description: () -> string?,
	thumbnail: () -> BannerThumbnail?,
	onActivated: (() -> ())?,
	onClose: (() -> ())?,
	testId: string,
}

--- The small banner's row: thumbnail, title and description, then a chevron when the banner activates or a close
--- button when it doesn't.
local function UpsellContent(props: UpsellContentProps): GuiObject
	local tokens = useTokens()
	local testId = props.testId
	local hasPrimaryAction = props.onActivated ~= nil

	local variantProps = Vide.derive(function(): UpsellContentVariantProps
		return useUpsellContentVariants(tokens(), props.density())
	end)

	local thumbnail = Vide.show(props.thumbnail, function(current: () -> BannerThumbnail)
		return named(
			"Thumbnail",
			Thumbnail({
				thumbnail = current,
				density = props.density,
				testId = testId,
				LayoutOrder = 1,
			})
		)
	end)

	local title = Vide.show(props.title, function(text: () -> string)
		return named(
			"Title",
			Text({
				Text = text,
				tag = function()
					return variantProps().title.tag
				end,
				LayoutOrder = 1,
				testId = `{testId}--title`,
			})
		)
	end)

	local description = Vide.show(props.description, function(text: () -> string)
		return named(
			"Description",
			Text({
				Text = text,
				TextTruncate = Enum.TextTruncate.AtEnd,
				sizeConstraint = {
					MaxSize = function()
						return variantProps().description.sizeConstraint.MaxSize :: Vector2
					end,
				},
				tag = function()
					return variantProps().description.tag
				end,
				LayoutOrder = 2,
				testId = `{testId}--description`,
			})
		)
	end)

	local content = named(
		"Content",
		View({
			tag = function()
				return variantProps().content.tag
			end,
			LayoutOrder = 2,
			testId = `{testId}--upsell-content--body`,
			children = { title, description },
		})
	)

	local chevron: GuiObject? = nil
	if hasPrimaryAction then
		chevron = named(
			"Chevron",
			Icon({
				name = IconName.ChevronSmallRight,
				LayoutOrder = 3,
				testId = `{testId}--chevron`,
			})
		)
	end

	local close: any = nil
	local onClose = props.onClose
	if onClose and not hasPrimaryAction then
		close = named(
			"Close",
			IconButton({
				onActivated = onClose,
				icon = IconName.X,
				variant = ButtonVariant.Utility,
				size = InputSize.Small,
				isCircular = true,
				LayoutOrder = 4,
				testId = `{testId}--close`,
			})
		)
	end

	return View({
		tag = function()
			return variantProps().container.tag
		end,
		LayoutOrder = 1,
		testId = `{testId}--upsell-content`,
		children = { thumbnail, content, chevron, close },
	})
end

return UpsellContent
