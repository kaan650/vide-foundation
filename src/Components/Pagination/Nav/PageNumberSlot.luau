local Vide = require("../../../Packages/Vide")

local ChipSize = require("../../../Enums/ChipSize")
local ChipVariant = require("../../../Enums/ChipVariant")
local ColorNamespace = require("../../../Enums/ColorNamespace")
local PaginationSize = require("../../../Enums/PaginationSize")
local PresentationContext = require("../../../Providers/Style/PresentationContext")
local Text = require("../../Text")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local named = require("../../../Utility/named")
local paginationUtils = require("../paginationUtils")
local rebuildOn = require("../../../Utility/rebuildOn")
local useChipVariants = require("../../Chip/useChipVariants")
local useTokens = require("../../../Providers/Style/useTokens")

type ChipSize = ChipSize.ChipSize
type ChipVariantProps = useChipVariants.ChipVariantProps
type PaginationSize = PaginationSize.PaginationSize
type Value<T> = Types.Value<T>

type PageNumberSlotProps = {
	slotSize: () -> PaginationSize,
	isChecked: () -> boolean,
	LayoutOrder: Value<number>,
	onPageActivated: (page: number) -> (),
	page: number,
	testId: string,
	-- Receives each instance the slot builds.
	ref: (instance: GuiObject) -> (),
} & Types.SelectionProps

local ICON_PRESENTATION: PresentationContext.PresentationContextValue = {
	colorNamespace = ColorNamespace.Color,
	isIconSize = true,
}

local WIDE_SLOT_SIZE_TAG: { [PaginationSize]: string } = {
	[PaginationSize.Small] = "size-0-600",
	[PaginationSize.Medium] = "size-0-800",
}

--- One page number. Pages up to 999 are circles whose checked background is the pagination's sliding highlight;
--- wider pages draw their own chip background. Returns a source of the instance: the slot is a button only while it
--- is not the current page, so it is rebuilt when that changes.
local function PageNumberSlot(props: PageNumberSlotProps): () -> GuiObject
	local tokens = useTokens()
	local needsWideSlot = paginationUtils.needsWidePageSlot(props.page)

	local function variantProps(isChecked: boolean): () -> ChipVariantProps
		return Vide.derive(function()
			local chipSize: ChipSize = if props.slotSize() == PaginationSize.Small then ChipSize.Small else ChipSize.Medium
			return useChipVariants(tokens(), chipSize, ChipVariant.Utility, isChecked, false, false)
		end)
	end

	local function onActivated()
		props.onPageActivated(props.page)
	end

	local function cursor(): Types.Cursor?
		return paginationUtils.getSlotCursor(tokens())
	end

	local function pageNumberText(
		textStyle: Types.ColorStyle,
		textTag: () -> string,
		padding: Types.Padding?
	): GuiObject
		return named(
			"Text",
			Text({
				Text = tostring(props.page),
				textStyle = textStyle,
				tag = textTag,
				padding = padding,
				LayoutOrder = 1,
				testId = `{props.testId}--text`,
			})
		)
	end

	local function build(isChecked: boolean): GuiObject
		local isInteractive = not isChecked
		local selection: Types.Selection = if isInteractive
			then {
				Selectable = function()
					return Value.read(props.Selectable) ~= false
				end,
				NextSelectionLeft = props.NextSelectionLeft,
				NextSelectionRight = props.NextSelectionRight,
				NextSelectionUp = props.NextSelectionUp,
				NextSelectionDown = props.NextSelectionDown,
			}
			else { Selectable = false }

		local instance: GuiObject
		if needsWideSlot then
			local chipVariant = variantProps(isChecked)
			local function label(): GuiObject
				return pageNumberText(function()
					return chipVariant().text.contentStyle
				end, function()
					return chipVariant().text.tag
				end, {
					left = function()
						return chipVariant().text.padding.left or UDim.new()
					end,
					right = function()
						return chipVariant().text.padding.right or UDim.new()
					end,
				})
			end

			instance = View({
				LayoutOrder = props.LayoutOrder,
				testId = props.testId,
				backgroundStyle = function()
					return chipVariant().chip.backgroundStyle
				end,
				cursor = if isInteractive then cursor else nil,
				onActivated = if isInteractive then onActivated else nil,
				selection = selection,
				tag = function()
					return `row align-x-center align-y-center auto-x radius-circle {WIDE_SLOT_SIZE_TAG[props.slotSize()]}`
				end,
				children = if isInteractive then PresentationContext.context(ICON_PRESENTATION, label) else label(),
			})
		else
			local checkedVariant = if isChecked then variantProps(true) else nil
			instance = View({
				LayoutOrder = props.LayoutOrder,
				testId = props.testId,
				backgroundStyle = function(): Types.ColorStyleValue
					return {
						Color3 = tokens().Color.Surface.Surface_0.Color3,
						Transparency = 1,
					}
				end,
				cursor = if isInteractive then cursor else nil,
				onActivated = if isInteractive then onActivated else nil,
				selection = selection,
				tag = function()
					return paginationUtils.getCircularSlotTag(props.slotSize())
				end,
				children = pageNumberText(function(): Types.ColorStyleValue
					return if checkedVariant then checkedVariant().text.contentStyle else tokens().Color.Content.Default :: any
				end, function()
					return paginationUtils.getPageLabelTextTag(props.slotSize())
				end, nil),
			})
		end

		props.ref(instance)
		return instance
	end

	return rebuildOn<<boolean>>(props.isChecked, build) :: () -> GuiObject
end

return PageNumberSlot
