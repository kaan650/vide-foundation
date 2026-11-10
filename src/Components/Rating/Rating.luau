local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
local IconName = BuilderIcons.Icon
local IconVariant = BuilderIcons.IconVariant

local ChipSize = require("../../Enums/ChipSize")
local Divider = require("../Divider")
local Icon = require("../Icon")
local Orientation = require("../../Enums/Orientation")
local RatingValue = require("../../Enums/RatingValue")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local useRatingVariants = require("./useRatingVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ChipSize = ChipSize.ChipSize
type RatingValue = RatingValue.RatingValue
type Value<T> = Types.Value<T>

export type RatingProps = {
	text: Value<string>,
	size: Value<ChipSize>?,
	value: Value<RatingValue>,
	onThumbUp: () -> (),
	onThumbDown: () -> (),
} & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	size = ChipSize.Medium,
	value = RatingValue.None,
	Selectable = true,
	testId = "--foundation-rating",
}

--- A thumbs-up/thumbs-down pill; the recorded thumb is filled.
local function Rating(ratingProps: RatingProps): GuiObject
	local props = withDefaults(ratingProps, defaultProps)
	local tokens = useTokens()

	local variantProps = Vide.derive(function()
		return useRatingVariants(tokens(), Value.read(props.size))
	end)

	local function cursor(): Types.CursorConfig
		local cursorBorderWidth = math.floor(tokens().Stroke.Thicker)
		return {
			radius = UDim.new(0, tokens().Radius.Circle),
			offset = cursorBorderWidth * 2,
			borderWidth = cursorBorderWidth,
		}
	end
	local function contentStyle(): Types.ColorStyleValue
		return variantProps().text.contentStyle
	end
	local function iconSize()
		return variantProps().iconSize
	end
	local function iconVariant(recorded: RatingValue): () -> BuilderIcons.IconVariant
		return function()
			return if Value.read(props.value) == recorded then IconVariant.Filled else IconVariant.Regular
		end
	end

	local thumbUpInstance = Vide.source(nil :: GuiObject?)
	local thumbDownInstance = Vide.source(nil :: GuiObject?)
	local getThumbUp: () -> GuiObject? = thumbUpInstance :: any
	local getThumbDown: () -> GuiObject? = thumbDownInstance :: any

	local function thumbIcon(name: string, recorded: RatingValue, tag: "thumbUpIcon" | "thumbDownIcon", testId: string)
		local icon = Icon({
			name = name,
			variant = iconVariant(recorded),
			size = iconSize,
			style = contentStyle,
			testId = testId,
		})
		icon.Name = "Icon"
		local wrapper = View({
			tag = function()
				return (variantProps() :: any)[tag].tag
			end,
			LayoutOrder = 1,
			children = icon,
		})
		wrapper.Name = "Icon"
		return wrapper
	end

	local label = Text({
		Text = props.text,
		textStyle = contentStyle,
		tag = function()
			return variantProps().text.tag
		end,
		LayoutOrder = 2,
		testId = `{props.testId}--text`,
	})
	label.Name = "Text"

	local thumbUp = View({
		tag = function()
			return variantProps().thumbUpSegment.tag
		end,
		LayoutOrder = 1,
		onActivated = function()
			props.onThumbUp()
		end,
		cursor = cursor,
		selection = {
			Selectable = props.Selectable,
			NextSelectionUp = props.NextSelectionUp,
			NextSelectionDown = props.NextSelectionDown,
			NextSelectionLeft = props.NextSelectionLeft,
			NextSelectionRight = getThumbDown,
		},
		testId = `{props.testId}--thumb-up`,
		children = {
			thumbIcon(IconName.ThumbUp, RatingValue.ThumbUp, "thumbUpIcon", `{props.testId}--thumb-up-icon`),
			label,
		},
	})
	thumbUp.Name = "ThumbUp"
	thumbUpInstance(thumbUp)

	local line = Divider({
		orientation = Orientation.Vertical,
	})
	line.Name = "Line"
	local divider = View({
		tag = function()
			return variantProps().dividerContainer.tag
		end,
		LayoutOrder = 2,
		testId = `{props.testId}--divider`,
		children = line,
	})
	divider.Name = "Divider"

	local thumbDown = View({
		tag = function()
			return variantProps().thumbDownSegment.tag
		end,
		LayoutOrder = 3,
		onActivated = function()
			props.onThumbDown()
		end,
		cursor = cursor,
		selection = {
			Selectable = props.Selectable,
			NextSelectionUp = props.NextSelectionUp,
			NextSelectionDown = props.NextSelectionDown,
			NextSelectionLeft = getThumbUp,
			NextSelectionRight = props.NextSelectionRight,
		},
		testId = `{props.testId}--thumb-down`,
		children = thumbIcon(
			IconName.ThumbDown,
			RatingValue.ThumbDown,
			"thumbDownIcon",
			`{props.testId}--thumb-down-icon`
		),
	})
	thumbDown.Name = "ThumbDown"
	thumbDownInstance(thumbDown)

	return View(withCommonProps(props, {
		tag = function()
			return variantProps().container.tag
		end,
		backgroundStyle = function()
			return variantProps().container.backgroundStyle
		end,
		children = { thumbUp, divider, thumbDown },
	}) :: any)
end

return Rating
