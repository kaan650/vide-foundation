local Vide = require("../../../Packages/Vide")

local BuilderIcons = require("../../../Packages/BuilderIcons")

local Icon = require("../../Icon")
local InputSize = require("../../../Enums/InputSize")
local Text = require("../../Text")
local Types = require("../../Types")
local View = require("../../View")
local getSharedVariants = require("../../Button/getSharedVariants")
local named = require("../../../Utility/named")
local useCardVariants = require("../useCardVariants")
local useTokens = require("../../../Providers/Style/useTokens")

type CardVariantProps = useCardVariants.CardVariantProps
type IconConfig = Types.IconConfig
type IconVariant = BuilderIcons.IconVariant

type CardHeaderProps = {
	testId: string,
	variantProps: () -> CardVariantProps,
	eyebrow: () -> string?,
	icon: () -> IconConfig?,
	title: () -> string?,
	description: () -> string?,
	descriptionLineClamp: () -> number?,
	-- The inline overflow and close buttons, built inside the header.
	actions: (() -> any)?,
}

--- The card's eyebrow, title row and description, with the inline actions beside them.
local function CardHeader(props: CardHeaderProps): GuiObject
	local tokens = useTokens()
	local variantProps = props.variantProps
	local testId = props.testId

	local iconName = Vide.derive(function(): string?
		local icon = props.icon()
		return if typeof(icon) == "table" then icon.name else icon
	end)

	local descriptionMaxHeight = Vide.derive(function(): number?
		local lineClamp = props.descriptionLineClamp()
		return if lineClamp ~= nil then variantProps().description.lineHeight * lineClamp else nil
	end)

	local eyebrow = Vide.show(function(): string?
		return if props.title() ~= nil then props.eyebrow() else nil
	end, function(text: () -> string)
		return named(
			"Eyebrow",
			Text({
				Text = text,
				tag = function()
					return variantProps().eyebrow.tag
				end,
				LayoutOrder = 1,
				testId = `{testId}--eyebrow`,
			})
		)
	end)

	local titleRow = Vide.show(props.title, function(title: () -> string)
		local icon = Vide.show(iconName, function(name: () -> string)
			return named(
				"Icon",
				Icon({
					name = name,
					variant = function()
						local config = props.icon()
						return (if typeof(config) == "table" then config.variant else nil) :: any
					end,
					size = function()
						return variantProps().icon.size
					end,
					LayoutOrder = 1,
					testId = `{testId}--icon`,
				})
			)
		end)

		--* The title hugs its text and shrinks, so a long title wraps beside the icon rather than pushing it out of
		--* the row.
		local titleText = named(
			"Title",
			Text({
				Text = title,
				tag = function()
					return variantProps().title.tag
				end,
				LayoutOrder = 2,
				testId = `{testId}--title`,
			})
		)

		return named(
			"TitleRow",
			View({
				tag = function()
					return variantProps().titleRow.tag
				end,
				layout = function(): Types.ListLayout?
					local gap = variantProps().titleRow.gap
					return if gap
						then { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, gap) }
						else nil
				end,
				LayoutOrder = 2,
				testId = `{testId}--title-row`,
				children = { icon, titleText },
			})
		)
	end)

	local description = Vide.show(props.description, function(text: () -> string)
		return named(
			"Description",
			Text({
				Text = text,
				TextTruncate = function()
					return if descriptionMaxHeight() then Enum.TextTruncate.AtEnd else Enum.TextTruncate.None
				end,
				sizeConstraint = function(): Types.SizeConstraint?
					local maxHeight = descriptionMaxHeight()
					return if maxHeight then { MaxSize = Vector2.new(math.huge, maxHeight) } else nil
				end,
				tag = function()
					return variantProps().description.tag
				end,
				LayoutOrder = 3,
				testId = `{testId}--description`,
			})
		)
	end)

	local text = named(
		"Text",
		View({
			tag = function()
				return variantProps().headerText.tag
			end,
			LayoutOrder = 1,
			testId = `{testId}--header-content`,
			children = { eyebrow, titleRow, description },
		})
	)

	--* The minimum height belongs to the row so the text hugs its own content: a text column padded out to the
	--* minimum would top-align its title while the row centers the actions. It is the Small IconButton's height, so a
	--* header without those buttons stays the same height in a group.
	return View({
		tag = function()
			return variantProps().header.tag
		end,
		sizeConstraint = {
			MinSize = function()
				return Vector2.new(0, getSharedVariants(tokens()).sizes[InputSize.Small].container.height)
			end,
		},
		LayoutOrder = 1,
		testId = `{testId}--header`,
		children = { text, if props.actions then props.actions() else nil },
	})
end

return CardHeader
