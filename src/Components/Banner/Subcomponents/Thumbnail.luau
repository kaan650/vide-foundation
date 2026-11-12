local Vide = require("../../../Packages/Vide")

local BuilderIcons = require("../../../Packages/BuilderIcons")

local Avatar = require("../../Avatar")
local Icon = require("../../Icon")
local Image = require("../../Image")
local Types = require("../../Types")
local View = require("../../View")
local named = require("../../../Utility/named")
local useTokens = require("../../../Providers/Style/useTokens")

local AvatarSize = require("../../../Enums/AvatarSize")
local CardDensity = require("../../../Enums/CardDensity")
local IconSize = require("../../../Enums/IconSize")
local UserPresence = require("../../../Enums/UserPresence")

type IconConfig = Types.IconConfig
type IconVariant = BuilderIcons.IconVariant
type UserPresence = UserPresence.UserPresence

export type BannerDensity = typeof(CardDensity.Compact) | typeof(CardDensity.Default)

export type BannerThumbnail =
	{
		type: "Avatar",
		userId: number,
		userPresence: UserPresence?,
	}
	| {
		type: "Image",
		image: string,
	}
	| {
		type: "Icon",
		icon: IconConfig,
	}
	| {
		type: "Slot",
		children: Types.Children,
	}

type ThumbnailKind = "Avatar" | "Image" | "Icon" | "Slot"

export type ThumbnailProps = {
	thumbnail: () -> BannerThumbnail,
	density: () -> BannerDensity,
	testId: string,
	LayoutOrder: number,
}

--- The small banner's leading accessory: an avatar, an image, an icon or the caller's own content, in a square
--- sized by density. Rebuilds its content when the thumbnail changes type.
local function Thumbnail(props: ThumbnailProps): GuiObject
	local tokens = useTokens()
	local testId = props.testId

	local function isCompact(): boolean
		return props.density() == CardDensity.Compact
	end

	--! Bindings can read a new thumbnail once before the switch removes their branch, so each branch keeps the last
	--! thumbnail of its own type.
	local function latest(kind: ThumbnailKind): () -> any
		local last: any = Vide.untrack(props.thumbnail)
		return function()
			local current = props.thumbnail()
			if current.type == kind then
				last = current
			end
			return last
		end
	end

	local content = Vide.switch(function(): ThumbnailKind
		return props.thumbnail().type
	end)({
		Avatar = function()
			local thumbnail = latest("Avatar")
			return named(
				"Content",
				Avatar({
					userId = function(): number
						return thumbnail().userId
					end,
					size = function()
						return if isCompact() then AvatarSize.Large else AvatarSize.XLarge
					end,
					userPresence = function()
						return thumbnail().userPresence
					end,
					testId = `{testId}--thumbnail-avatar`,
				})
			)
		end,
		Image = function()
			local thumbnail = latest("Image")
			return named(
				"Content",
				Image({
					Image = function(): string
						return thumbnail().image
					end,
					ScaleType = Enum.ScaleType.Crop,
					tag = "size-full radius-medium",
					testId = `{testId}--thumbnail-image`,
				})
			)
		end,
		Icon = function()
			local thumbnail = latest("Icon")
			return named(
				"Content",
				Icon({
					name = function(): string
						local icon: IconConfig = thumbnail().icon
						return if typeof(icon) == "table" then icon.name else icon
					end,
					variant = function()
						local icon: IconConfig = thumbnail().icon
						return (if typeof(icon) == "table" then icon.variant else nil) :: any
					end,
					size = IconSize.Large,
					testId = `{testId}--thumbnail-icon`,
				})
			)
		end,
		--* The slot is the caller's content, so it is clipped to the accessory box rather than letting an oversized
		--* child push the row wider.
		Slot = function()
			local thumbnail = latest("Slot")
			return named(
				"Content",
				View({
					tag = "align-x-center align-y-center size-full clip",
					testId = `{testId}--thumbnail-slot`,
					children = function()
						return thumbnail().children
					end,
				})
			)
		end,
	})

	return View({
		tag = "align-x-center align-y-center",
		Size = function()
			local size = if isCompact() then tokens().Size.Size_1200 else tokens().Size.Size_1600
			return UDim2.fromOffset(size, size)
		end,
		LayoutOrder = props.LayoutOrder,
		testId = `{testId}--thumbnail`,
		children = content,
	})
end

return Thumbnail
