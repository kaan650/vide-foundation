local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")
local IconName = BuilderIcons.Icon
local IconVariant = BuilderIcons.IconVariant

local FillBehavior = require("../../Enums/FillBehavior")
local Icon = require("../Icon")
local InputSize = require("../../Enums/InputSize")
local StepperStepState = require("../../Enums/StepperStepState")
local Text = require("../Text")
local Types = require("../Types")
local View = require("../View")
local useStepperVariants = require("./useStepperVariants")
local useTokens = require("../../Providers/Style/useTokens")

type FillBehavior = FillBehavior.FillBehavior
type InputSize = InputSize.InputSize
type StepperStepState = StepperStepState.StepperStepState
type ItemId = Types.ItemId

export type StepItemStep = {
	id: ItemId,
	label: string,
	description: string?,
}

type StepItemProps = {
	step: () -> StepItemStep,
	index: () -> number,
	stepState: () -> StepperStepState,
	size: () -> InputSize,
	fillBehavior: () -> FillBehavior,
	-- Receives the view the active-step highlight measures.
	measureRef: (GuiObject) -> (),
	testId: string,
	LayoutOrder: () -> number,
}

local function StepItem(props: StepItemProps): GuiObject
	local tokens = useTokens()
	local variant = Vide.derive(function()
		return useStepperVariants(
			tokens(),
			props.size(),
			props.stepState(),
			props.fillBehavior() == FillBehavior.Fill
		)
	end)

	local measure = View({
		LayoutOrder = 1,
		tag = "size-full",
	})
	measure.Name = "Measure"
	props.measureRef(measure)

	local stepIndex = Vide.switch(function()
		return props.stepState() == StepperStepState.Complete
	end)({
		[true] = function()
			local icon = Icon({
				name = IconName.Check,
				style = function()
					return tokens().Inverse.Content.Emphasis :: any
				end,
				size = function()
					return variant().icon.size
				end,
				variant = IconVariant.Filled,
				testId = `{props.testId}--check`,
			})
			icon.Name = "StepIndex"
			return icon
		end,
		[false] = function()
			local text = Text({
				Text = function()
					return tostring(props.index())
				end,
				tag = function()
					return variant().index.tag
				end,
				testId = `{props.testId}--index`,
			})
			text.Name = "StepIndex"
			return text
		end,
	})

	local indicator = View({
		tag = function()
			return variant().indicatorInner.tag
		end,
		testId = `{props.testId}--indicator`,
		children = stepIndex,
	})
	indicator.Name = "Indicator"

	local indicatorOuter = View({
		LayoutOrder = 1,
		tag = function()
			return variant().indicatorOuter.tag
		end,
		testId = `{props.testId}--indicator-outer`,
		children = indicator,
	})
	indicatorOuter.Name = "IndicatorOuter"

	local label = Text({
		LayoutOrder = 1,
		Text = function()
			return props.step().label
		end,
		tag = function()
			return variant().label.tag
		end,
		testId = `{props.testId}--label`,
	})
	label.Name = "Label"

	local getDescription: () -> string? = function()
		return props.step().description
	end
	local description = Vide.show(getDescription, function(text: () -> string)
		local view = Text({
			LayoutOrder = 2,
			Text = text,
			tag = function()
				return variant().description.tag
			end,
			testId = `{props.testId}--description`,
		})
		view.Name = "Description"
		return view
	end)

	local textColumn = View({
		LayoutOrder = 2,
		tag = function()
			return variant().textColumn.tag
		end,
		padding = {
			left = function()
				local padding = variant().textColumn.padding
				return if padding and padding.left then padding.left else UDim.new(0, 0)
			end,
		} :: any,
		testId = `{props.testId}--text-column`,
		children = { label, description },
	})
	textColumn.Name = "TextColumn"

	local function contentPadding(side: "top" | "bottom" | "left" | "right"): () -> UDim
		return function()
			local padding = variant().content.padding
			return if padding then (padding :: any)[side] or UDim.new(0, 0) else UDim.new(0, 0)
		end
	end
	local content = View({
		LayoutOrder = 2,
		tag = function()
			return variant().content.tag
		end,
		padding = {
			top = contentPadding("top"),
			bottom = contentPadding("bottom"),
			left = contentPadding("left"),
			right = contentPadding("right"),
		} :: any,
		testId = `{props.testId}--content`,
		children = { indicatorOuter, textColumn },
	})
	content.Name = "Content"

	return View({
		tag = function()
			return variant().container.tag
		end,
		testId = props.testId,
		LayoutOrder = props.LayoutOrder,
		children = { measure, content },
	})
end

return StepItem
