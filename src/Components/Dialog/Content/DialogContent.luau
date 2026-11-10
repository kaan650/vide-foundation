local ScrollView = require("../../ScrollView")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local Visibility = require("../../../Enums/Visibility")
local create = require("../../../Utility/create")
local useDialog = require("../useDialog")
local useDialogVariants = require("../useDialogVariants").useDialogVariants
local useScrollBarPadding = require("./useScrollBarPadding")
local withCommonProps = require("../../../Utility/withCommonProps")

export type DialogContentProps = {
	children: Types.Children?,
} & Types.CommonProps & Types.SelectionProps

--- The dialog's scrolling body. Its scroll bar shows only when the content overflows.
local function DialogContent(props: DialogContentProps): GuiObject
	local hasOverflowY, scrollBarPadding, updateScrollBarPadding = useScrollBarPadding()
	local variants = useDialogVariants()
	local dialogContext = useDialog()

	local commonProps = table.clone(props)
	commonProps.testId = `{dialogContext.testId}--content`

	local scrollPadding = create("UIPadding")({
		Name = "ScrollPadding",
		PaddingRight = function()
			return UDim.new(0, scrollBarPadding())
		end,
	})

	return ScrollView(withCommonProps(commonProps, {
		scroll = {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			scrollBarVisibility = function()
				return if hasOverflowY() then Visibility.Auto else Visibility.None
			end,
		},
		layout = {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		selection = {
			Selectable = function()
				return Value.read(props.Selectable) ~= false and hasOverflowY()
			end,
			NextSelectionUp = props.NextSelectionUp,
			NextSelectionDown = props.NextSelectionDown,
			NextSelectionLeft = props.NextSelectionLeft,
			NextSelectionRight = props.NextSelectionRight,
		},
		onAbsoluteCanvasSizeChanged = updateScrollBarPadding,
		onAbsoluteWindowSizeChanged = updateScrollBarPadding,
		tag = function()
			return variants().content.tag
		end,
		children = { scrollPadding, props.children },
	}) :: any)
end

return DialogContent
