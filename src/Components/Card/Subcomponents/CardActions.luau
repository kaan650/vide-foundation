local BuilderIcons = require("../../../Packages/BuilderIcons")

local ButtonVariant = require("../../../Enums/ButtonVariant")
local InputSize = require("../../../Enums/InputSize")

local IconButton = require("../../IconButton")
local View = require("../../View")
local named = require("../../../Utility/named")
local useCardVariants = require("../useCardVariants")

type InputSize = InputSize.InputSize
type CardVariantProps = useCardVariants.CardVariantProps

local IconName = BuilderIcons.Icon
local ACTION_SIZE: InputSize = InputSize.Small

type CardActionsProps = {
	testId: string,
	variantProps: () -> CardVariantProps,
	onOverflow: (() -> ())?,
	onClose: (() -> ())?,
	overflowRef: ((GuiObject) -> ())?,
	isOverMedia: () -> boolean,
	isInline: boolean,
}

--- The card's overflow and close buttons: in the header row, or pinned to the card's top right corner.
local function CardActions(props: CardActionsProps): GuiObject
	local function variant()
		return if props.isOverMedia() then ButtonVariant.OverMedia else ButtonVariant.Utility
	end

	local overflow: any = nil
	local onOverflow = props.onOverflow
	if onOverflow then
		overflow = named(
			"Overflow",
			IconButton({
				onActivated = onOverflow,
				icon = IconName.ThreeDotsHorizontal,
				variant = variant,
				size = ACTION_SIZE,
				isCircular = true,
				LayoutOrder = 1,
				testId = `{props.testId}--overflow`,
			})
		)
		if props.overflowRef and typeof(overflow) == "Instance" then
			props.overflowRef(overflow :: GuiObject)
		end
	end

	local close: any = nil
	local onClose = props.onClose
	if onClose then
		close = named(
			"Close",
			IconButton({
				onActivated = onClose,
				icon = IconName.X,
				variant = variant,
				size = ACTION_SIZE,
				isCircular = true,
				LayoutOrder = 2,
				testId = `{props.testId}--close`,
			})
		)
	end

	return View({
		tag = function()
			return props.variantProps().actions.tag
		end,
		AnchorPoint = if props.isInline then nil else Vector2.new(1, 0),
		Position = if props.isInline then nil else UDim2.fromScale(1, 0),
		LayoutOrder = if props.isInline then 2 else nil,
		ZIndex = 2,
		testId = `{props.testId}--actions`,
		children = { overflow, close },
	})
end

return CardActions
