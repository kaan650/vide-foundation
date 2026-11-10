local Constants = require("../../Constants")
local DialogSize = require("../../Enums/DialogSize")
local Types = require("../Types")
type DialogSize = DialogSize.DialogSize
type Value<T> = Types.Value<T>

export type SheetRef = {
	close: () -> (),
}

export type SheetProps = {
	-- Whether the sheet is open, false does not mean the sheet is finished closing, use `onClose` to know when the sheet is closed
	isOpen: Value<boolean?>?,
	-- Receives a handle whose `close` method closes the sheet with its animation.
	sheetRef: ((sheetRef: SheetRef) -> ())?,
	-- Prefer using center sheet over side sheet
	preferCenterSheet: Value<boolean?>?,
	-- The size of the sheet, doesn't apply to bottom sheets
	size: Value<DialogSize?>?,
	-- Callback fired when the sheet is closed
	onClose: () -> (),
	-- Height for center sheets, value should be between 0 and 1 representing the percentage of the screen height or absolute pixel values (e.g. 300) make sure to scale pixel values with `useScaledValue`. If omitted, the center sheet will size to fit its contents.
	centerSheetHeight: Value<number?>?,
	-- List of snap points for bottom sheets, values should be between 0 and 1 representing the percentage of the screen height or absolute pixel values (e.g. 300) make sure to scale pixel values with `useScaledValue`. If omitted, the bottom sheet will size to fit its contents.
	snapPoints: Value<{ number }?>?,
	-- The default snap point index to open the sheet to, defaults to the first snap point
	defaultSnapPointIndex: Value<number?>?,
	-- Callback fired when the bottom sheet changes to a snap point
	onSnapPointChanged: ((snapPoint: number, index: number) -> ())?,
	-- Receives the sheet's surface.
	ref: ((instance: GuiObject) -> ())?,
	testId: string?,
	-- Builds the sheet's parts (Header, Content, Actions, FullBleed), which must be created inside it.
	children: (() -> any)?,
}

return {
	nonSelectable = Constants.MODAL.DISABLE_SELECTION,
	isolatedSelectionGroup = Constants.MODAL.TRAP_FOCUS,
}
