local BuilderIcons = require("../../../Packages/BuilderIcons")

local ButtonVariant = require("../../../Enums/ButtonVariant")
local IconButton = require("../../IconButton")
local InputSize = require("../../../Enums/InputSize")
local PaginationDirection = require("../../../Enums/PaginationDirection")
local PaginationSize = require("../../../Enums/PaginationSize")
local Types = require("../../Types")

type InputSize = InputSize.InputSize
type PaginationDirection = PaginationDirection.PaginationDirection
type PaginationSize = PaginationSize.PaginationSize
type Value<T> = Types.Value<T>

local IconName = BuilderIcons.Icon

type DirectionConfig = {
	icon: string,
	testIdSuffix: string,
}

local DIRECTION_CONFIG: { [PaginationDirection]: DirectionConfig } = {
	[PaginationDirection.First] = {
		icon = IconName.ChevronSmallLeftToLine,
		testIdSuffix = "first",
	},
	[PaginationDirection.Backward] = {
		icon = IconName.ChevronSmallLeft,
		testIdSuffix = "back",
	},
	[PaginationDirection.Forward] = {
		icon = IconName.ChevronSmallRight,
		testIdSuffix = "forward",
	},
	[PaginationDirection.Last] = {
		icon = IconName.ChevronSmallRightToLine,
		testIdSuffix = "last",
	},
}

local function getInputSize(slotSize: PaginationSize): InputSize
	return if slotSize == PaginationSize.Small then InputSize.XSmall else InputSize.Small
end

type NavButtonProps = {
	baseTestId: string,
	slotSize: () -> PaginationSize,
	direction: PaginationDirection,
	isDisabled: () -> boolean,
	LayoutOrder: Value<number>,
	onDirectionActivated: (direction: PaginationDirection) -> (),
} & Types.SelectionProps

--- A circular chevron button that moves the pagination in one direction. Returns a source of the instance, since a
--- disabled IconButton is rebuilt as a CanvasGroup.
local function NavButton(props: NavButtonProps): GuiObject | () -> GuiObject
	local directionConfig = DIRECTION_CONFIG[props.direction]

	return IconButton({
		LayoutOrder = props.LayoutOrder,
		testId = `{props.baseTestId}--{directionConfig.testIdSuffix}`,
		icon = directionConfig.icon,
		size = function()
			return getInputSize(props.slotSize())
		end,
		variant = ButtonVariant.Utility,
		isCircular = true,
		isDisabled = props.isDisabled,
		onActivated = function()
			props.onDirectionActivated(props.direction)
		end,
		Selectable = props.Selectable,
		NextSelectionLeft = props.NextSelectionLeft,
		NextSelectionRight = props.NextSelectionRight,
		NextSelectionUp = props.NextSelectionUp,
		NextSelectionDown = props.NextSelectionDown,
	})
end

return NavButton
