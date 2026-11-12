local Vide = require("../../Packages/Vide")

local AccessoryType = require("../../Enums/AccessoryType")
local AvatarIcon = require("../AvatarIcon")
local Icon = require("../Icon")
local MetadataSize = require("../../Enums/MetadataSize")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local getMultiLineTextHeight = require("../../Utility/getMultiLineTextHeight")
local named = require("../../Utility/named")
local useMetadataVariants = require("./useMetadataVariants")
local useTextSizeOffset = require("../../Providers/Style/useTextSizeOffset")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type MetadataVariantProps = useMetadataVariants.MetadataVariantProps
type IconAccessoryConfig = Types.IconAccessoryConfig
type AvatarAccessoryConfig = Types.AvatarAccessoryConfig
type MetadataSize = MetadataSize.MetadataSize
type Value<T> = Types.Value<T>

export type MetadataAccessory = IconAccessoryConfig | AvatarAccessoryConfig

type MetadataItemConfig = {
	-- Label for this item; it truncates when it is the list's `truncateIndex` item.
	text: string,
	-- Icon name, icon config, or avatar rendered before this item's text.
	leading: (string | MetadataAccessory)?,
}

export type MetadataItem = string | MetadataItemConfig

export type MetadataProps = {
	-- A single item, or a list of items joined by `·` (or spaced apart when `hasSeparator` is false).
	text: Value<MetadataItem | { MetadataItem }>,
	-- Icon rendered after the last item.
	trailing: Value<(string | IconAccessoryConfig)?>?,
	-- 1-based list item that truncates when the parent is too narrow. Defaults to the last item; clamped to the list length.
	truncateIndex: Value<number?>?,
	-- Lines a single item can wrap to before truncating. Defaults to 1; lists always stay on one line.
	maxLines: Value<number>?,
	-- **DEPRECATED**: Loading belongs on the containing tile or card. Still accepted but ignored.
	isLoading: Value<boolean>?,
	-- Separates list items with `·`; when false, items are spaced apart instead. Defaults to true.
	hasSeparator: Value<boolean>?,
	-- Text style: `Medium` (body medium) or `Small` (body small, for use next to smaller headings). Icons, avatars, and spacing stay the same. Defaults to `Medium`.
	size: Value<MetadataSize>?,
} & Types.CommonProps

local SEPARATOR = "·"

local defaultProps = {
	size = MetadataSize.Medium :: MetadataSize,
	maxLines = 1,
	hasSeparator = true,
	testId = "--foundation-metadata",
}

type AccessoryKind = "Avatar" | "Icon"

local function toAccessory(config: (string | MetadataAccessory)?): MetadataAccessory?
	if config == nil then
		return nil
	end
	return if type(config) == "string" then { iconName = config } :: MetadataAccessory else config
end

local function kindOf(accessory: MetadataAccessory?): AccessoryKind?
	if accessory == nil then
		return nil
	end
	return if accessory.type == AccessoryType.Avatar then "Avatar" else "Icon"
end

local function isSingle(text: MetadataItem | { MetadataItem }): boolean
	return type(text) == "string" or (text :: MetadataItemConfig).text ~= nil
end

local function toItems(text: MetadataItem | { MetadataItem }): { MetadataItemConfig }
	local entries: { MetadataItem } = if isSingle(text) then { text :: MetadataItem } else text :: { MetadataItem }
	local items: { MetadataItemConfig } = {}
	for _, entry in entries do
		table.insert(items, if type(entry) == "string" then { text = entry } else entry :: MetadataItemConfig)
	end
	return items
end

--- An icon or avatar beside a metadata item, named `name`. Returns a source rebuilt when the accessory changes kind.
local function Accessory(
	name: string,
	read: () -> (string | MetadataAccessory)?,
	variantProps: () -> MetadataVariantProps,
	layoutOrder: number,
	testId: string
): () -> any
	local accessory = Vide.derive(function()
		return toAccessory(read())
	end)

	--! Bindings can read a new accessory once before the switch removes their branch, so each branch keeps the
	--! last accessory of its own kind.
	local function latest(kind: AccessoryKind): () -> any
		local last: any = Vide.untrack(accessory)
		return function()
			local current = accessory()
			if kindOf(current) == kind then
				last = current
			end
			return last
		end
	end

	return Vide.switch(function(): AccessoryKind?
		return kindOf(accessory())
	end)({
		Avatar = function()
			local config = latest("Avatar")
			return named(
				name,
				View({
					tag = function()
						return variantProps().accessory.avatarTag
					end,
					LayoutOrder = layoutOrder,
					children = named(
						"Avatar",
						AvatarIcon({
							userId = function(): number
								return (config() :: AvatarAccessoryConfig).userId
							end,
							size = function()
								return variantProps().accessory.avatarSize
							end,
							testId = testId,
						})
					),
				})
			)
		end,
		Icon = function()
			local config = latest("Icon")
			return named(
				name,
				Icon({
					name = function(): string
						return (config() :: IconAccessoryConfig).iconName
					end,
					variant = function()
						return (config() :: IconAccessoryConfig).iconVariant :: any
					end,
					size = function()
						return variantProps().accessory.iconSize
					end,
					style = function()
						return variantProps().accessory.style
					end,
					LayoutOrder = layoutOrder,
					testId = testId,
				})
			)
		end,
	})
end

--- A short line of non-interactive context: one item, or a list of items joined by `·`, with optional icons or
--- avatars. Truncates one item when its parent is too narrow.
local function Metadata(metadataProps: MetadataProps): GuiObject
	local props = withDefaults(metadataProps, defaultProps)
	local tokens = useTokens()
	local textSizeOffset = useTextSizeOffset()
	local testId = props.testId

	local function hasSeparator(): boolean
		return Value.read(props.hasSeparator)
	end

	local variantProps = Vide.derive(function(): MetadataVariantProps
		return useMetadataVariants(tokens(), Value.read(props.size), not hasSeparator())
	end)

	local items = Vide.derive(function()
		return toItems(Value.read(props.text))
	end)
	local itemCount = Vide.derive(function()
		return #items()
	end)
	local truncateIndex = Vide.derive(function(): number
		local count = itemCount()
		return math.clamp(Value.read(props.truncateIndex) or count, 1, math.max(count, 1))
	end)
	local maxLines = Vide.derive(function(): number
		return if isSingle(Value.read(props.text)) then math.max(Value.read(props.maxLines), 1) else 1
	end)
	local textHeight = Vide.derive(function(): number
		local typography = variantProps().text.fontStyle
		return getMultiLineTextHeight(
			(typography.FontSize or 0) + textSizeOffset(),
			maxLines(),
			typography.LineHeight or 1
		)
	end)

	local function trailing(): (string | IconAccessoryConfig)?
		return Value.read(props.trailing)
	end

	local children = Vide.indexes(items, function(item: () -> MetadataItemConfig, index: number)
		local separator = Vide.show(function()
			return index > 1 and hasSeparator()
		end, function()
			return named(
				`Separator{index - 1}`,
				Text({
					Text = SEPARATOR,
					tag = function()
						return variantProps().text.tag
					end,
					LayoutOrder = index * 2 - 1,
					testId = `{testId}--separator-{index - 1}`,
				})
			)
		end)

		local leading = Accessory("Leading", function()
			return item().leading
		end, variantProps, 1, `{testId}--item-{index}--leading`)

		local itemTrailing = Accessory("Trailing", function()
			return if index == itemCount() then trailing() else nil
		end, variantProps, 4, `{testId}--trailing`)

		local text = named(
			"Text",
			Text({
				Text = function()
					return item().text
				end,
				OpenTypeFeatures = function()
					return variantProps().text.openTypeFeatures
				end,
				tag = function()
					local variant = variantProps()
					return if maxLines() > 1
						then variant.wrappedText.tag
						elseif index == truncateIndex() then variant.truncatedText.tag
						else variant.text.tag
				end,
				sizeConstraint = function(): Types.SizeConstraint?
					return if maxLines() > 1 then { MaxSize = Vector2.new(math.huge, textHeight()) } else nil
				end,
				LayoutOrder = 3,
				testId = `{testId}--text-{index}`,
			})
		)

		local itemView = named(
			`Item{index}`,
			View({
				tag = function()
					local variant = variantProps()
					return if index == truncateIndex() then variant.truncatedItem.tag else variant.item.tag
				end,
				LayoutOrder = index * 2,
				testId = `{testId}--item-{index}`,
				children = { leading, text, itemTrailing },
			})
		)

		return { separator, itemView }
	end)

	return View(withCommonProps(props, {
		tag = function()
			return variantProps().container.tag
		end,
		children = children,
	}) :: any)
end

return Metadata
