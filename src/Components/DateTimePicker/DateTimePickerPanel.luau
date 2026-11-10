local Vide = require("../../Packages/Vide")

local Button = require("../Button")
local ButtonVariant = require("../../Enums/ButtonVariant")
local DateTimeCalendarConstants = require("./Utilities/DateTimeCalendarConstants")
local DateTimeLayoutUtilities = require("./Utilities/DateTimeLayoutUtilities")
local Divider = require("../Divider")
local Translator = require("../../Utility/Localization/Translator")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local useScaledValue = require("../../Utility/useScaledValue")
local useTokens = require("../../Providers/Style/useTokens")

export type SectionedLayout = "dual" | "singleWithTime"

export type DateTimePickerPanelProps = {
	children: Types.Children,
	isApplyButtonDisabled: () -> boolean,
	isResetButtonDisabled: () -> boolean,
	isSectioned: () -> boolean,
	onApply: () -> (),
	onCancel: () -> (),
	onReset: () -> (),
	sectionedLayout: () -> SectionedLayout?,
	showReset: () -> boolean,
	testId: string?,
}

--- The open picker's surface: the calendar content above Apply and Cancel, and Reset in the sectioned variants.
local function DateTimePickerPanel(props: DateTimePickerPanelProps): GuiObject
	local tokens = useTokens()
	local scaledPaneWidth = useScaledValue(DateTimeLayoutUtilities.PANE_WIDTH)
	local scaledCalendarWidth = useScaledValue(DateTimeLayoutUtilities.CALENDAR_WIDTH)
	local scaledTimeListWidth = useScaledValue(DateTimeLayoutUtilities.TIME_LIST_WIDTH)

	local function applyButton(): GuiObject
		local button = Button({
			isDisabled = props.isApplyButtonDisabled,
			LayoutOrder = 2,
			onActivated = props.onApply,
			testId = `{props.testId}--apply-button`,
			text = Translator:FormatByKey("CommonUI.Controls.Action.Apply"),
			variant = ButtonVariant.Emphasis,
		})
		button.Name = "ApplyButton"
		return button
	end

	local function cancelButton(): GuiObject
		local button = Button({
			LayoutOrder = 3,
			onActivated = props.onCancel,
			testId = `{props.testId}--cancel-button`,
			text = Translator:FormatByKey("CommonUI.Controls.Action.Cancel"),
			variant = ButtonVariant.Standard,
		})
		button.Name = "CancelButton"
		return button
	end

	local function actionsPadding(): string
		return if props.isSectioned() then "padding-x-large padding-y-large" else "padding-top-large"
	end

	local actionBar = rebuildOn(props.showReset, function(showReset: boolean): GuiObject
		if showReset then
			local resetButton = Button({
				isDisabled = props.isResetButtonDisabled,
				LayoutOrder = 1,
				onActivated = props.onReset,
				testId = `{props.testId}--reset-button`,
				text = Translator:FormatByKey("CommonUI.Controls.Action.ResetAll"),
				variant = ButtonVariant.Utility,
			})
			resetButton.Name = "ResetButton"

			local primaryActions = View({
				LayoutOrder = 2,
				tag = "row align-x-right grow gap-small auto-y",
				children = { applyButton(), cancelButton() },
			})
			primaryActions.Name = "PrimaryActions"

			return View({
				LayoutOrder = 3,
				tag = function()
					return `row align-y-center gap-small size-full-0 auto-y {actionsPadding()}`
				end,
				children = { resetButton, primaryActions },
			})
		end
		return View({
			LayoutOrder = 3,
			tag = function()
				return `row flex-fill gap-small size-full-0 auto-y {actionsPadding()}`
			end,
			children = { applyButton(), cancelButton() },
		})
	end)

	local function panelWidth(): number?
		local layout = props.sectionedLayout()
		if layout == "dual" then
			return 2 * scaledPaneWidth() + 3 * tokens().Padding.Large
		elseif layout == "singleWithTime" then
			return DateTimeLayoutUtilities.computeSingleWithTimeLayout(
				scaledCalendarWidth(),
				scaledTimeListWidth(),
				tokens(),
				DateTimeCalendarConstants.NUM_CALENDAR_GRID_ROWS
			).contentWidth
		end
		return nil
	end

	local function isSizedSection(): boolean
		return props.isSectioned() and props.sectionedLayout() ~= nil
	end

	local actionsDivider = Vide.show(props.isSectioned, function()
		local divider = Divider({
			LayoutOrder = 2,
		})
		divider.Name = "ActionsDivider"
		return divider
	end)

	return View({
		tag = function()
			local sectioned = props.isSectioned()
			local sized = isSizedSection()
			return {
				["col"] = true,
				["bg-surface-200"] = true,
				["stroke-default"] = true,
				["radius-large"] = true,
				["auto-y"] = sized,
				["auto-xy"] = not sized,
				["clip"] = sectioned,
				["padding-large"] = not sectioned,
			}
		end,
		children = {
			Value.bindProperty("Size", function(): UDim2?
				local width = panelWidth()
				return if width then UDim2.fromOffset(width, 0) else nil
			end),
			named("Content", props.children),
			actionsDivider,
			named("Actions", actionBar),
		},
	})
end

return DateTimePickerPanel
