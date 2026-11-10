local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local FillBehavior = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/FillBehavior")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local Types = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Types")

type FillBehavior = FillBehavior.FillBehavior
type Step = VideFoundation.Step
type StepperSize = typeof(InputSize.XSmall) | typeof(InputSize.Small) | typeof(InputSize.Medium)
type ItemId = Types.ItemId
type Value<T> = VideFoundation.Value<T>

local IconName = VF.Enums.IconName

local SIZE_ORDER: { StepperSize } = {
	InputSize.XSmall,
	InputSize.Small,
	InputSize.Medium,
}

local FILL_BEHAVIOR_ORDER: { FillBehavior } = {
	FillBehavior.Fill,
	FillBehavior.Fit,
}

local PLAYGROUND_SIZE_OPTIONS: { StepperSize } = {
	InputSize.Medium,
	InputSize.XSmall,
	InputSize.Small,
}

local STEPPER_WIDTH = 460
local NARROW_STEPPER_WIDTH = 600
local COMPACT_STEPPER_WIDTH = 240
local OVERFLOW_CONTAINER_WIDTH = 500

local STEP_POOL_SIZE = 5

local STEP_POOL: { Step } = {}
for index = 1, STEP_POOL_SIZE do
	table.insert(STEP_POOL, { id = `step-{index}`, label = `Step {index}`, description = "Description" })
end

local LONG_LABEL_STEPS: { Step } = {}
for index = 1, 4 do
	table.insert(LONG_LABEL_STEPS, {
		id = `long-step-{index}`,
		label = `Step {index} with a title far wider than the step`,
		description = "Description that also runs wider than the step",
	})
end

local function takeSteps(count: number): { Step }
	local steps: { Step } = {}
	for index = 1, math.clamp(count, 1, #STEP_POOL) do
		table.insert(steps, STEP_POOL[index])
	end
	return steps
end

local function withoutDescriptions(steps: { Step }): { Step }
	local result: { Step } = {}
	for index, step in steps do
		result[index] = { id = step.id, label = step.label }
	end
	return result
end

local BASE_STEPS = takeSteps(4)
local MINIMAL_STEPS = takeSteps(2)
local OVERFLOW_STEPS = takeSteps(#STEP_POOL)
local SINGLE_STEP = takeSteps(1)

local DEFAULT_ACTIVE_STEP_ID: ItemId = BASE_STEPS[2].id

local THREE_STEPS = takeSteps(3)

local PLAYGROUND_STEP_ID_OPTIONS: { ItemId } = {
	THREE_STEPS[1].id,
	THREE_STEPS[2].id,
	THREE_STEPS[3].id,
}

local MIXED_DESCRIPTION_STEPS: { Step } = {}
for index, step in MINIMAL_STEPS do
	MIXED_DESCRIPTION_STEPS[index] = if index % 2 == 0 then { id = step.id, label = step.label } else step
end

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
				tag = props.contentTag or "col gap-large align-x-left auto-xy",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

type StepperExampleProps = {
	LayoutOrder: number?,
	steps: Value<{ Step }>?,
	activeStepId: Value<ItemId?>?,
	size: Value<StepperSize>?,
	fillBehavior: Value<FillBehavior>?,
	hasParentSurface: boolean?,
	width: number?,
}

--* Stepper's scroll container anchors its scrims to the nearest clipping ancestor, falling back to the whole page,
--* and Stepper's own root opts out with `no-clip`. Without this wrapper, overflowing steps paint across the page.
local function ClippedStepper(props: StepperExampleProps)
	return VF.View({
		tag = "size-full-0 auto-y",
		ClipsDescendants = true,
		LayoutOrder = props.LayoutOrder,
		children = VF.Stepper({
			steps = props.steps or BASE_STEPS,
			activeStepId = props.activeStepId or DEFAULT_ACTIVE_STEP_ID,
			size = props.size,
			fillBehavior = props.fillBehavior,
		}),
	})
end

-- hasParentSurface paints the frame so the width the stepper lays itself out against is visible.
local function StepperFrame(props: StepperExampleProps)
	return VF.View({
		tag = if props.hasParentSurface
			then "size-full-0 auto-y padding-large radius-medium bg-surface-100"
			else "size-full-0 auto-y",
		Size = UDim2.fromOffset(props.width or STEPPER_WIDTH, 0),
		LayoutOrder = props.LayoutOrder,
		children = ClippedStepper({
			steps = props.steps,
			activeStepId = props.activeStepId,
			size = props.size,
			fillBehavior = props.fillBehavior,
		}),
	})
end

local function LabeledStepper(props: StepperExampleProps & { label: string })
	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			StepperFrame({
				LayoutOrder = 2,
				steps = props.steps,
				activeStepId = props.activeStepId,
				size = props.size,
				fillBehavior = props.fillBehavior,
				hasParentSurface = props.hasParentSurface,
				width = props.width,
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local function steps(): { Step }
		return if controls.hasDescriptions() then THREE_STEPS else withoutDescriptions(THREE_STEPS)
	end

	return VF.View({
		tag = "col gap-medium size-full-0 auto-y padding-large bg-surface-0",
		children = ClippedStepper({
			LayoutOrder = 1,
			steps = steps,
			activeStepId = function(): ItemId?
				--* UI Labs remembers control values, so a stale id can outlive the step it named.
				local activeStepId: ItemId = controls.activeStepId()
				local isPresent = Dash.findIndex(steps(), function(step: Step)
					return step.id == activeStepId
				end) ~= nil
				return if isPresent then activeStepId else PLAYGROUND_STEP_ID_OPTIONS[1]
			end,
			size = controls.size,
			fillBehavior = controls.fillBehavior,
		}),
	})
end

local function SizingStory()
	local sizes = {}
	for index, size in SIZE_ORDER do
		sizes[index] = LabeledStepper({
			label = size,
			LayoutOrder = index,
			steps = SINGLE_STEP,
			activeStepId = SINGLE_STEP[1].id,
			size = size,
			fillBehavior = FillBehavior.Fit,
			width = COMPACT_STEPPER_WIDTH,
		})
	end

	--* Two steps leave enough slack in the frame for Fill to stretch where Fit does not.
	local fillBehaviors = {}
	for index, fillBehavior in FILL_BEHAVIOR_ORDER do
		fillBehaviors[index] = LabeledStepper({
			label = `fillBehavior = {fillBehavior}`,
			LayoutOrder = index,
			steps = MINIMAL_STEPS,
			activeStepId = MINIMAL_STEPS[2].id,
			fillBehavior = fillBehavior,
			hasParentSurface = true,
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Size",
				contentTag = "row wrap align-y-top gap-xlarge size-full-0 auto-y",
				children = sizes,
			}),
			Section({
				LayoutOrder = 2,
				name = "Fill behavior",
				children = fillBehaviors,
			}),
		},
	})
end

local function StatesStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "Step states",
			children = {
				LabeledStepper({
					LayoutOrder = 1,
					label = "Current — the active step",
					steps = SINGLE_STEP,
					activeStepId = SINGLE_STEP[1].id,
					fillBehavior = FillBehavior.Fit,
				}),
				LabeledStepper({
					LayoutOrder = 2,
					label = "Complete — Step 1, with Step 2 active",
					steps = MINIMAL_STEPS,
					activeStepId = MINIMAL_STEPS[2].id,
					fillBehavior = FillBehavior.Fit,
				}),
				LabeledStepper({
					LayoutOrder = 3,
					label = "Incomplete — Step 2, with Step 1 active",
					steps = MINIMAL_STEPS,
					activeStepId = MINIMAL_STEPS[1].id,
					fillBehavior = FillBehavior.Fit,
				}),
			},
		}),
	})
end

local function ControlledStepperExample(props: {
	LayoutOrder: number,
	steps: { Step },
	fillBehavior: FillBehavior?,
	hasParentSurface: boolean?,
	width: number?,
})
	local steps = props.steps
	local activeStepId = Vide.source(steps[1].id :: ItemId)

	local function activeStepIndex(): number
		local current = activeStepId()
		return Dash.findIndex(steps, function(step: Step)
			return step.id == current
		end) or 1
	end

	return VF.View({
		tag = "col align-x-left gap-medium auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.View({
				LayoutOrder = 1,
				tag = "row align-y-center gap-small auto-xy",
				children = {
					VF.IconButton({
						LayoutOrder = 1,
						icon = IconName.ChevronSmallLeft,
						size = InputSize.Small,
						isDisabled = function()
							return activeStepIndex() <= 1
						end,
						onActivated = function()
							local previousStep = steps[activeStepIndex() - 1]
							if previousStep then
								activeStepId(previousStep.id)
							end
						end,
					}),
					VF.IconButton({
						LayoutOrder = 2,
						icon = IconName.ChevronSmallRight,
						size = InputSize.Small,
						isDisabled = function()
							return activeStepIndex() >= #steps
						end,
						onActivated = function()
							local nextStep = steps[activeStepIndex() + 1]
							if nextStep then
								activeStepId(nextStep.id)
							end
						end,
					}),
					VF.Text({
						LayoutOrder = 3,
						Text = function()
							return `activeStepId = "{activeStepId()}"`
						end,
						tag = "auto-xy text-body-small text-align-x-left content-muted",
					}),
				},
			}),
			StepperFrame({
				LayoutOrder = 2,
				steps = steps,
				activeStepId = activeStepId,
				fillBehavior = props.fillBehavior,
				hasParentSurface = props.hasParentSurface,
				width = props.width,
			}),
		},
	})
end

local function ControlledStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Stepping through a flow",
				children = ControlledStepperExample({
					LayoutOrder = 1,
					steps = THREE_STEPS,
				}),
			}),
			Section({
				LayoutOrder = 2,
				name = "Overflow",
				--* Fit lets the steps outgrow the frame: under Fill they are scale-sized, which never adds to the scroll
				--* canvas, so the scrims would never engage.
				children = ControlledStepperExample({
					LayoutOrder = 1,
					steps = OVERFLOW_STEPS,
					fillBehavior = FillBehavior.Fit,
					hasParentSurface = true,
					width = OVERFLOW_CONTAINER_WIDTH,
				}),
			}),
		},
	})
end

local function ContentStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Descriptions",
				children = {
					LabeledStepper({
						LayoutOrder = 1,
						label = "Label only",
						steps = withoutDescriptions(MINIMAL_STEPS),
					}),
					LabeledStepper({
						LayoutOrder = 2,
						label = "Label and description",
						steps = MINIMAL_STEPS,
					}),
					LabeledStepper({
						LayoutOrder = 3,
						label = "Mixed — description on some steps only",
						steps = MIXED_DESCRIPTION_STEPS,
					}),
				},
			}),
			Section({
				LayoutOrder = 2,
				name = "Long text",
				children = {
					LabeledStepper({
						LayoutOrder = 1,
						label = `fillBehavior = {FillBehavior.Fill}`,
						steps = LONG_LABEL_STEPS,
						activeStepId = LONG_LABEL_STEPS[2].id,
						fillBehavior = FillBehavior.Fill,
						width = NARROW_STEPPER_WIDTH,
					}),
					LabeledStepper({
						LayoutOrder = 2,
						label = `fillBehavior = {FillBehavior.Fit}`,
						steps = LONG_LABEL_STEPS,
						activeStepId = LONG_LABEL_STEPS[2].id,
						fillBehavior = FillBehavior.Fit,
						width = NARROW_STEPPER_WIDTH,
					}),
				},
			}),
		},
	})
end

return foundation.sections({
	summary = "Stepper displays a horizontal sequence of steps with a leading indicator, a label, and an optional description. The bottom border highlights the current step and animates between steps.",
	controls = {
		activeStepId = UILabs.Choose(PLAYGROUND_STEP_ID_OPTIONS),
		size = UILabs.Choose(PLAYGROUND_SIZE_OPTIONS),
		fillBehavior = UILabs.Choose(FILL_BEHAVIOR_ORDER),
		hasDescriptions = true,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizing", story = SizingStory },
		{ name = "States", story = StatesStory },
		{ name = "Controlled component", story = ControlledStory },
		{ name = "Content", story = ContentStory },
	},
})
