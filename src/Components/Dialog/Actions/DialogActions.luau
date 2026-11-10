local Vide = require("../../../Packages/Vide")

local ButtonGroup = require("../../ButtonGroup")
local ButtonVariant = require("../../../Enums/ButtonVariant")
local DialogSize = require("../../../Enums/DialogSize")
local FillBehavior = require("../../../Enums/FillBehavior")
local Orientation = require("../../../Enums/Orientation")
local Text = require("../../Text")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local useDialog = require("../useDialog")
local useDialogVariants = require("../useDialogVariants").useDialogVariants
local withDefaults = require("../../../Utility/withDefaults")

type ButtonVariant = ButtonVariant.SupportedButtonVariant
type Orientation = Orientation.Orientation
type Value<T> = Types.Value<T>

export type DialogAction = {
	variant: Value<ButtonVariant>?,
	icon: Value<string?>?,
	text: Value<string?>?,
	onActivated: () -> (),
	inputDelay: Value<number>?,
	-- Receives the button instance.
	ref: ((GuiObject) -> ())?,
}

export type DialogActionsProps = {
	actions: Value<{ DialogAction }?>?,
	label: Value<string?>?,
	-- Vertical stacks the buttons, on small dialogs only.
	orientation: Value<Orientation>?,
	LayoutOrder: Value<number>?,
}

local defaultProps = {
	orientation = Orientation.Horizontal,
}

--- The dialog's buttons, with an optional note below them.
local function DialogActions(dialogActionsProps: DialogActionsProps): GuiObject
	local props = withDefaults(dialogActionsProps, defaultProps)
	local variants = useDialogVariants()
	local dialogContext = useDialog()
	local testId = dialogContext.testId

	local function isVertical(): boolean
		return Value.read(props.orientation) == Orientation.Vertical
			and dialogContext.responsiveSize() == DialogSize.Small
	end

	local actions = props.actions
	local buttons: Value<{ DialogAction }>
	if type(actions) == "function" then
		local getActions: () -> { DialogAction }? = actions :: any
		buttons = function(): { DialogAction }
			return getActions() or {}
		end
	else
		buttons = (actions or {}) :: { DialogAction }
	end

	local actionsContainer = ButtonGroup({
		buttons = buttons :: any,
		orientation = function()
			return if isVertical() then Orientation.Vertical else Orientation.Horizontal
		end,
		fillBehavior = FillBehavior.Fill,
		LayoutOrder = 1,
		testId = `{testId}--actions-container`,
	})
	actionsContainer.Name = "ActionsContainer"

	return View({
		tag = "col size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		testId = `{testId}--actions`,
		children = {
			actionsContainer,
			Vide.show(function()
				return Value.read(props.label)
			end, function(label: () -> string)
				local text = Text({
					Text = label,
					tag = function()
						return variants().actionsLabel.tag
					end,
					LayoutOrder = 2,
					testId = `{testId}--actions-label`,
				})
				text.Name = "ActionsLabel"
				return text
			end),
		},
	})
end

return DialogActions
