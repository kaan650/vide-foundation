local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")

local ColorNamespace = require("../../Enums/ColorNamespace")
local Constants = require("../../Constants")
local InputPlacement = require("../../Enums/InputPlacement")
local InputSize = require("../../Enums/InputSize")
local InternalInput = require("../InternalInput")
local Knob = require("../Knob")
local Motion = require("../../Utility/Motion")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local named = require("../../Utility/named")
local useInputGroupDefaults = require("../InternalInputGroup/useInputGroupDefaults")
local useTokens = require("../../Providers/Style/useTokens")
local useToggleVariants = require("./useToggleVariants")
local useUncontrolledState = require("../InternalInput/useUncontrolledState")
local withCommonProps = require("../../Utility/withCommonProps")

type InputPlacement = InputPlacement.InputPlacement
type InputSize = InputSize.InputSize
type KnobIcon = Knob.KnobIcon
type Value<T> = Types.Value<T>

local SPRING_PARAMETERS: Motion.SpringOptions = {
	frequency = 4,
}

local CHECK_ICON: KnobIcon = {
	name = BuilderIcons.Icon.Check,
	variant = BuilderIcons.IconVariant.Regular,
}

local IS_INVERSE: PresentationContext.PresentationContextValue = {
	isIconSize = false,
	colorNamespace = ColorNamespace.Color,
}

export type ToggleProps = {
	-- Whether the toggle is currently checked (i.e. on). If it is left `nil`,
	-- the toggle will be considered uncontrolled.
	isChecked: Value<boolean?>?,
	-- Whether the toggle is disabled. When `true`, the `onActivated` callback
	-- will not be invoked, even if the user interacts with the toggle.
	isDisabled: Value<boolean?>?,
	-- A function that will be called whenever the toggle is activated.
	-- Returns the new value of the toggle when uncontrolled.
	onActivated: (boolean) -> (),
	-- A label for the toggle. To omit, set it to an empty string.
	label: Value<string>,
	-- A secondary description displayed below the label.
	hint: Value<string?>?,
	size: Value<InputSize>?,
	placement: Value<InputPlacement>?,
} & Types.SelectionProps & Types.CommonProps

local defaultProps = {
	size = InputSize.Medium,
	placement = InputPlacement.Start,
	Selectable = true,
	testId = "--foundation-toggle",
}

--- A switch whose knob slides between off and on. Inside an input group it takes the group's size and placement.
--- A source `isDisabled` or `label` returns a source of the instance.
local function Toggle(toggleProps: ToggleProps): GuiObject | () -> GuiObject
	local props = useInputGroupDefaults(toggleProps, defaultProps)
	local tokens = useTokens()

	local function size(): InputSize
		return Value.read(props.size)
	end
	local variantProps = Vide.derive(function()
		return useToggleVariants(tokens(), size())
	end)
	local isChecked, onActivated = useUncontrolledState(props.isChecked, props.onActivated)

	local progress, setProgressGoal = Motion.useAnimatedBinding(if Vide.untrack(isChecked) then 1 else 0)
	Vide.effect(function()
		local goal = if isChecked() then 1 else 0
		Vide.untrack(function()
			setProgressGoal(Motion.spring(goal, SPRING_PARAMETERS))
		end)
	end)

	local knob = PresentationContext.context(IS_INVERSE, function()
		return named(
			"Knob",
			Knob({
				size = function(): InputSize
					local current = size()
					return if current == InputSize.Large then InputSize.Medium else current
				end,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = function()
					local positions = variantProps().knob
					return positions.offPosition:Lerp(positions.onPosition, progress())
				end,
				hasShadow = false,
				icon = function(): KnobIcon?
					return if isChecked() then CHECK_ICON else nil
				end,
				testId = `{props.testId}--knob`,
			})
		)
	end)

	return InternalInput(withCommonProps(props, {
		isChecked = isChecked,
		isDisabled = props.isDisabled,
		onActivated = onActivated,
		label = {
			text = props.label,
			position = function()
				return Constants.INPUT_PLACEMENT_TO_LABEL_ALIGNMENT[Value.read(props.placement)]
			end,
			hint = props.hint,
		},
		customVariantProps = function()
			return variantProps().input
		end,
		size = props.size,
		Selectable = props.Selectable,
		NextSelectionUp = props.NextSelectionUp,
		NextSelectionDown = props.NextSelectionDown,
		NextSelectionLeft = props.NextSelectionLeft,
		NextSelectionRight = props.NextSelectionRight,
		children = knob,
	}) :: any)
end

return Toggle
