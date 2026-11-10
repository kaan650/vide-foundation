local Vide = require("../../Packages/Vide")

local Button = require("../Button")
local ButtonVariant = require("../../Enums/ButtonVariant")
local FillBehavior = require("../../Enums/FillBehavior")
local InputSize = require("../../Enums/InputSize")
local Orientation = require("../../Enums/Orientation")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local devAssert = require("../../Utility/devAssert")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ButtonVariant = ButtonVariant.SupportedButtonVariant
type FillBehavior = FillBehavior.FillBehavior
type Orientation = Orientation.Orientation
type Value<T> = Types.Value<T>

-- InputSize.Large is not supported by ButtonGroup.
export type ButtonGroupSize = typeof(InputSize.XSmall) | typeof(InputSize.Small) | typeof(InputSize.Medium)

export type ButtonGroupItem = {
	text: Value<string?>?,
	onActivated: () -> (),
	variant: Value<ButtonVariant>?,
	isDisabled: Value<boolean>?,
	isLoading: Value<boolean>?,
	icon: Value<string?>?,
	inputDelay: Value<number>?,
	-- Receives the button instance.
	ref: ((GuiObject) -> ())?,
	testId: string?,
}

export type ButtonGroupProps = {
	-- The buttons to render in the group.
	buttons: Value<{ ButtonGroupItem }>,
	-- Maximum number of buttons accepted by the group.
	maxButtonCount: Value<number>?,
	-- Horizontal = side-by-side row (default).
	-- Vertical   = stacked column, buttons always fill full width.
	orientation: Value<Orientation>?,
	-- Only applies to Horizontal orientation. Vertical always forces fill.
	fillBehavior: Value<FillBehavior?>?,
	-- Applies to all buttons in the group; individual items cannot override this.
	size: Value<ButtonGroupSize>?,
} & Types.CommonProps

local defaultProps = {
	maxButtonCount = 3,
	orientation = Orientation.Horizontal,
	size = InputSize.Medium,
	testId = "--foundation-button-group",
}

--- A row or column of Buttons sharing one size.
local function ButtonGroup(buttonGroupProps: ButtonGroupProps): GuiObject
	local props = withDefaults(buttonGroupProps, defaultProps)
	local testId = props.testId

	local function isVertical(): boolean
		return Value.read(props.orientation) == Orientation.Vertical
	end
	local function isFill(): boolean
		return isVertical() or Value.read(props.fillBehavior) == FillBehavior.Fill
	end

	Vide.effect(function()
		local count = #Value.read(props.buttons)
		local maxButtonCount: number = Value.read(props.maxButtonCount)
		devAssert(count <= maxButtonCount, `ButtonGroup: a maximum of {maxButtonCount} buttons is supported, got {count}.`)
	end)

	--* Vertical groups stretch buttons with the container's flex-x-fill, so only horizontal fill uses the buttons' UIFlexItem.
	local function buttonFillBehavior(): FillBehavior?
		return if not isVertical() and isFill() then FillBehavior.Fill else nil
	end
	local isLayoutStatic = type(props.orientation) ~= "function" and type(props.fillBehavior) ~= "function"

	local function groupButton(item: ButtonGroupItem, index: number): GuiObject
		local button = Button({
			text = item.text,
			onActivated = item.onActivated,
			variant = item.variant,
			isDisabled = item.isDisabled,
			isLoading = item.isLoading,
			icon = item.icon,
			inputDelay = item.inputDelay,
			size = props.size,
			fillBehavior = if isLayoutStatic then buttonFillBehavior() else buttonFillBehavior,
			LayoutOrder = index,
			testId = item.testId or `{testId}--button-{index}`,
		})
		if item.ref then
			item.ref(button)
		end
		return button
	end

	local buttons = props.buttons
	local children
	if type(buttons) == "function" then
		children = Vide.indexes(buttons, function(item: () -> ButtonGroupItem, index: number)
			local function field(key: string): () -> any
				return function()
					return Value.read((item() :: any)[key])
				end
			end
			local initial = Vide.untrack(item)
			local button = groupButton({
				text = field("text"),
				onActivated = function()
					item().onActivated()
				end,
				variant = field("variant"),
				isDisabled = field("isDisabled"),
				isLoading = field("isLoading"),
				icon = field("icon"),
				inputDelay = field("inputDelay"),
				ref = initial.ref,
				testId = initial.testId,
			}, index)
			Vide.effect(function()
				button.Name = `{index}-{Value.read(item().text)}`
			end)
			return button
		end)
	else
		children = {}
		for index, item in buttons do
			local button = groupButton(item, index)
			button.Name = `{index}-{Value.read(item.text)}`
			table.insert(children, button)
		end
	end

	return View(withCommonProps(props, {
		tag = function()
			local vertical, fill = isVertical(), isFill()
			return {
				["gap-small"] = true,
				["col flex-x-fill"] = vertical,
				--* No wrap when filling: each button (Size.X.Scale = 1) would take its own line.
				["row"] = not vertical and fill,
				["row wrap"] = not vertical and not fill,
				["size-full-0 auto-y"] = fill,
				["auto-xy"] = not fill,
			}
		end,
		children = children,
	}) :: any)
end

return ButtonGroup
