local RunService = game:GetService("RunService")

local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local PreferencesProvider =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Providers/Preferences/PreferencesProvider")
local ProgressShape = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ProgressShape")
local ProgressSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ProgressSize")
local ProgressTypes = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Progress")

type ProgressCircleProps = ProgressTypes.ProgressCircleProps
type ProgressShape = ProgressShape.ProgressShape
type ProgressSize = ProgressSize.ProgressSize
type Value<T> = VideFoundation.Value<T>

local SIZE_ORDER: { ProgressSize } = {
	ProgressSize.Small,
	ProgressSize.Medium,
	ProgressSize.Large,
}

local SHAPE_ORDER: { ProgressShape } = {
	ProgressShape.Bar,
	ProgressShape.Circle,
}

local PLAYGROUND_SHAPE_OPTIONS: { ProgressShape } = {
	ProgressShape.Bar,
	ProgressShape.Circle,
}

local PLAYGROUND_SIZE_OPTIONS: { ProgressSize } = {
	ProgressSize.Medium,
	ProgressSize.Small,
	ProgressSize.Large,
}

local DEFAULT_VALUE = 65
local BAR_CONTAINER_WIDTH = 300
local WIDTH_FILL_CONTAINER = 400
local WIDTH_FIXED = UDim.new(0, 200)
local WIDTH_FILL = UDim.new(1, 0)
local ANIMATION_SECONDS = 3

local VALUE_INCREMENTS: { number } = { 0, 25, 50, 75, 100 }

local CLAMPING_VALUES: { { label: string, value: number } } = {
	{ label = "-10", value = -10 },
	{ label = "150", value = 150 },
}

local REDUCED_MOTION_EXAMPLES: { { label: string, note: string, reducedMotion: boolean } } = {
	{
		label = "Default",
		note = "Circle sweeps a spinning arc, bar scrolls a shimmer.",
		reducedMotion = false,
	},
	{
		label = "Reduced motion",
		note = "Both pulse in place, with no movement.",
		reducedMotion = true,
	},
}

local function Section(props: { LayoutOrder: number, name: string, contentTag: string?, children: any })
	return VF.View({
		tag = "col gap-medium size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.name,
				tag = "auto-xy text-label-medium content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = props.contentTag or "row gap-large auto-xy wrap",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function Subsection(props: {
	LayoutOrder: number,
	name: string,
	note: string?,
	contentTag: string?,
	children: any,
})
	local title = if props.note
		then VF.View({
			tag = "col align-x-left gap-xsmall auto-xy",
			LayoutOrder = 1,
			children = {
				VF.Text({
					Text = props.name,
					tag = "auto-xy text-caption-small text-align-x-left content-default",
					LayoutOrder = 1,
				}),
				VF.Text({
					Text = props.note,
					tag = "auto-xy text-caption-small text-align-x-left content-muted",
					LayoutOrder = 2,
				}),
			},
		})
		else VF.Text({
			Text = props.name,
			tag = "auto-xy text-caption-small text-align-x-left content-default",
			LayoutOrder = 1,
		})

	return VF.View({
		tag = "col gap-medium size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			title,
			VF.View({
				tag = props.contentTag or "row gap-large auto-xy wrap",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function ProgressContainer(props: { shape: ProgressShape, containerWidth: number?, children: any })
	if props.shape == ProgressShape.Bar then
		return VF.View({
			tag = "size-full-0 auto-y",
			Size = UDim2.fromOffset(props.containerWidth or BAR_CONTAINER_WIDTH, 0),
			children = props.children,
		})
	end
	return VF.View({
		tag = "auto-xy",
		children = props.children,
	})
end

local function WidthExampleContainer(props: { width: number, children: any })
	return VF.View({
		tag = "col size-full-0 auto-y padding-medium radius-medium bg-surface-100",
		Size = UDim2.fromOffset(props.width, 0),
		children = props.children,
	})
end

local function Indicator(
	props: { shape: ProgressShape, size: Value<ProgressSize>?, value: Value<number?>?, width: UDim? }
)
	if props.shape == ProgressShape.Bar then
		return VF.Progress({
			shape = ProgressShape.Bar,
			--* A bar has no Large size and shows Medium for it.
			size = props.size :: any,
			value = props.value,
			width = props.width,
		})
	end
	local circleProps: ProgressCircleProps = {
		shape = ProgressShape.Circle,
		size = props.size,
		value = props.value,
	}
	return VF.Progress(circleProps)
end

local function LabeledProgress(props: {
	label: string,
	LayoutOrder: number,
	shape: ProgressShape?,
	size: ProgressSize?,
	value: Value<number>?,
	width: UDim?,
	containerWidth: number?,
})
	local shape: ProgressShape = props.shape or ProgressShape.Bar

	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "auto-xy",
				LayoutOrder = 2,
				children = ProgressContainer({
					shape = shape,
					containerWidth = props.containerWidth,
					children = Indicator({
						shape = shape,
						size = props.size,
						value = props.value,
						width = props.width,
					}),
				}),
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local function value(): number?
		return if controls.isIndeterminate() then nil else controls.value()
	end

	--* Progress picks its component from `shape` once, so a new shape builds it again.
	return foundation.rebuildOn(controls.shape, function(shape: ProgressShape)
		return ProgressContainer({
			shape = shape,
			containerWidth = BAR_CONTAINER_WIDTH,
			children = Indicator({
				shape = shape,
				size = controls.size,
				value = value,
			}),
		})
	end)
end

local function VariantsStory()
	local children = {}
	for index, shape in SHAPE_ORDER do
		children[index] = LabeledProgress({
			label = shape,
			LayoutOrder = index,
			shape = shape,
			value = DEFAULT_VALUE,
		})
	end
	return VF.View({
		tag = "row wrap gap-large auto-xy padding-large bg-surface-0",
		children = children,
	})
end

local BAR_SIZE_ORDER: { ProgressSize } = {
	ProgressSize.Small,
	ProgressSize.Medium,
}

local function SizingStory()
	local bars = {}
	for index, size in BAR_SIZE_ORDER do
		bars[index] = LabeledProgress({
			label = size,
			LayoutOrder = index,
			shape = ProgressShape.Bar,
			size = size,
			value = DEFAULT_VALUE,
		})
	end

	local circles = {}
	for index, size in SIZE_ORDER do
		circles[index] = LabeledProgress({
			label = size,
			LayoutOrder = index,
			shape = ProgressShape.Circle,
			size = size,
			value = DEFAULT_VALUE,
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Size",
				contentTag = "col gap-xlarge size-full-0 auto-y",
				children = {
					Subsection({
						LayoutOrder = 1,
						name = "Circle",
						contentTag = "row gap-large auto-xy wrap",
						children = circles,
					}),
					Subsection({
						LayoutOrder = 2,
						name = "Bar (Small and Medium)",
						contentTag = "row gap-large auto-xy wrap",
						children = bars,
					}),
				},
			}),
			Section({
				LayoutOrder = 2,
				name = "Width",
				contentTag = "col gap-xlarge size-full-0 auto-y",
				children = {
					Subsection({
						LayoutOrder = 1,
						name = `Fixed width (200px in {BAR_CONTAINER_WIDTH}px parent)`,
						contentTag = "auto-xy",
						children = WidthExampleContainer({
							width = BAR_CONTAINER_WIDTH,
							children = VF.Progress({
								shape = ProgressShape.Bar,
								value = DEFAULT_VALUE,
								width = WIDTH_FIXED,
							}),
						}),
					}),
					Subsection({
						LayoutOrder = 2,
						name = `Fill ({WIDTH_FILL_CONTAINER}px parent)`,
						contentTag = "auto-xy",
						children = WidthExampleContainer({
							width = WIDTH_FILL_CONTAINER,
							children = VF.Progress({
								shape = ProgressShape.Bar,
								value = DEFAULT_VALUE,
								width = WIDTH_FILL,
							}),
						}),
					}),
				},
			}),
		},
	})
end

local function indeterminatePair(): { any }
	return {
		LabeledProgress({
			label = ProgressShape.Circle,
			LayoutOrder = 1,
			shape = ProgressShape.Circle,
		}),
		LabeledProgress({
			label = ProgressShape.Bar,
			LayoutOrder = 2,
			shape = ProgressShape.Bar,
		}),
	}
end

local function StatesStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "Indeterminate",
			contentTag = "row gap-large auto-xy wrap",
			children = indeterminatePair(),
		}),
	})
end

local function ControlledProgressExample()
	local progress = Vide.source(0)
	local isAnimating = Vide.source(false)

	Vide.effect(function()
		if not isAnimating() then
			return
		end
		local startTime = os.clock()
		local connection: RBXScriptConnection
		connection = RunService.Heartbeat:Connect(function()
			local newProgress = math.min((os.clock() - startTime) / ANIMATION_SECONDS * 100, 100)
			progress(newProgress)
			if newProgress >= 100 then
				connection:Disconnect()
				isAnimating(false)
			end
		end)
		Vide.cleanup(connection)
	end)

	return VF.View({
		tag = "col gap-medium size-full-0 auto-y",
		children = {
			VF.Text({
				Text = function()
					return `Progress: {math.floor(progress())}%`
				end,
				tag = "size-0-0 auto-xy text-title-small content-emphasis",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "row align-y-center gap-large auto-xy",
				LayoutOrder = 2,
				children = {
					LabeledProgress({
						label = ProgressSize.Medium,
						LayoutOrder = 1,
						shape = ProgressShape.Circle,
						size = ProgressSize.Medium,
						value = progress,
					}),
					LabeledProgress({
						label = ProgressSize.Large,
						LayoutOrder = 2,
						shape = ProgressShape.Circle,
						size = ProgressSize.Large,
						value = progress,
					}),
				},
			}),
			LabeledProgress({
				label = ProgressShape.Bar,
				LayoutOrder = 3,
				shape = ProgressShape.Bar,
				value = progress,
			}),
			VF.Button({
				text = function()
					return if isAnimating() then "Animating..." else "Start animation"
				end,
				onActivated = function()
					progress(0)
					isAnimating(true)
				end,
				isDisabled = isAnimating,
				LayoutOrder = 4,
			}),
		},
	})
end

local function ControlledStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = ControlledProgressExample(),
	})
end

local function ReducedMotionStory()
	local examples = {}
	for index, example in REDUCED_MOTION_EXAMPLES do
		examples[index] = Subsection({
			LayoutOrder = index,
			name = example.label,
			note = example.note,
			contentTag = "row gap-xlarge align-y-center auto-xy wrap",
			children = PreferencesProvider({
				preferences = { reducedMotion = example.reducedMotion },
				children = indeterminatePair,
			}),
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "Indeterminate",
			contentTag = "col gap-xlarge size-full-0 auto-y",
			children = examples,
		}),
	})
end

local function labeledValues(shape: ProgressShape, values: { { label: string, value: number } }): { any }
	local children = {}
	for index, example in values do
		children[index] = LabeledProgress({
			label = example.label,
			LayoutOrder = index,
			shape = shape,
			value = example.value,
		})
	end
	return children
end

local function ContentStory()
	local increments = {}
	for index, value in VALUE_INCREMENTS do
		increments[index] = { label = `{value}`, value = value }
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Value",
				contentTag = "col gap-xlarge size-full-0 auto-y",
				children = {
					Subsection({
						LayoutOrder = 1,
						name = "Circle",
						contentTag = "row gap-large auto-xy wrap",
						children = labeledValues(ProgressShape.Circle, increments),
					}),
					Subsection({
						LayoutOrder = 2,
						name = "Bar",
						contentTag = "row gap-large auto-xy wrap",
						children = labeledValues(ProgressShape.Bar, increments),
					}),
				},
			}),
			Section({
				LayoutOrder = 2,
				name = "Clamping values",
				contentTag = "col gap-xlarge size-full-0 auto-y",
				children = {
					Subsection({
						LayoutOrder = 1,
						name = "Circle",
						contentTag = "row gap-large auto-xy wrap",
						children = labeledValues(ProgressShape.Circle, CLAMPING_VALUES),
					}),
					Subsection({
						LayoutOrder = 2,
						name = "Bar",
						contentTag = "row gap-large auto-xy wrap",
						children = labeledValues(ProgressShape.Bar, CLAMPING_VALUES),
					}),
				},
			}),
			Section({
				LayoutOrder = 3,
				name = "Label",
				contentTag = "col gap-xlarge size-full-0 auto-y",
				children = {
					Subsection({
						LayoutOrder = 1,
						name = "Circle",
						note = "Label is only available in Large.",
						contentTag = "auto-xy",
						children = VF.Progress({
							shape = ProgressShape.Circle,
							size = ProgressSize.Large,
							value = DEFAULT_VALUE,
						} :: ProgressCircleProps),
					}),
					Subsection({
						LayoutOrder = 2,
						name = "Bar",
						note = "Min and max labels below the bar, hidden while indeterminate.",
						contentTag = "row gap-xlarge auto-xy wrap",
						children = {
							ProgressContainer({
								shape = ProgressShape.Bar,
								children = VF.Progress({
									shape = ProgressShape.Bar,
									value = DEFAULT_VALUE,
									showLabel = true,
									LayoutOrder = 1,
								}),
							}),
							ProgressContainer({
								shape = ProgressShape.Bar,
								children = VF.Progress({
									shape = ProgressShape.Bar,
									value = DEFAULT_VALUE,
									showLabel = true,
									minValueLabel = "Start",
									maxValueLabel = "End",
									LayoutOrder = 2,
								}),
							}),
						},
					}),
				},
			}),
		},
	})
end

return foundation.sections({
	summary = "Visual feedback for task completion in Bar or Circle shape, with determinate and indeterminate states.",
	controls = {
		shape = UILabs.Choose(PLAYGROUND_SHAPE_OPTIONS),
		size = UILabs.Choose(PLAYGROUND_SIZE_OPTIONS),
		value = DEFAULT_VALUE,
		isIndeterminate = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Variants", story = VariantsStory },
		{
			name = "Sizing",
			story = function()
				return foundation.scroll(SizingStory())
			end,
		},
		{ name = "States", story = StatesStory },
		{ name = "Controlled component", story = ControlledStory },
		{
			name = "Reduced motion",
			summary = "Read from PreferencesProvider, not from props. Only the indeterminate state animates, so determinate progress is unaffected.",
			story = ReducedMotionStory,
		},
		{
			name = "Content",
			story = function()
				return foundation.scroll(ContentStory())
			end,
		},
	},
})
