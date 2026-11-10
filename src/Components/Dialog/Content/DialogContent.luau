local Vide = require("../../../Packages/Vide")

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

	--! Roblox measures some layouts inside a ScrollingFrame too short when the dialog sizes this body: a horizontal
	--! list row of auto-sized items (two inputs side by side) counts as 0, and React's dialog cuts the content off.
	--! Reproduced with plain instances and in React Foundation 1.109 (2026-11-10). The canvas height is right, so it
	--! becomes the body's minimum height, capped by the room the dialog has, which keeps scrolling when the content
	--! is taller than the screen.
	local minHeight = Vide.source(0)
	local scrollingFrame: ScrollingFrame? = nil
	local content: GuiObject? = nil

	local function fitToCanvas()
		local body = if content then content.Parent else nil
		local inner = if body then body.Parent else nil
		local container = if inner then inner.Parent else nil
		local frame = scrollingFrame
		if
			not content
			or not frame
			or not (inner and inner:IsA("GuiObject"))
			or not (container and container:IsA("GuiObject"))
		then
			return
		end
		local others = inner.AbsoluteSize.Y - content.AbsoluteSize.Y
		local room = container.AbsoluteSize.Y - others
		minHeight(math.max(0, math.min(frame.AbsoluteCanvasSize.Y, room)))
	end

	local function onScrollSizeChanged(frame: ScrollingFrame)
		scrollingFrame = frame
		updateScrollBarPadding(frame)
		fitToCanvas()
	end

	local view = ScrollView(withCommonProps(commonProps, {
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
		sizeConstraint = {
			MinSize = function()
				return Vector2.new(0, minHeight())
			end,
		},
		onAbsoluteCanvasSizeChanged = onScrollSizeChanged,
		onAbsoluteWindowSizeChanged = updateScrollBarPadding,
		tag = function()
			return variants().content.tag
		end,
		children = { scrollPadding, props.children },
	}) :: any)
	content = view

	-- The room changes with the screen, which the body's own events don't report
	local containerConnection: RBXScriptConnection? = nil
	local function watchContainer()
		if containerConnection then
			containerConnection:Disconnect()
			containerConnection = nil
		end
		local body = view.Parent
		local inner = if body then body.Parent else nil
		local container = if inner then inner.Parent else nil
		if container and container:IsA("GuiObject") then
			containerConnection = container:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitToCanvas)
			fitToCanvas()
		end
	end
	local ancestryConnection = view.AncestryChanged:Connect(watchContainer)
	Vide.cleanup(function()
		ancestryConnection:Disconnect()
		if containerConnection then
			containerConnection:Disconnect()
		end
	end)

	return view
end

return DialogContent
