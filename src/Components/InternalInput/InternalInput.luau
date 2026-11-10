local Vide = require("../../Packages/Vide")

local Constants = require("../../Constants")
local InputHint = require("./InputHint")
local InputLabel = require("../InputLabel")
local InputSize = require("../../Enums/InputSize")
local Motion = require("../../Utility/Motion")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local getInputTextSize = require("../../Utility/getInputTextSize")
local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local useInputMotionStates = require("./useInputMotionStates")
local useInputVariants = require("./useInputVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type ColorStyleValue = Types.ColorStyleValue
type CursorConfig = Types.CursorConfig
type InputSize = InputSize.InputSize
type Value<T> = Types.Value<T>

export type InputColors = useInputMotionStates.InputColors

export type InputVariantProps = {
	tag: string,
	size: UDim2,
	cursorRadius: UDim?,
	colors: InputColors?,
	checkedStyle: ColorStyleValue?,
	stroke: {
		thickness: number?,
	}?,
}

export type InputLabelConfig = {
	-- The label text, or an instance shown in its place. To omit, set it to an empty string.
	text: (Value<string?> | GuiObject)?,
	position: Value<Enum.HorizontalAlignment?>?,
	hint: Value<string?>?,
}

export type InternalInputProps = {
	-- Whether the input is currently checked.
	isChecked: Value<boolean>,
	-- Whether the input is in an indeterminate state.
	-- Will override the filled state that isChecked contributes to.
	isIndeterminate: Value<boolean?>?,
	-- Whether the input is disabled. When `true`, the `onActivated` callback
	-- will not be invoked, even if the user interacts with the input.
	isDisabled: Value<boolean?>?,
	-- A function that will be called whenever the input is activated, with the new value.
	onActivated: (boolean) -> (),
	label: InputLabelConfig,
	size: Value<InputSize>?,
	-- Custom styles for the input.
	customVariantProps: Value<InputVariantProps>,
	children: Types.Children?,
} & Types.SelectionProps & Types.CommonProps

type Layout = { hasLabel: boolean, isDisabled: boolean }

--* React keeps the root while the label comes and goes and remounts it when disabling turns it into a CanvasGroup;
--* rebuilding on both gives the same tree.
local LAYOUTS: { [string]: Layout } = {
	Input = { hasLabel = false, isDisabled = false },
	DisabledInput = { hasLabel = false, isDisabled = true },
	Labelled = { hasLabel = true, isDisabled = false },
	DisabledLabelled = { hasLabel = true, isDisabled = true },
}

local STATE_LAYER: Types.StateLayer = { affordance = StateLayerAffordance.None }

local defaultProps = {
	size = InputSize.Medium,
	Selectable = true,
	testId = "--foundation-internal-input",
}

--- The box shared by Checkbox, RadioGroup.Item and Toggle: a styled input with an optional label and hint beside it.
--- `children` render inside the input. A source `isDisabled` or `label.text` returns a source of the instance.
local function InternalInput(inputProps: InternalInputProps): GuiObject | () -> GuiObject
	local props = withDefaults(inputProps, defaultProps)
	local label = props.label
	local testId = props.testId
	local tokens = useTokens()

	local function readLabel(): (string | GuiObject)?
		local text = label.text
		return if type(text) == "function" then (text :: () -> string?)() else text :: (string | GuiObject)?
	end
	local function hasLabel(): boolean
		local text = readLabel()
		return if type(text) == "string" then #text > 0 else text ~= nil
	end
	local function hint(): string?
		return Value.read(label.hint)
	end
	local function labelPosition(): Enum.HorizontalAlignment
		return Value.read(label.position) or Enum.HorizontalAlignment.Right
	end
	local function size(): InputSize
		return Value.read(props.size)
	end
	local function isChecked(): boolean
		return Value.read(props.isChecked) == true
	end
	local function isDisabled(): boolean
		return Value.read(props.isDisabled) == true
	end
	local function isFilled(): boolean
		return isChecked() or Value.read(props.isIndeterminate) == true
	end
	local function customVariantProps(): InputVariantProps
		return Value.read(props.customVariantProps)
	end

	local variantProps = Vide.derive(function()
		return useInputVariants(tokens(), size(), labelPosition())
	end)

	local function cursor(): CursorConfig
		return {
			radius = customVariantProps().cursorRadius or UDim.new(0, 0),
			offset = tokens().Size.Size_200,
			borderWidth = tokens().Stroke.Thicker,
		}
	end

	local motionStates = Vide.derive(function()
		return useInputMotionStates(tokens(), customVariantProps().colors)
	end)
	local values, animate = Motion.useMotion(Vide.untrack(motionStates).Default)
	Vide.effect(function()
		local filled = isFilled()
		local states = motionStates()
		Vide.untrack(function()
			animate(if filled then states.Checked else states.Default)
		end)
	end)

	local function onActivated()
		if Vide.untrack(isDisabled) then
			return
		end
		props.onActivated(not Vide.untrack(isChecked))
	end

	local function strokeThickness(): number
		local stroke = customVariantProps().stroke
		return if stroke and stroke.thickness ~= nil then stroke.thickness else variantProps().input.stroke.thickness
	end

	local function labelSize()
		return getInputTextSize(size())
	end

	local function inputLabel(): any
		local text = label.text
		if typeof(text) == "Instance" then
			return text
		end
		return InputLabel({
			Text = function()
				local current = readLabel()
				return if type(current) == "string" then current else ""
			end,
			textStyle = values.labelStyle,
			size = labelSize,
			testId = `{testId}--label`,
		})
	end

	local function build(layoutName: string): GuiObject
		local layout = LAYOUTS[layoutName]
		local disabled = layout.isDisabled
		local labelled = layout.hasLabel

		local selectionProps = {
			Selectable = if disabled then false else props.Selectable,
			NextSelectionUp = props.NextSelectionUp,
			NextSelectionDown = props.NextSelectionDown,
			NextSelectionLeft = props.NextSelectionLeft,
			NextSelectionRight = props.NextSelectionRight,
		}

		local inputContainerProps: { [string]: any } = {
			tag = function()
				return customVariantProps().tag
			end,
			Size = function()
				local thickness = strokeThickness()
				return customVariantProps().size - UDim2.fromOffset(thickness, thickness)
			end,
			backgroundStyle = values.backgroundStyle,
			onActivated = onActivated,
			stateLayer = STATE_LAYER,
			stroke = {
				Color = function()
					return values.strokeStyle().Color3
				end,
				--* Stroke transparency is not affected by GroupTransparency.
				Transparency = if disabled and not labelled
					then Constants.DISABLED_TRANSPARENCY
					else function()
						return values.strokeStyle().Transparency
					end,
				Thickness = strokeThickness,
				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
			},
			selection = selectionProps,
			cursor = cursor,
			children = props.children,
		}

		if not labelled then
			inputContainerProps.GroupTransparency = if disabled then Constants.DISABLED_TRANSPARENCY else 0
			inputContainerProps.isDisabled = disabled
			return View(withCommonProps(props, inputContainerProps) :: any)
		end

		inputContainerProps.LayoutOrder = function()
			--* Labels go after the input unless placed at the start (WCAG G162).
			return if labelPosition() == Enum.HorizontalAlignment.Left then 1 else -1
		end
		inputContainerProps.testId = `{testId}--container`

		local function padding(): UDim
			return variantProps().container.padding
		end

		return View(withCommonProps(props, {
			tag = function()
				return variantProps().container.tag
			end,
			--* Keeps the input's stroke inside the bounds of the CanvasGroup.
			padding = {
				top = padding,
				bottom = padding,
				left = function()
					return if labelPosition() == Enum.HorizontalAlignment.Right then padding() else UDim.new(0, 0)
				end,
				right = function()
					return if labelPosition() == Enum.HorizontalAlignment.Left then padding() else UDim.new(0, 0)
				end,
			},
			GroupTransparency = if disabled then Constants.DISABLED_TRANSPARENCY else 0,
			onActivated = onActivated,
			stateLayer = STATE_LAYER,
			selection = { Selectable = false },
			isDisabled = disabled,
			children = {
				named("Input", View(inputContainerProps :: any)),
				Vide.show(function()
					local current = hint()
					return current ~= nil and current ~= ""
				end, function()
					return named(
						"InputLabel",
						View({
							tag = "col gap-xxsmall auto-xy",
							children = {
								named("InputLabel", inputLabel()),
								named(
									"Hint",
									InputHint({
										text = function()
											return hint() or ""
										end,
										size = labelSize,
										testId = `{testId}--hint`,
										LayoutOrder = 2,
									})
								),
							},
						})
					)
				end, function()
					return named("InputLabel", inputLabel())
				end),
			},
		}) :: any)
	end

	local function layoutName(): string
		local labelled = hasLabel()
		local disabled = isDisabled()
		return if labelled
			then (if disabled then "DisabledLabelled" else "Labelled")
			else (if disabled then "DisabledInput" else "Input")
	end

	if type(props.isDisabled) ~= "function" and type(label.text) ~= "function" then
		return build(layoutName())
	end
	return rebuildOn(Vide.derive(layoutName), build)
end

return InternalInput
