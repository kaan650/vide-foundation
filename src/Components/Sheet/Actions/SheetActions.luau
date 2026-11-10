local Vide = require("../../../Packages/Vide")

local SheetContext = require("../SheetContext")
local SheetType = require("../SheetType")
local StateLayerAffordance = require("../../../Enums/StateLayerAffordance")
local Types = require("../../Types")
local View = require("../../View")
local useTokens = require("../../../Providers/Style/useTokens")

export type SheetActionsProps = {
	-- Receives the actions bar.
	ref: ((instance: GuiObject) -> ())?,
	children: Types.Children?,
}

local function noop() end

--- The sheet's button bar. On bottom sheets it is pinned to the bottom of the screen, outside the scrolling sheet,
--- and returns nil; elsewhere it is returned in place.
local function SheetActions(props: SheetActionsProps): GuiObject?
	local tokens = useTokens()
	local sheet = SheetContext()
	local testId = sheet.testId
	assert(testId, "SheetActions must be used within a Sheet")

	local isBottomSheet = sheet.sheetType == SheetType.Bottom
	local bottomPadding = sheet.bottomPadding

	local actions = View({
		tag = {
			["row gap-small size-full-0 auto-y"] = true,
			["bg-surface-100"] = isBottomSheet,
		},
		padding = {
			top = function()
				return UDim.new(0, tokens().Margin.Small)
			end,
			left = function()
				return UDim.new(0, tokens().Margin.Small)
			end,
			right = function()
				return UDim.new(0, tokens().Margin.Small)
			end,
			bottom = function()
				return UDim.new(0, bottomPadding + tokens().Margin.Small)
			end,
		},
		stroke = {
			Color = function()
				return tokens().Color.Stroke.Default.Color3
			end,
			Transparency = function()
				return tokens().Color.Stroke.Default.Transparency
			end,
			Thickness = function()
				return if sheet.hasActionsDivider() then tokens().Stroke.Standard else 0
			end,
		},
		onAbsoluteSizeChanged = if isBottomSheet
			then function(instance: GuiObject)
				sheet.setActionsHeight(instance.AbsoluteSize.Y - bottomPadding)
			end
			else nil,
		ZIndex = 1,
		testId = `{testId}--actions`,
		Position = if isBottomSheet
			then function()
				return UDim2.new(0, 0, 1, -math.min(sheet.sheetHeightAvailable(), sheet.actionsHeight()))
			end
			else nil,
		LayoutOrder = 3,
		--* Keeps presses from going through the actions bar.
		onActivated = noop,
		selection = {
			Selectable = false,
		},
		stateLayer = {
			affordance = StateLayerAffordance.None,
		},
		children = props.children,
	})
	if props.ref then
		props.ref(actions)
	end

	if not isBottomSheet then
		return actions
	end

	--* Not returned, so the caller cannot name it; React names it after its key, usually "Actions".
	actions.Name = "Actions"
	Vide.effect(function()
		actions.Parent = sheet.innerSurface()
	end)
	Vide.cleanup(actions)
	return nil
end

return SheetActions
