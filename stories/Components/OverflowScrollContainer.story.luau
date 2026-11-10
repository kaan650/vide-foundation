local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local OverflowScrollContainer =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Components/OverflowScrollContainer")

type ColorStyleValue = VideFoundation.ColorStyleValue
type InputSize = InputSize.InputSize
type Value<T> = VideFoundation.Value<T>

local INPUT_SIZES: { InputSize } = {
	InputSize.XSmall,
	InputSize.Small,
	InputSize.Medium,
	InputSize.Large,
}

local DEFAULT_ROW_TAG = "size-2400-1000"

type SampleProps = {
	size: Value<InputSize>,
	rowTag: string?,
	forceHovered: Value<boolean?>?,
	forceScrimsVisible: Value<boolean?>?,
	preferredInput: Value<Enum.PreferredInput?>?,
	LayoutOrder: number?,
}

local function Sample(props: SampleProps)
	local tokens = VF.Hooks.useTokens()

	local children = {}
	for i = 1, 20 do
		children[i] = VF.View({
			LayoutOrder = i,
			tag = props.rowTag or DEFAULT_ROW_TAG,
			backgroundStyle = function(): ColorStyleValue
				return tokens().Inverse.Surface.Surface_0 :: ColorStyleValue
			end,
		})
	end

	return OverflowScrollContainer({
		LayoutOrder = props.LayoutOrder,
		size = props.size,
		forceHovered = props.forceHovered,
		forceScrimsVisible = props.forceScrimsVisible,
		forcePreferredInput = props.preferredInput,
		children = VF.View({
			tag = "row gap-small auto-xy",
			children = children,
		}),
	})
end

--- A captioned sample per entry of `list`, stacked.
local function LabeledSamples<T>(list: { T }, describe: (entry: T) -> (string, SampleProps))
	local rows = {}
	for index, entry in list do
		local label, sampleProps = describe(entry)
		sampleProps.LayoutOrder = 2
		rows[index] = VF.View({
			LayoutOrder = index,
			tag = "col gap-small size-full-0 auto-y",
			children = {
				VF.Text({
					LayoutOrder = 1,
					Text = label,
					tag = "auto-xy text-caption-large content-emphasis",
				}),
				Sample(sampleProps),
			},
		})
	end

	return VF.View({
		tag = "col gap-xlarge size-full-0 auto-y",
		children = rows,
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return Sample({
		size = controls.size,
		forceHovered = controls.forceHovered,
		forceScrimsVisible = controls.forceScrimsVisible,
		preferredInput = controls.preferredInput,
	})
end

local SCRIM_STATES: { { label: string, forceHovered: boolean } } = {
	{ label = "Resting", forceHovered = false },
	{ label = "Hovered", forceHovered = true },
}

local function ScrimStatesStory(controls: { [string]: any })
	return LabeledSamples(SCRIM_STATES, function(state)
		return state.label,
			{
				size = controls.size,
				forceHovered = state.forceHovered,
				forceScrimsVisible = true,
				preferredInput = controls.preferredInput,
			}
	end)
end

local INPUT_TYPES: { { label: string, preferredInput: Enum.PreferredInput } } = {
	{ label = "Keyboard and mouse", preferredInput = Enum.PreferredInput.KeyboardAndMouse },
	{ label = "Gamepad", preferredInput = Enum.PreferredInput.Gamepad },
	{ label = "Touch", preferredInput = Enum.PreferredInput.Touch },
}

local function InputTypesStory(controls: { [string]: any })
	return LabeledSamples(INPUT_TYPES, function(inputType)
		return inputType.label,
			{
				size = controls.size,
				forceScrimsVisible = true,
				preferredInput = inputType.preferredInput,
			}
	end)
end

local function SizesStory()
	return LabeledSamples(INPUT_SIZES, function(size)
		return size, { size = size }
	end)
end

local ROW_HEIGHTS: { { label: string, tag: string } } = {
	{ label = "24px rows", tag = "size-2400-600" },
	{ label = "40px rows", tag = "size-2400-1000" },
	{ label = "64px rows", tag = "size-2400-1600" },
	{ label = "96px rows", tag = "size-2400-2400" },
}

local function RowHeightsStory(controls: { [string]: any })
	return LabeledSamples(ROW_HEIGHTS, function(rowHeight)
		return rowHeight.label,
			{
				size = controls.size,
				rowTag = rowHeight.tag,
				forceScrimsVisible = true,
				preferredInput = controls.preferredInput,
			}
	end)
end

return foundation.sections({
	summary = "OverflowScrollContainer lays content out in a horizontally scrolling row, revealing edge scrims and nav affordances when the content overflows.",
	controls = {
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		forceHovered = false,
		forceScrimsVisible = false,
		preferredInput = UILabs.Choose({
			Enum.PreferredInput.KeyboardAndMouse,
			Enum.PreferredInput.Gamepad,
			Enum.PreferredInput.Touch,
		}),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Scrim states",
			summary = "Both scrims held open at the controlled size, resting above hovered, so the "
				.. "two treatments can be read side by side without pointing at either",
			story = ScrimStatesStory,
		},
		{
			name = "Input types",
			summary = "Scrims held open at the controlled size for each preferred input, so the "
				.. "direction affordance can be compared: a chevron for keyboard and mouse and for "
				.. "touch, a shoulder-button glyph for gamepad",
			story = InputTypesStory,
		},
		{
			name = "Sizes",
			summary = "Every supported size over rows of one fixed height, so the only thing that "
				.. "changes down the list is the scrim's chevron. Size does not set the "
				.. "container's height, which comes from the content, nor the scrim's width, "
				.. "which follows the measured content height",
			story = SizesStory,
		},
		{
			name = "Row heights",
			summary = "One size over rows of three different heights, scrims held open. The scrim "
				.. "measures the row it overlays, so a taller row widens the scrim and grows the "
				.. "chevron's square, while the chevron glyph itself stays fixed at the "
				.. "controlled size",
			story = RowHeightsStory,
		},
	},
})
