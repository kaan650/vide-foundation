local foundation = require("../foundation")
local MatrixGrid = require("../Shared/MatrixGrid")
local StoryIcons = require("../Shared/StoryIcons")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local InputFocusBehavior = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputFocusBehavior")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local InputVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputVariant")
local NumberInputControlsVariant =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/NumberInputControlsVariant")
local OnChangeCallbackReason = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/OnChangeCallbackReason")
local ScrubBehavior = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ScrubBehavior")

type InputFocusBehavior = InputFocusBehavior.InputFocusBehavior
type InputSize = InputSize.InputSize
type InputVariant = InputVariant.InputVariant
type NumberInputProps = VideFoundation.NumberInputProps
type OnChangeCallbackReason = OnChangeCallbackReason.OnChangeCallbackReason
type ScrubBehavior = ScrubBehavior.ScrubBehavior

local SIZE_ORDER: { InputSize } = {
	InputSize.XSmall,
	InputSize.Small,
	InputSize.Medium,
	InputSize.Large,
}
local VARIANT_ORDER: { InputVariant } = {
	InputVariant.Standard,
	InputVariant.Contrast,
	InputVariant.Utility,
}
local SCRUB_ORDER: { ScrubBehavior } = {
	ScrubBehavior.Off,
	ScrubBehavior.On,
}

local WIDTH_EXAMPLES: { { label: string, width: UDim? } } = {
	{ label = "Default (300)", width = nil },
	{ label = "120", width = UDim.new(0, 120) },
	{ label = "200", width = UDim.new(0, 200) },
	{ label = "320", width = UDim.new(0, 320) },
}

local ICON_TYPE_EXAMPLES = StoryIcons.ICON_TYPE_EXAMPLES
local ICON_CONTROL_OPTIONS = StoryIcons.buildIconControlOptions()

local ICON_INFO_COLUMN_WIDTH = 140
local ICON_CELL_COLUMN_WIDTH = 220

type FormatAsStringEntry = {
	name: string,
	callback: ((value: number) -> string)?,
}
local FORMAT_AS_STRING_CALLBACKS: { FormatAsStringEntry } = {
	{
		name = "none",
		callback = nil,
	},
	{
		name = "stringified",
		callback = function(numValue)
			return `{numValue}`
		end,
	},
	{
		name = "punctuation",
		callback = function(numValue)
			local withPunctuation = ""
			local roundedNumString = tostring(math.round(numValue))
			local s, e = math.max(#roundedNumString - 2, 1), #roundedNumString
			while e >= 1 do
				local nextThreeChars = string.sub(roundedNumString, s, e)
				e = s - 1
				s = math.max(e - 2, 1)
				if e >= 1 then
					withPunctuation = "," .. nextThreeChars .. withPunctuation
				else
					withPunctuation = nextThreeChars .. withPunctuation
				end
			end
			local numString = tostring(numValue)
			local decimalsStart, _ = string.find(numString, ".", 1, true)
			return withPunctuation .. string.sub(numString, decimalsStart or #numString + 1, #numString)
		end,
	},
}

local FORMAT_NAMES: { string } = {}
for index, entry in FORMAT_AS_STRING_CALLBACKS do
	FORMAT_NAMES[index] = entry.name
end

local function findFormatAsString(name: string): ((value: number) -> string)?
	for _, entry in FORMAT_AS_STRING_CALLBACKS do
		if entry.name == name then
			return entry.callback
		end
	end
	return nil
end

local function noop() end

local function Section(props: { caption: string, contentTag: string?, LayoutOrder: number?, children: any })
	return VF.View({
		tag = "col gap-medium size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.caption,
				tag = "auto-xy text-label-medium text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = props.contentTag or "row gap-xxlarge auto-xy wrap",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function Group(props: { caption: string, contentTag: string, LayoutOrder: number?, children: any })
	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.caption,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = props.contentTag,
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

type StatefulNumberInputProps = {
	defaultValue: number?,
	label: string,
	hint: VideFoundation.Value<string?>?,
	size: InputSize?,
	variant: InputVariant?,
	width: UDim?,
	minimum: number?,
	maximum: number?,
	step: number?,
	precision: number?,
	isDisabled: boolean?,
	hasError: boolean?,
	isRequired: boolean?,
	leadingIcon: string?,
	trailingIcon: string?,
	prefix: string?,
	suffix: string?,
	hasControls: boolean?,
	controlsVariant: NumberInputControlsVariant.NumberInputControlsVariant?,
	scrubBehavior: ScrubBehavior?,
	onScrubStarted: (() -> ())?,
	onScrubEnded: (() -> ())?,
	focusBehavior: InputFocusBehavior?,
}

--- A NumberInput that keeps its own value, starting at `defaultValue`.
local function StatefulNumberInput(props: StatefulNumberInputProps)
	local value = Vide.source(props.defaultValue or 0)

	return VF.NumberInput({
		value = value,
		onChanged = function(newValue: number)
			value(newValue)
		end,
		label = props.label,
		hint = props.hint,
		size = props.size,
		variant = props.variant,
		width = props.width,
		minimum = props.minimum,
		maximum = props.maximum,
		step = props.step,
		precision = props.precision,
		isDisabled = props.isDisabled,
		hasError = props.hasError,
		isRequired = props.isRequired,
		leadingIcon = props.leadingIcon,
		trailingIcon = props.trailingIcon,
		prefix = props.prefix,
		suffix = props.suffix,
		hasControls = props.hasControls,
		controlsVariant = props.controlsVariant,
		scrubBehavior = props.scrubBehavior,
		onScrubStarted = props.onScrubStarted,
		onScrubEnded = props.onScrubEnded,
		focusBehavior = props.focusBehavior,
	})
end

local function IconMatrixCell(props: { LayoutOrder: number, leadingIcon: string?, trailingIcon: string? })
	return VF.View({
		tag = "col align-x-left auto-y",
		Size = UDim2.fromOffset(ICON_CELL_COLUMN_WIDTH, 0),
		LayoutOrder = props.LayoutOrder,
		children = StatefulNumberInput({
			defaultValue = 0,
			label = "Value",
			leadingIcon = props.leadingIcon,
			trailingIcon = props.trailingIcon,
			minimum = 0,
			maximum = 100,
			step = 1,
			width = UDim.new(0, 200),
		}),
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local value = Vide.source(0)

	local function handleTextChanged(text: string)
		print(text)
	end

	--* formatAsString, onTextChanged and focusBehavior take plain values, so a change builds the input again.
	return foundation.rebuildOn(function()
		return `{controls.format()}/{controls.onTextChanged()}/{controls.focusBehavior()}`
	end, function()
		return VF.NumberInput({
			value = value,
			variant = controls.variant,
			hasError = controls.hasError,
			isDisabled = controls.isDisabled,
			isRequired = controls.isRequired,
			onChanged = function(newValue: number)
				value(newValue)
			end,
			onTextChanged = if controls.onTextChanged() then handleTextChanged else nil,
			formatAsString = findFormatAsString(controls.format()),
			label = controls.label,
			size = controls.size,
			width = function(): UDim?
				local width = controls.width()
				return if width == 0 then nil else UDim.new(0, width)
			end,
			maximum = controls.maximum,
			minimum = controls.minimum,
			step = controls.step,
			hint = controls.hint,
			precision = controls.precision,
			leadingIcon = function()
				return StoryIcons.parseIconControl(controls.leadingIcon())
			end,
			trailingIcon = function()
				return StoryIcons.parseIconControl(controls.trailingIcon())
			end,
			scrubBehavior = controls.scrubBehavior,
			prefix = function(): string?
				local prefix = controls.prefix()
				return if prefix == "" then nil else prefix
			end,
			suffix = function(): string?
				local suffix = controls.suffix()
				return if suffix == "" then nil else suffix
			end,
			hasControls = controls.hasControls,
			focusBehavior = foundation.orNil(controls.focusBehavior)(),
		})
	end)
end

local function VariantsStory()
	local groups = {}
	for index, variant in VARIANT_ORDER do
		groups[index] = Group({
			caption = variant,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = StatefulNumberInput({
				defaultValue = 0,
				variant = variant,
				label = "Value",
				minimum = 0,
				maximum = 100,
				step = 1,
				width = UDim.new(0, 200),
			}),
		})
	end
	return VF.View({ tag = "row wrap gap-xxlarge auto-xy", children = groups })
end

local function SizingStory()
	local sizes = {}
	for index, size in SIZE_ORDER do
		sizes[index] = Group({
			caption = size,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = StatefulNumberInput({
				defaultValue = 0,
				size = size,
				label = "Value",
				minimum = 0,
				maximum = 100,
				step = 1,
				width = UDim.new(0, 200),
			}),
		})
	end

	local widths = {}
	for index, example in WIDTH_EXAMPLES do
		widths[index] = Group({
			caption = example.label,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = StatefulNumberInput({
				defaultValue = 0,
				label = "Value",
				width = example.width,
				minimum = 0,
				maximum = 100,
				step = 1,
			}),
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y",
		children = {
			Section({
				caption = "Size",
				LayoutOrder = 1,
				contentTag = "row gap-xxlarge auto-xy align-y-bottom wrap",
				children = sizes,
			}),
			Section({
				caption = "Width",
				LayoutOrder = 2,
				contentTag = "row gap-xxlarge auto-xy align-y-bottom wrap",
				children = widths,
			}),
		},
	})
end

local function StatesStory()
	local states: { { caption: string, hint: string?, isDisabled: boolean?, hasError: boolean?, isRequired: boolean? } } =
		{
			{ caption = "Enabled" },
			{ caption = "Hint", hint = "Hint text" },
			{ caption = "Disabled", isDisabled = true },
			{ caption = "Error", hasError = true, hint = "Value is invalid" },
			{ caption = "Required", isRequired = true },
		}

	local groups = {}
	for index, state in states do
		groups[index] = Group({
			caption = state.caption,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = StatefulNumberInput({
				defaultValue = 0,
				label = "Value",
				hint = state.hint,
				isDisabled = state.isDisabled,
				hasError = state.hasError,
				isRequired = state.isRequired,
				minimum = 0,
				maximum = 100,
				step = 1,
				width = UDim.new(0, 200),
			}),
		})
	end
	return VF.View({ tag = "row wrap gap-xxlarge auto-xy", children = groups })
end

local function ControlledStory()
	local value = Vide.source(0)
	local lastReason = Vide.source(nil :: OnChangeCallbackReason?)
	local getLastReason: () -> OnChangeCallbackReason? = lastReason :: any

	return VF.View({
		tag = "col gap-medium size-full-0 auto-y",
		children = {
			VF.NumberInput({
				value = value,
				onChanged = function(newValue: number, reason: OnChangeCallbackReason)
					value(newValue)
					lastReason(reason)
				end,
				label = "Quantity",
				hint = "Number from 0 to 100",
				hasControls = true,
				controlsVariant = NumberInputControlsVariant.Split,
				minimum = 0,
				maximum = 100,
				step = 1,
				width = UDim.new(0, 200),
				LayoutOrder = 1,
			}),
			VF.Text({
				Text = function()
					return `Value: {value()} — last change: {getLastReason() or "none"}`
				end,
				tag = "auto-xy text-body-medium text-align-x-left content-emphasis",
				LayoutOrder = 2,
			}),
		},
	})
end

local function ScrubbingStory()
	local isScrubbing = Vide.source(false)

	local groups = {}
	for index, behavior in SCRUB_ORDER do
		groups[index] = Group({
			caption = behavior,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = StatefulNumberInput({
				defaultValue = 0,
				label = "Drag to change",
				hint = if behavior == ScrubBehavior.On
					then function(): string?
						return `Scrub enabled — Scrubbing: {isScrubbing()}`
					end
					else "Scrub disabled",
				scrubBehavior = behavior,
				onScrubStarted = function()
					isScrubbing(true)
				end,
				onScrubEnded = function()
					isScrubbing(false)
				end,
				hasControls = false,
				controlsVariant = NumberInputControlsVariant.None,
				minimum = 0,
				maximum = 100,
				step = 1,
				width = UDim.new(0, 200),
			}),
		})
	end
	return VF.View({ tag = "row wrap gap-xxlarge auto-xy", children = groups })
end

local function FocusBehaviorStory()
	local options: { { caption: string, focusBehavior: InputFocusBehavior, hint: string } } = {
		{ caption = "Clear", focusBehavior = InputFocusBehavior.Clear, hint = "Cursor placed on focus" },
		{
			caption = "Highlight",
			focusBehavior = InputFocusBehavior.Highlight,
			hint = "Selects all on focus (desktop only)",
		},
	}

	local groups = {}
	for index, option in options do
		groups[index] = Group({
			caption = option.caption,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = StatefulNumberInput({
				defaultValue = 0,
				label = "Value",
				hint = option.hint,
				focusBehavior = option.focusBehavior,
				minimum = 0,
				maximum = 100,
				step = 1,
				width = UDim.new(0, 200),
			}),
		})
	end
	return VF.View({ tag = "row wrap gap-xxlarge auto-xy", children = groups })
end

local function evaluateExpression(text: string): number?
	local trimmed = string.match(text, "^%s*(.-)%s*$")
	if trimmed == nil or trimmed == "" then
		return nil
	end

	local left, op, right = string.match(trimmed, "^(%d+%.?%d*)%s*([+%-])%s*(%d+%.?%d*)$")
	if left and op and right then
		local a, b = tonumber(left), tonumber(right)
		if a and b then
			if op == "+" then
				return a + b
			elseif op == "-" then
				return a - b
			end
		end
	end

	return tonumber(trimmed)
end

local EXPRESSION_INPUT_HINT = 'Type an expression like "3 + 5"'
local INVALID_EXPRESSION_HINT = "Could not compute expression"

local function ExpressionInputStory()
	local value = Vide.source(nil :: number?)
	local getValue: () -> number? = value :: any
	local expression = Vide.source("")
	local errorMessage = Vide.source(nil :: string?)
	local getErrorMessage: () -> string? = errorMessage :: any

	return VF.View({
		tag = "col gap-large auto-xy padding-large",
		children = {
			VF.NumberInput({
				value = function()
					return getValue() or 0
				end,
				label = "Padding",
				hasError = function()
					return getErrorMessage() ~= nil
				end,
				hint = function()
					return getErrorMessage() or EXPRESSION_INPUT_HINT
				end,
				onTextChanged = function(text: string)
					expression(text)
					errorMessage(nil)
				end,
				onChanged = noop,
				onFocusLost = function()
					local result = evaluateExpression(Vide.untrack(expression))
					if result ~= nil then
						value(result)
						expression(tostring(result))
						errorMessage(nil)
					else
						value(nil)
						errorMessage(INVALID_EXPRESSION_HINT)
					end
				end,
				width = UDim.new(0, 300),
				LayoutOrder = 1,
			}),
			VF.Text({
				tag = "auto-xy text-body-medium content-default",
				Text = function()
					local text = expression()
					return `Expression: {if text == "" then "—" else text}`
				end,
				LayoutOrder = 2,
			}),
			VF.Text({
				tag = "auto-xy text-body-medium content-emphasis",
				Text = function()
					local current = getValue()
					return if current ~= nil then `Value: {current}` else "Value: nil"
				end,
				LayoutOrder = 3,
			}),
		},
	})
end

local function StepIncrementsStory()
	local stepExamples: { { caption: string, step: number, precision: number?, minimum: number, maximum: number, defaultValue: number } } =
		{
			{ caption = "Step 1", step = 1, minimum = 0, maximum = 100, defaultValue = 10 },
			{ caption = "Step 5", step = 5, minimum = 0, maximum = 100, defaultValue = 10 },
			{ caption = "Step 0.25", step = 0.25, precision = 2, minimum = 0, maximum = 100, defaultValue = 1 },
			{ caption = "Tight range (0–5)", step = 1, minimum = 0, maximum = 5, defaultValue = 3 },
		}

	local groups = {}
	for index, example in stepExamples do
		groups[index] = Group({
			caption = example.caption,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = StatefulNumberInput({
				defaultValue = example.defaultValue,
				label = "Value",
				hint = if example.maximum == 5 then "Stops at 0 and 5" else `Steps by {example.step}`,
				hasControls = true,
				controlsVariant = NumberInputControlsVariant.Split,
				minimum = example.minimum,
				maximum = example.maximum,
				step = example.step,
				precision = example.precision,
				width = UDim.new(0, 200),
			}),
		})
	end
	return VF.View({ tag = "row wrap gap-xxlarge auto-xy", children = groups })
end

local function ContentStory()
	local prefixSuffixExamples: { { caption: string, prefix: string?, suffix: string?, leadingIcon: string? } } = {
		{ caption = "Prefix ($)", prefix = "$" },
		{ caption = "Suffix (%)", suffix = "%" },
		{ caption = "Suffix (px) + icon", suffix = "px", leadingIcon = ICON_TYPE_EXAMPLES[1].name },
	}

	local limitExamples: { { caption: string, defaultValue: number } } = {
		{ caption = "Above maximum (1000000 → 9999)", defaultValue = 1000000 },
		{ caption = "Below minimum (-500 → 0)", defaultValue = -500 },
	}

	local precisionExamples: { { caption: string, precision: number } } = {
		{ caption = "0", precision = 0 },
		{ caption = "1", precision = 1 },
		{ caption = "2", precision = 2 },
		{ caption = "3 (default)", precision = 3 },
	}

	local limits = {}
	for index, example in limitExamples do
		limits[index] = Group({
			caption = example.caption,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = StatefulNumberInput({
				defaultValue = example.defaultValue,
				label = "Value",
				minimum = 0,
				maximum = 9999,
				step = 1,
				width = UDim.new(0, 200),
			}),
		})
	end

	local precisions = {}
	for index, example in precisionExamples do
		precisions[index] = Group({
			caption = example.caption,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = StatefulNumberInput({
				defaultValue = 3.14159,
				label = "Value",
				precision = example.precision,
				minimum = 0,
				maximum = 100,
				step = 1,
				width = UDim.new(0, 200),
			}),
		})
	end

	local steppers = {}
	for index, size in SIZE_ORDER do
		steppers[index] = Group({
			caption = size,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = StatefulNumberInput({
				defaultValue = 0,
				size = size,
				label = "Value",
				hasControls = true,
				controlsVariant = NumberInputControlsVariant.Split,
				minimum = 0,
				maximum = 100,
				step = 1,
				width = UDim.new(0, 200),
			}),
		})
	end

	local prefixSuffix = {}
	for index, example in prefixSuffixExamples do
		prefixSuffix[index] = Group({
			caption = example.caption,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = StatefulNumberInput({
				defaultValue = 0,
				label = "Value",
				prefix = example.prefix,
				suffix = example.suffix,
				leadingIcon = example.leadingIcon,
				minimum = 0,
				maximum = 9999,
				step = 1,
				width = UDim.new(0, 200),
			}),
		})
	end

	local iconPerSize = {}
	for index, size in SIZE_ORDER do
		iconPerSize[index] = Group({
			caption = size,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = StatefulNumberInput({
				defaultValue = 0,
				size = size,
				label = "Value",
				leadingIcon = ICON_TYPE_EXAMPLES[1].name,
				minimum = 0,
				maximum = 100,
				step = 1,
				width = UDim.new(0, 200),
			}),
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y",
		children = {
			Section({ caption = "Number limits", LayoutOrder = 1, children = limits }),
			Section({ caption = "Precision", LayoutOrder = 2, children = precisions }),
			Section({ caption = "Steppers", LayoutOrder = 3, children = steppers }),
			Section({ caption = "Prefix / suffix", LayoutOrder = 4, children = prefixSuffix }),
			Section({
				caption = "Icon types and placement",
				LayoutOrder = 5,
				contentTag = "auto-xy",
				children = MatrixGrid.MatrixGrid({
					labelColumnWidth = ICON_INFO_COLUMN_WIDTH,
					columnHeaders = { "Leading", "Trailing" },
					cellColumnWidth = ICON_CELL_COLUMN_WIDTH,
					headerTextAlign = "left",
					cellAlign = "left",
					rows = StoryIcons.buildIconTypeMatrixRows(function(iconType)
						return {
							IconMatrixCell({ LayoutOrder = 1, leadingIcon = iconType.name }),
							IconMatrixCell({ LayoutOrder = 1, trailingIcon = iconType.name }),
						}
					end),
				}),
			}),
			Section({
				caption = "Icon per size",
				LayoutOrder = 6,
				contentTag = "row gap-xxlarge auto-xy align-y-bottom wrap",
				children = iconPerSize,
			}),
		},
	})
end

return foundation.sections({
	summary = "Numeric text input with steppers, scrubbing, prefix/suffix, formatting, and validation.",
	controls = {
		label = "Label",
		hint = "Number from -5 to 100",
		size = UILabs.Choose(SIZE_ORDER),
		isRequired = UILabs.Choose({ false, true }),
		variant = UILabs.Choose(VARIANT_ORDER),
		format = UILabs.Choose(FORMAT_NAMES),
		onTextChanged = false,
		hasError = false,
		isDisabled = false,
		maximum = 100,
		minimum = -5,
		step = 0.2,
		precision = 2,
		prefix = "",
		suffix = "",
		width = 0,
		scrubBehavior = UILabs.Choose(SCRUB_ORDER),
		leadingIcon = UILabs.Choose(ICON_CONTROL_OPTIONS),
		trailingIcon = UILabs.Choose(ICON_CONTROL_OPTIONS),
		hasControls = true,
		focusBehavior = UILabs.Choose({
			foundation.NONE,
			table.unpack(foundation.Dash.values(InputFocusBehavior :: any)),
		}),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Variants", story = VariantsStory },
		{ name = "Sizing", story = SizingStory },
		{ name = "States", story = StatesStory },
		{ name = "Controlled component", story = ControlledStory },
		{ name = "Scrubbing", story = ScrubbingStory },
		{ name = "Step increments", story = StepIncrementsStory },
		{ name = "Focus behavior", story = FocusBehaviorStory },
		{
			name = "Content",
			story = function()
				return foundation.scroll(ContentStory())
			end,
		},
		{
			name = "Expression input",
			summary = "Uses `onTextChanged` to allow for custom expressions to be written instead of exclusively numbers.",
			story = ExpressionInputStory,
		},
	},
})
