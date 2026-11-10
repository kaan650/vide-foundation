local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
type IconVariant = BuilderIcons.IconVariant

local Icon = require("../Icon")
local Image = require("../Image")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local getIconScale = require("../../Utility/getIconScale")
local iconMigrationUtils = require("../../Utility/iconMigrationUtils")
local useBadgeVariants = require("./useBadgeVariants")
local useIconSize = require("../../Utility/useIconSize")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local BadgeVariant = require("../../Enums/BadgeVariant")
type BadgeVariant = BadgeVariant.BadgeVariant
local BadgeShape = require("../../Enums/BadgeShape")
type BadgeShape = BadgeShape.BadgeShape
local BadgeSize = require("../../Enums/BadgeSize")
type BadgeSize = BadgeSize.BadgeSize
local IconSize = require("../../Enums/IconSize")
local IconPosition = require("../../Enums/IconPosition")
type IconPosition = IconPosition.IconPosition

type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

export type BadgeIcon = {
	name: string,
	variant: IconVariant?,
	position: IconPosition,
}

export type BadgeProps = {
	text: Value<string?>?,
	-- An icon name shows on the left; a table also sets the position and variant.
	icon: Value<(string | BadgeIcon)?>?,
	variant: Value<BadgeVariant>?,
	shape: Value<BadgeShape>?,
	size: Value<BadgeSize>?,
	-- DEPRECATED
	isDisabled: Value<boolean>?,
} & Types.CommonProps

local defaultProps = {
	variant = BadgeVariant.Contrast,
	shape = BadgeShape.Pill,
	size = BadgeSize.Small,
	testId = "--foundation-badge",
}

-- DEPRECATED Primary, Secondary and Neutral are scheduled for removal in Foundation 2.0.
local deprecatedVariantsMapping: { [BadgeVariant]: BadgeVariant } = {
	[BadgeVariant.Primary] = BadgeVariant.Contrast,
	[BadgeVariant.Secondary] = BadgeVariant.Neutral,
}

type IconKind = "glyph" | "image"

type IconState = {
	kind: IconKind?,
	name: string,
	variant: IconVariant?,
	layoutOrder: number,
	intrinsicSize: Vector2?,
	scale: number,
}

local NO_ICON: IconState = { name = "", layoutOrder = 1, scale = 1 }

local function getIconState(icon: BadgeIcon?): IconState
	if not icon then
		return NO_ICON
	end
	local layoutOrder = if icon.position == IconPosition.Left then 1 else 3
	if iconMigrationUtils.isBuilderOrMigratedIcon(icon.name) then
		local normalized = iconMigrationUtils.normalizeIconName(icon.name)
		return {
			kind = "glyph",
			name = normalized.name,
			variant = if iconMigrationUtils.isMigrated(icon.name) then normalized.variant else icon.variant,
			layoutOrder = layoutOrder,
			scale = 1,
		}
	end
	local intrinsicSize, scale = getIconScale(icon.name, IconSize.XSmall)
	return {
		kind = if intrinsicSize then "image" else nil,
		name = icon.name,
		layoutOrder = layoutOrder,
		intrinsicSize = intrinsicSize,
		scale = scale,
	}
end

--- A small pill or box with a text, an icon, or both.
local function Badge(badgeProps: BadgeProps): GuiObject
	local props = withDefaults(badgeProps, defaultProps)
	local tokens = useTokens()
	local iconDimensions = useIconSize(IconSize.XSmall, true)

	local iconState = Vide.derive(function(): IconState
		local icon = Value.read(props.icon)
		return getIconState(if typeof(icon) == "string" then { name = icon, position = IconPosition.Left } else icon)
	end)

	local hasText = Vide.derive(function()
		local text = Value.read(props.text)
		return text ~= nil and #text > 0
	end)

	local variantProps = Vide.derive(function()
		local variant: BadgeVariant = Value.read(props.variant)
		return useBadgeVariants(
			tokens(),
			deprecatedVariantsMapping[variant] or variant,
			Value.read(props.shape),
			not hasText()
		)
	end)

	local function contentStyle(): ColorStyleValue
		return variantProps().content.style
	end

	--! Effects can run once with a new icon before the switch removes this branch, so it keeps its own kind's state.
	local function latest(kind: IconKind): () -> IconState
		local last = Vide.untrack(iconState)
		return function()
			local current = iconState()
			if current.kind == kind then
				last = current
			end
			return last
		end
	end

	local icon = Vide.switch(function()
		return iconState().kind
	end)({
		glyph = function()
			local state = latest("glyph")
			local glyph = Icon({
				name = function()
					return state().name
				end,
				variant = function(): IconVariant
					return state().variant :: IconVariant
				end,
				size = IconSize.XSmall,
				style = contentStyle,
				LayoutOrder = function()
					return state().layoutOrder
				end,
				testId = `{props.testId}--icon`,
			})
			glyph.Name = "Icon"
			return glyph
		end,
		image = function()
			local state = latest("image")
			local image = Image({
				Image = function()
					return state().name
				end,
				Size = function()
					local size = state().intrinsicSize or Vector2.zero
					return UDim2.fromOffset(size.X, size.Y)
				end,
				imageStyle = contentStyle,
				scale = function()
					return state().scale
				end,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				LayoutOrder = function()
					return state().layoutOrder
				end,
				testId = `{props.testId}--icon`,
			})
			image.Name = "Children"
			local wrapper = View({ Size = iconDimensions, children = image })
			wrapper.Name = "Icon"
			return wrapper
		end,
	})

	local text = Vide.show(hasText, function()
		local label = Text({
			Text = function()
				return Value.read(props.text) or ""
			end,
			textStyle = contentStyle,
			RichText = true,
			LayoutOrder = 2,
			tag = function()
				return variantProps().text.tag
			end,
			testId = `{props.testId}--text`,
		})
		label.Name = "Text"
		return label
	end)

	return View(withCommonProps(props, {
		backgroundStyle = function(): ColorStyleValue
			return variantProps().container.backgroundStyle
		end,
		stroke = function()
			return variantProps().container.stroke
		end,
		tag = function()
			return variantProps().container.tag
		end,
		children = { icon, text },
	}) :: any)
end

return Badge
