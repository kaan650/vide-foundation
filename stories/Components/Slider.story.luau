local foundation = require("../foundation")
local MatrixGrid = require("../Shared/MatrixGrid")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local IconSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/IconSize")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local Orientation = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/Orientation")
local PopoverAlign = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/PopoverAlign")
local PopoverSide = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/PopoverSide")
local SliderType = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/SliderType")
local SliderVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/SliderVariant")
local Visibility = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/Visibility")

type ColorStyleValue = VideFoundation.ColorStyleValue
type InputSize = InputSize.InputSize
type Orientation = Orientation.Orientation
type SliderVariant = SliderVariant.SliderVariant
type Visibility = Visibility.Visibility

local IconName = VF.Enums.IconName

local SIZE_ORDER: { InputSize } = {
	InputSize.XSmall,
	InputSize.Small,
	InputSize.Medium,
	InputSize.Large,
}

type VisualColumn = { name: string, variant: SliderVariant, isDisabled: boolean }

local VISUAL_COLUMNS: { VisualColumn } = {
	{ name = "Standard", variant = SliderVariant.Standard, isDisabled = false },
	{ name = "Standard disabled", variant = SliderVariant.Standard, isDisabled = true },
	{ name = "Emphasis", variant = SliderVariant.Emphasis, isDisabled = false },
	{ name = "Emphasis disabled", variant = SliderVariant.Emphasis, isDisabled = true },
}

local VISUALS_LABEL_COLUMN_WIDTH = 80
local VISUALS_CELL_COLUMN_WIDTH = 200
local VISUALS_SLIDER_WIDTH = UDim.new(0, 180)
local VERTICAL_CELL_COLUMN_WIDTH = 80
local VERTICAL_SLIDER_LENGTH = UDim.new(0, 240)
local ORIENTATION_OPTIONS: { Orientation } = { Orientation.Horizontal, Orientation.Vertical }
local KNOB_VISIBILITY_OPTIONS: { Visibility } = {
	Visibility.None,
	Visibility.Always,
	Visibility.Auto,
}
local SLIDER_VARIANT_OPTIONS: { SliderVariant } = {
	SliderVariant.Emphasis,
	SliderVariant.Standard,
	SliderVariant.Utility,
}
local POPOVER_SLIDER_WIDTH = UDim.new(0, 240)

local function PlaygroundStory(controls: { [string]: any })
	local value = Vide.source(0.5)

	return VF.View({
		tag = function()
			return if controls.orientation() == Orientation.Vertical
				then "align-x-center size-full-3000"
				else "size-full-0 auto-y"
		end,
		--* Slider picks its knob when it is created, so toggling the custom knob builds it again.
		children = foundation.rebuildOn(controls.hasCustomKnob, function(hasCustomKnob: boolean)
			return VF.Slider({
				value = value,
				range = function()
					local min: number, max: number = controls.rangeMin(), controls.rangeMax()
					return NumberRange.new(min, max)
				end,
				size = controls.size,
				orientation = controls.orientation,
				knobVisibility = controls.knobVisibility,
				variant = controls.variant,
				isDisabled = controls.isDisabled,
				isContained = controls.isContained,
				step = controls.step,
				onValueChanged = function(newValue: number)
					value(newValue)
				end,
				knob = if hasCustomKnob
					then VF.Icon({
						name = IconName.Tilt,
						size = IconSize.Medium,
					})
					else nil,
				onDragStarted = function()
					print("Drag started. Previous value:", value())
				end,
				onDragEnded = function()
					print("Drag ended. Final value:", value())
				end,
			})
		end),
	})
end

local function HorizontalVisualsStory()
	local columnHeaders = {}
	for index, column in VISUAL_COLUMNS do
		columnHeaders[index] = column.name
	end

	local rows: { MatrixGrid.MatrixGridRow } = {}
	for index, size in SIZE_ORDER do
		local cells = {}
		for columnIndex, column in VISUAL_COLUMNS do
			cells[columnIndex] = VF.Slider({
				value = 0.5,
				size = size,
				width = VISUALS_SLIDER_WIDTH,
				variant = column.variant,
				isDisabled = column.isDisabled,
				knobVisibility = Visibility.Always,
			})
		end
		rows[index] = { label = MatrixGrid.matrixLabel(size), cells = cells }
	end

	return MatrixGrid.MatrixGrid({
		labelColumnWidth = VISUALS_LABEL_COLUMN_WIDTH,
		columnHeaders = columnHeaders,
		cellColumnWidth = VISUALS_CELL_COLUMN_WIDTH,
		headerTextAlign = "left",
		cellAlign = "left",
		rowGap = "xxlarge",
		rows = rows,
	})
end

local function VerticalVisualsStory()
	local columnHeaders = {}
	for index, column in VISUAL_COLUMNS do
		columnHeaders[index] = column.name
	end

	local rows: { MatrixGrid.MatrixGridRow } = {}
	for index, size in SIZE_ORDER do
		local cells = {}
		for columnIndex, column in VISUAL_COLUMNS do
			cells[columnIndex] = VF.Slider({
				value = 0.5,
				orientation = Orientation.Vertical,
				size = size,
				width = VERTICAL_SLIDER_LENGTH,
				variant = column.variant,
				isDisabled = column.isDisabled,
				knobVisibility = Visibility.Always,
			})
		end
		rows[index] = { label = MatrixGrid.matrixLabel(size), cells = cells }
	end

	return MatrixGrid.MatrixGrid({
		labelColumnWidth = VISUALS_LABEL_COLUMN_WIDTH,
		columnHeaders = columnHeaders,
		cellColumnWidth = VERTICAL_CELL_COLUMN_WIDTH,
		rowGap = "xxlarge",
		rows = rows,
	})
end

local function RangeStory()
	local value = Vide.source(NumberRange.new(25, 75))

	return VF.View({
		tag = "col gap-small size-full-0 auto-y",
		children = {
			VF.Slider({
				type = SliderType.Range,
				value = value,
				onValueChanged = function(newValue: NumberRange)
					value(newValue)
				end,
				range = NumberRange.new(0, 100),
				LayoutOrder = 1,
			}),
			VF.Text({
				Text = function()
					local current = value()
					return `{math.round(current.Min)} - {math.round(current.Max)}`
				end,
				tag = "auto-xy text-body-medium content-default",
				LayoutOrder = 2,
			}),
		},
	})
end

local function MediaTimelineStory()
	local value = Vide.source(0.25)
	local isPlaying = Vide.source(false)
	local wasPlaying = false

	Vide.effect(function()
		if not isPlaying() then
			return
		end
		local isRunning = true
		--* Deferred so the loop's reads and writes happen outside this effect.
		task.defer(function()
			while isRunning do
				value(value() + 1 / 600)
				task.wait(1 / 16)
			end
		end)
		Vide.cleanup(function()
			isRunning = false
		end)
	end)

	return VF.View({
		tag = "col gap-small size-full-0 auto-y",
		children = {
			VF.Slider({
				value = value,
				size = InputSize.XSmall,
				knobVisibility = Visibility.Auto,
				variant = SliderVariant.Standard,
				onValueChanged = function(newValue: number)
					value(newValue)
				end,
				onDragStarted = function()
					if Vide.untrack(isPlaying) then
						wasPlaying = true
					end
					isPlaying(false)
				end,
				onDragEnded = function()
					if wasPlaying then
						isPlaying(true)
					end
					wasPlaying = false
				end,
				LayoutOrder = 1,
			}),
			VF.Button({
				text = function()
					return if isPlaying() then "Pause" else "Play"
				end,
				onActivated = function()
					isPlaying(not isPlaying())
				end,
				LayoutOrder = 2,
			}),
		},
	})
end

local function CustomStory()
	local tokens = VF.Hooks.useTokens()
	local value = Vide.source(0.5)

	local function startColor(): ColorStyleValue
		return tokens().Color.Extended.Blue.Blue_1400 :: ColorStyleValue
	end
	local function endColor(): ColorStyleValue
		return tokens().Color.Extended.Blue.Blue_100 :: ColorStyleValue
	end

	return VF.View({
		tag = "size-full-0 auto-y stroke-standard stroke-emphasis radius-circle",
		backgroundStyle = function(): ColorStyleValue
			return tokens().Color.Extended.White.White_100 :: ColorStyleValue
		end,
		children = {
			foundation.create("UIGradient")({
				Name = "Gradient",
				Color = function()
					return ColorSequence.new({
						ColorSequenceKeypoint.new(0, startColor().Color3 :: Color3),
						ColorSequenceKeypoint.new(1, endColor().Color3 :: Color3),
					})
				end,
			}),
			VF.Slider({
				value = value,
				size = InputSize.Medium,
				variant = SliderVariant.Utility,
				isContained = true,
				knob = VF.Knob({
					size = InputSize.Large,
					style = function(): ColorStyleValue
						local from, to, alpha = startColor(), endColor(), value()
						return {
							Color3 = (from.Color3 :: Color3):Lerp(to.Color3 :: Color3, alpha),
							Transparency = math.lerp(from.Transparency :: number, to.Transparency :: number, alpha),
						}
					end,
					--* React maps a binding for the style, which keeps the knob's shadow a CanvasGroup.
					isStyleBinding = true,
					stroke = function()
						return {
							Color = tokens().Color.System.Neutral.Color3,
							Transparency = tokens().Color.System.Neutral.Transparency,
							Thickness = math.round(tokens().Stroke.Thick),
						}
					end,
					hasShadow = true,
				}),
				knobVisibility = Visibility.Always,
				onValueChanged = function(newValue: number)
					value(newValue)
				end,
				width = UDim.new(1, 0),
			}),
		},
	})
end

local function RotatedStory()
	local value = Vide.source(0.5)
	local numSliders = 7

	local sliders = {}
	for i = 0, 360, 360 / numSliders do
		table.insert(
			sliders,
			VF.View({
				Size = UDim2.fromScale(1 / numSliders, 0),
				LayoutOrder = i,
				children = foundation.create("Folder")({
					Name = "Folder",
					VF.View({
						tag = "size-full",
						Rotation = i,
						children = VF.Slider({
							value = value,
							onValueChanged = function(newValue: number)
								value(newValue)
							end,
						}),
					}),
				}),
			})
		)
	end

	return VF.View({
		tag = "row align-y-center size-full-3000",
		children = sliders,
	})
end

local function PopoverStory()
	local isOpen = Vide.source(true)
	local value = Vide.source(0.5)

	return VF.View({
		tag = "row align-x-center align-y-center size-full-0 auto-y",
		children = VF.Popover.Root({
			isOpen = isOpen,
			children = function()
				return {
					VF.Popover.Anchor({
						children = VF.Button({
							text = function()
								return if isOpen() then "Close popover" else "Open popover"
							end,
							onActivated = function()
								isOpen(not isOpen())
							end,
						}),
					}),
					VF.Popover.Content({
						side = PopoverSide.Bottom,
						align = PopoverAlign.Start,
						onPressedOutside = function()
							isOpen(false)
						end,
						children = function()
							return VF.View({
								tag = "col gap-medium auto-xy padding-medium",
								children = {
									VF.Text({
										Text = "Slider in Popover",
										tag = "auto-xy text-title-medium content-emphasis",
										LayoutOrder = 1,
									}),
									VF.Slider({
										value = value,
										onValueChanged = function(newValue: number)
											value(newValue)
										end,
										width = POPOVER_SLIDER_WIDTH,
										knobVisibility = Visibility.Always,
										LayoutOrder = 2,
									}),
								},
							})
						end,
					}),
				}
			end,
		}),
	})
end

return foundation.sections({
	summary = `If dragging does not work make sure to deselect any tools in Studio! By default the "Select" tool is selected and will interfere with dragging behavior`,
	controls = {
		size = UILabs.Choose(SIZE_ORDER),
		orientation = UILabs.Choose(ORIENTATION_OPTIONS),
		knobVisibility = UILabs.Choose(KNOB_VISIBILITY_OPTIONS),
		isDisabled = false,
		isContained = false,
		variant = UILabs.Choose(SLIDER_VARIANT_OPTIONS),
		hasCustomKnob = false,
		rangeMin = -50,
		rangeMax = 100,
		step = 0,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Horizontal visuals",
			summary = "Standard and Emphasis sliders, enabled and disabled, across every size",
			story = HorizontalVisualsStory,
		},
		{
			name = "Vertical visuals",
			summary = "Standard and Emphasis vertical sliders, enabled and disabled, across every size",
			story = VerticalVisualsStory,
		},
		{
			name = "Range",
			summary = "SliderType.Range selects an interval with two thumbs that stop when they meet",
			story = RangeStory,
		},
		{
			name = "Media timeline",
			summary = "Press the Play button to simulate media playback, then click and drag to seek around the timeline",
			story = MediaTimelineStory,
		},
		{ name = "Custom", summary = "Color slider with gradient background", story = CustomStory },
		{ name = "Rotated", summary = "Sliders in containers rotated", story = RotatedStory },
		{ name = "Popover", summary = "Slider mounted inside a Popover", story = PopoverStory },
	},
})
