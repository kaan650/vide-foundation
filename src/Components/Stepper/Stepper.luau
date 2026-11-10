local Vide = require("../../Packages/Vide")

local FillBehavior = require("../../Enums/FillBehavior")
local InputSize = require("../../Enums/InputSize")
local OverflowScrollContainer = require("../OverflowScrollContainer")
local StepItem = require("./StepItem")
local StepperStepState = require("../../Enums/StepperStepState")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local useAnimatedHighlight = require("../../Utility/useAnimatedHighlight")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type FillBehavior = FillBehavior.FillBehavior
type InputSize = InputSize.InputSize
type StepperStepState = StepperStepState.StepperStepState
type ItemId = Types.ItemId
type Value<T> = Types.Value<T>

export type StepperSize = typeof(InputSize.XSmall) | typeof(InputSize.Small) | typeof(InputSize.Medium)

export type Step = {
	id: ItemId,
	label: string,
	description: string?,
}

export type StepperProps = {
	steps: Value<{ Step }>,
	-- Defaults to the first step.
	activeStepId: Value<ItemId?>?,
	size: Value<StepperSize>?,
	-- Fill grows the steps to equal widths across the whole width; Fit gives them their minimum width.
	fillBehavior: Value<FillBehavior>?,
} & Types.CommonProps

local defaultProps = {
	fillBehavior = FillBehavior.Fill,
	size = InputSize.Medium,
	testId = "--foundation-stepper",
	ZIndex = 1,
}

local function getStepState(index: number, activeStepIndex: number, isActive: boolean): StepperStepState
	if isActive then
		return StepperStepState.Current
	elseif index < activeStepIndex then
		return StepperStepState.Complete
	end
	return StepperStepState.Incomplete
end

type Entry = { step: Step, index: number }

--- A row of numbered steps; steps before the active one show a check, and a bar under the active step slides to it.
local function Stepper(stepperProps: StepperProps): GuiObject
	local props = withDefaults(stepperProps, defaultProps)
	local tokens = useTokens()

	local function steps(): { Step }
		return Value.read(props.steps :: Value<{ Step }>)
	end
	local function size(): InputSize
		return Value.read(props.size)
	end
	local function fillBehavior(): FillBehavior
		return Value.read(props.fillBehavior)
	end
	local function isFill(): boolean
		return fillBehavior() == FillBehavior.Fill
	end
	local function activeStepId(): ItemId?
		local active: ItemId? = Value.read(props.activeStepId)
		if active ~= nil then
			return active
		end
		local first = steps()[1]
		return if first then first.id else nil
	end
	local activeStepIndex = Vide.derive(function(): number
		local active = activeStepId()
		for index, step in steps() do
			if step.id == active then
				return index
			end
		end
		return 1
	end)

	local measureInstances = Vide.source({} :: { [ItemId]: GuiObject })
	local containerInstance = Vide.source(nil :: GuiObject?)
	local getContainer: () -> GuiObject? = containerInstance :: any
	local stepListWidth = Vide.source(0)

	local animatedBorder = useAnimatedHighlight(activeStepId, getContainer, measureInstances, function()
		size()
		fillBehavior()
	end)

	local function highlightThickness(): number
		return tokens().Stroke.Standard
	end

	--* Keyed by id like Foundation's steps, so a step keeps its instance and test id when the list changes.
	local entries = Vide.derive(function(): { [ItemId]: Entry }
		local byId: { [ItemId]: Entry } = {}
		for index, step in steps() do
			byId[step.id] = { step = step, index = index }
		end
		return byId
	end)

	local function createStep(entry: () -> Entry, id: ItemId): GuiObject
		local view = StepItem({
			step = function()
				return entry().step
			end,
			index = function()
				return entry().index
			end,
			stepState = function()
				return getStepState(entry().index, activeStepIndex(), activeStepId() == id)
			end,
			size = size,
			fillBehavior = fillBehavior,
			LayoutOrder = function()
				return entry().index
			end,
			measureRef = function(measure: GuiObject)
				local instances = table.clone(Vide.untrack(measureInstances))
				instances[id] = measure
				measureInstances(instances)
				Vide.cleanup(function()
					local remaining = table.clone(Vide.untrack(measureInstances))
					if remaining[id] == measure then
						remaining[id] = nil
						measureInstances(remaining)
					end
				end)
			end,
			testId = `{props.testId}--step-{id}`,
		})
		view.Name = `Step{id}`
		return view
	end

	local stepList = View({
		onAbsoluteSizeChanged = function(instance: GuiObject)
			stepListWidth(instance.AbsoluteSize.X)
		end,
		tag = function()
			return {
				["row flex-y-fill auto-xy"] = true,
				["size-full-0"] = isFill(),
			}
		end,
		testId = `{props.testId}--list`,
		children = Vide.indexes(entries :: () -> { [ItemId]: Entry }, createStep),
	})
	stepList.Name = "StepList"

	local scrollContainer = OverflowScrollContainer({
		LayoutOrder = 1,
		size = size,
		scrimBottomInset = highlightThickness,
		testId = `{props.testId}--scroll-container`,
		children = stepList,
	})
	scrollContainer.Name = "ScrollContainer"

	local border = View({
		LayoutOrder = 2,
		tag = "position-bottom-left anchor-bottom-left",
		Size = function()
			return UDim2.new(1, 0, 0, highlightThickness())
		end,
		backgroundStyle = function()
			return tokens().Color.Stroke.Default :: any
		end,
		testId = `{props.testId}--border`,
	})
	border.Name = "Border"

	local container = View({
		tag = "col size-full-0 auto-y",
		ZIndex = props.ZIndex,
		testId = `{props.testId}--container`,
		children = { scrollContainer, border },
	})
	container.Name = "Stepper"
	containerInstance(container)

	local animatedBorderView = View({
		LayoutOrder = 0,
		ZIndex = function()
			return Value.read(props.ZIndex) + 1
		end,
		tag = "anchor-bottom-left bg-system-contrast",
		Size = function()
			return UDim2.fromOffset(animatedBorder.highlightWidth(), highlightThickness())
		end,
		Position = function()
			return UDim2.fromOffset(animatedBorder.highlightPosition(), animatedBorder.activeItemHeight())
		end,
		testId = `{props.testId}--animated-border`,
	})
	animatedBorderView.Name = "AnimatedBorder"

	return View(withCommonProps(props, {
		tag = "size-full-0 auto-y no-clip",
		sizeConstraint = function(): Types.SizeConstraint?
			if isFill() then
				return nil
			end
			return { MaxSize = Vector2.new(stepListWidth(), math.huge) }
		end,
		children = { container, animatedBorderView },
	}) :: any)
end

return Stepper
