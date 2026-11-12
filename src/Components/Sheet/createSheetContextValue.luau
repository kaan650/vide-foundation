local Vide = require("../../Packages/Vide")

local SheetContext = require("./SheetContext")
local SheetType = require("./SheetType")
local Types = require("../Types")
local Value = require("../../Utility/Value")
type SheetContextValue = SheetContext.SheetContextValue
type SheetType = SheetType.SheetType
type Value<T> = Types.Value<T>

local function zero(): number
	return 0
end

local function yes(): boolean
	return true
end

local function noop(_: any) end

--- The context state every sheet type keeps: header, full bleed, divider, inner scroll and navigation. Fields that
--- only the bottom sheet drives (heights, inner scrolling) start as the constants center and side sheets use.
local function createSheetContextValue(sheetType: SheetType, testId: string, closeSheet: () -> ()): SheetContextValue
	local hasActionsDivider = Vide.source(false)
	local hasHeader = Vide.source(false)
	local hasFullBleed = Vide.source(false)
	local fullBleedHeight = Vide.source(0)
	local innerScrollY = Vide.source(0)
	local closeAffordance = Vide.source(nil :: GuiObject?)
	local contentStart = Vide.source(nil :: Value<GuiObject?>?)
	local getCloseAffordance: () -> GuiObject? = closeAffordance :: any
	local getContentStart: () -> Value<GuiObject?>? = contentStart :: any

	return {
		sheetHeightAvailable = zero,
		actionsHeight = zero,
		setActionsHeight = noop,
		hasActionsDivider = function()
			return hasActionsDivider()
		end,
		setHasActionsDivider = function(value: boolean)
			hasActionsDivider(value)
		end,
		sheetContentHeight = nil,
		safeAreaPadding = zero,
		bottomPadding = 0,
		innerScrollingEnabled = yes,
		innerScrollY = function()
			return innerScrollY()
		end,
		setInnerScrollingFrame = noop,
		setInnerScrollY = function(value: number)
			innerScrollY(value)
		end,
		hasHeader = function()
			return hasHeader()
		end,
		setHasHeader = function(value: boolean)
			hasHeader(value)
		end,
		hasFullBleed = function()
			return hasFullBleed()
		end,
		setHasFullBleed = function(value: boolean)
			hasFullBleed(value)
		end,
		fullBleedHeight = function()
			return fullBleedHeight()
		end,
		setFullBleedHeight = function(value: number)
			fullBleedHeight(value)
		end,
		hasRadius = yes,
		closeSheet = closeSheet,
		sheetType = sheetType,
		innerSurface = function(): GuiObject?
			return nil
		end,
		testId = testId,
		closeAffordanceRef = getCloseAffordance,
		setCloseAffordanceRef = function(instance: GuiObject?)
			closeAffordance(instance)
		end,
		contentStartRef = function(): GuiObject?
			return Value.read(getContentStart())
		end,
		setContentStartRef = function(ref: Value<GuiObject?>)
			contentStart(ref)
		end,
		isVerticalSheetGesture = function()
			return false
		end,
		contentRevealOffset = function(): number?
			return nil
		end,
		setIsContentReversed = noop,
	}
end

return createSheetContextValue
