local Vide = require("../../Packages/Vide")

local SheetType = require("./SheetType")
local Types = require("../Types")
type SheetType = SheetType.SheetType
type Value<T> = Types.Value<T>

export type SheetContextValue = {
	sheetHeightAvailable: () -> number,
	actionsHeight: () -> number,
	setActionsHeight: (height: number) -> (),
	hasActionsDivider: () -> boolean,
	setHasActionsDivider: (hasDivider: boolean) -> (),
	-- Only center sheets give their content a height; nil elsewhere.
	sheetContentHeight: (() -> number?)?,
	safeAreaPadding: () -> number,
	bottomPadding: number,
	innerScrollingEnabled: () -> boolean,
	innerScrollY: () -> number,
	setInnerScrollingFrame: (frame: ScrollingFrame?) -> (),
	setInnerScrollY: (scrollY: number) -> (),
	hasHeader: () -> boolean,
	setHasHeader: (hasHeader: boolean) -> (),
	--* Foundation finds Sheet.FullBleed among the children before rendering; here the FullBleed reports itself.
	hasFullBleed: () -> boolean,
	setHasFullBleed: (hasFullBleed: boolean) -> (),
	fullBleedHeight: () -> number,
	setFullBleedHeight: (height: number) -> (),
	hasRadius: () -> boolean,
	closeSheet: () -> (),
	sheetType: SheetType?,
	innerSurface: () -> GuiObject?,
	-- Nil outside a sheet.
	testId: string?,
	closeAffordanceRef: () -> GuiObject?,
	setCloseAffordanceRef: (instance: GuiObject?) -> (),
	contentStartRef: () -> GuiObject?,
	setContentStartRef: (ref: Value<GuiObject?>) -> (),
	isVerticalSheetGesture: () -> boolean,
}

local function zero(): number
	return 0
end

local function no(): boolean
	return false
end

local function none(): any
	return nil
end

local function noop(_: any) end

return Vide.context({
	sheetHeightAvailable = zero,
	actionsHeight = zero,
	setActionsHeight = noop,
	hasActionsDivider = no,
	setHasActionsDivider = noop,
	sheetContentHeight = nil,
	safeAreaPadding = zero,
	bottomPadding = 0,
	innerScrollingEnabled = no,
	innerScrollY = zero,
	setInnerScrollingFrame = noop,
	setInnerScrollY = noop,
	hasHeader = no,
	setHasHeader = noop,
	hasFullBleed = no,
	setHasFullBleed = noop,
	fullBleedHeight = zero,
	setFullBleedHeight = noop,
	hasRadius = function()
		return true
	end,
	closeSheet = function() end,
	sheetType = nil,
	innerSurface = none,
	testId = nil,
	closeAffordanceRef = none,
	setCloseAffordanceRef = noop,
	contentStartRef = none,
	setContentStartRef = noop,
	isVerticalSheetGesture = no,
} :: SheetContextValue)
