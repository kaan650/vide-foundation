local Vide = require("../../../Packages/Vide")

local CloseAffordance = require("../../CloseAffordance")
local CloseAffordanceVariant = require("../../../Enums/CloseAffordanceVariant")
local SheetContext = require("../SheetContext")
local SheetType = require("../SheetType")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local useTokens = require("../../../Providers/Style/useTokens")

type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

export type SheetHeaderProps = {
	-- Defaults to true, except on bottom sheets.
	hasCloseAffordance: Value<boolean?>?,
	-- Receives the header instance.
	ref: ((instance: GuiObject) -> ())?,
	children: Types.Children?,
}

--- The sheet's title row, with a close button and a divider that fades in as the content scrolls.
local function SheetHeader(props: SheetHeaderProps): GuiObject
	local tokens = useTokens()
	local sheet = SheetContext()
	local testId = sheet.testId
	assert(testId, "SheetHeader must be used within a Sheet")

	local isBottomSheet = sheet.sheetType == SheetType.Bottom

	sheet.setHasHeader(true)
	Vide.cleanup(function()
		sheet.setHasHeader(false)
	end)

	local subContent = View({
		LayoutOrder = 1,
		tag = "row items-center shrink gap-small size-full-0 auto-y",
		children = props.children,
	})
	subContent.Name = "SubContent"

	local content = View({
		LayoutOrder = 1,
		tag = "row align-y-center items-center gap-small size-full-1400 auto-y margin-left-small padding-y-small padding-right-medium",
		children = {
			subContent,
			Vide.show(function()
				local hasCloseAffordance = Value.read(props.hasCloseAffordance)
				return if hasCloseAffordance == nil then not isBottomSheet else hasCloseAffordance
			end, function()
				local closeAffordance = CloseAffordance({
					onActivated = sheet.closeSheet,
					NextSelectionDown = sheet.contentStartRef,
					variant = function()
						return if sheet.hasFullBleed()
							then CloseAffordanceVariant.OverMedia
							else CloseAffordanceVariant.Utility
					end,
					LayoutOrder = 2,
					testId = `{testId}--header--close-affordance`,
				}) :: GuiObject
				closeAffordance.Name = "CloseAffordance"
				sheet.setCloseAffordanceRef(closeAffordance)
				return closeAffordance
			end),
		},
	})
	content.Name = "Content"

	local bottomBorder = View({
		LayoutOrder = 2,
		backgroundStyle = function(): ColorStyleValue
			local current = tokens()
			local stroke = current.Color.Stroke.Default
			return {
				Color3 = stroke.Color3,
				Transparency = math.lerp(
					1,
					stroke.Transparency,
					math.clamp(sheet.innerScrollY() / current.Size.Size_1200, 0, 1)
				),
			}
		end,
		testId = `{testId}--header--bottom-border`,
		Size = function()
			return UDim2.new(1, 0, 0, tokens().Stroke.Standard)
		end,
	})
	bottomBorder.Name = "BottomBorder"

	local header = View({
		ZIndex = 2,
		tag = "col size-full-0 auto-y",
		testId = `{testId}--header`,
		children = { content, bottomBorder },
	})
	if props.ref then
		props.ref(header)
	end
	return header
end

return SheetHeader
