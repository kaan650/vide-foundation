local foundation = require("../foundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local IconSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/IconSize")
local InputPlacement = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputPlacement")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")

type InputPlacement = InputPlacement.InputPlacement
type InputGroupSize = "XSmall" | "Small" | "Medium"

local IconName = VF.Enums.IconName
local RadioGroup = VF.RadioGroup

local VALUES = { "A", "B", "C", "D", "E" }
local SIZES: { InputGroupSize } = { InputSize.XSmall, InputSize.Small, InputSize.Medium }

local function printValue(value: string)
	print("Checking value", value)
end

local function BasicStory(controls: { [string]: any })
	local function items()
		local children = {}
		for index, value in VALUES do
			children[index] = RadioGroup.Item({
				value = value,
				label = function()
					local optionLabel: string = controls.optionLabel()
					return if #optionLabel > 0 then `{optionLabel} {value}` else ""
				end,
				isDisabled = if value == "D" then true else controls.isDisabled,
				LayoutOrder = index,
			})
		end
		return children
	end

	--* The group takes size and placement as plain values, so a change builds it again.
	return foundation.rebuildOn(function()
		return `{controls.size()}/{controls.placement()}`
	end, function()
		return RadioGroup.Root({
			legend = controls.legend,
			size = controls.size(),
			placement = controls.placement(),
			onValueChanged = printValue,
			children = items,
		})
	end)
end

local function DifferentLabelLengthsStory(controls: { [string]: any })
	local itemsData = {
		{ value = "A", label = "Short" },
		{ value = "B", label = "Medium length label" },
		{ value = "C", label = "A much, much longer label to test wrapping and layout in the radio group" },
		{ value = "D", label = "Tiny" },
		{
			value = "E",
			label = "Extremely long label that spans multiple lines to ensure alignment across items with a label on the left",
		},
	}

	return VF.View({
		tag = "auto-y",
		Size = UDim2.fromOffset(400, 0),
		children = RadioGroup.Root({
			onValueChanged = printValue,
			children = function()
				local children = {}
				for index, item in itemsData do
					children[index] = RadioGroup.Item({
						value = item.value,
						label = item.label,
						size = controls.size,
						placement = controls.placement,
						LayoutOrder = index,
					})
				end
				return children
			end,
		}),
	})
end

local function SizesStory()
	local groups = {}
	for sizeIndex, size in SIZES do
		groups[sizeIndex] = RadioGroup.Root({
			legend = size,
			size = size,
			LayoutOrder = sizeIndex,
			onValueChanged = printValue,
			children = function()
				local children = {}
				for index, value in VALUES do
					children[index] = RadioGroup.Item({
						value = value,
						label = value,
						LayoutOrder = index,
					})
				end
				return children
			end,
		})
	end

	return VF.View({
		tag = "row wrap align-y-center gap-xlarge auto-xy",
		children = groups,
	})
end

local function SelectionCard(props: {
	controls: { [string]: any },
	value: string,
	icon: string,
	label: string,
	cursor: () -> any,
	setSelectedValue: (string) -> (),
	LayoutOrder: number,
})
	return VF.View({
		tag = "col align-x-center gap-small auto-xy padding-medium",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.View({
				cursor = props.cursor,
				onActivated = function()
					props.setSelectedValue(props.value)
					print("Selected card:", props.value)
				end,
				tag = "col align-x-center align-y-center size-2000-2000 radius-medium bg-surface-100",
				LayoutOrder = 1,
				children = VF.Icon({
					name = props.icon,
					size = IconSize.XLarge,
				}),
			}),
			RadioGroup.Item({
				value = props.value,
				label = props.label,
				placement = props.controls.placement,
				LayoutOrder = 2,
			}),
		},
	})
end

local function CustomSelectionStory(controls: { [string]: any })
	local selectedValue = Vide.source(nil :: string?)
	local getSelectedValue: () -> string? = selectedValue :: any
	local tokens = VF.Hooks.useTokens()

	local function cursor()
		return {
			radius = UDim.new(0, tokens().Radius.Medium),
			offset = tokens().Size.Size_150,
			borderWidth = tokens().Stroke.Thicker,
		}
	end

	local function setSelectedValue(value: string)
		selectedValue(value)
	end

	local cards = {
		{ value = "A", icon = IconName.CircleCheck, label = "Success" },
		{ value = "B", icon = IconName.TriangleExclamation, label = "Error" },
		{ value = "C", icon = IconName.CircleI, label = "Info" },
	}

	return RadioGroup.Root({
		value = getSelectedValue,
		onValueChanged = setSelectedValue,
		-- Make the group non-selectable since individual items handle their own selection
		Selectable = false,
		children = function()
			local children = {}
			for index, card in cards do
				children[index] = SelectionCard({
					controls = controls,
					value = card.value,
					icon = card.icon,
					label = card.label,
					cursor = cursor,
					setSelectedValue = setSelectedValue,
					LayoutOrder = index,
				})
			end
			return VF.View({
				tag = "row wrap gap-large auto-xy",
				children = children,
			})
		end,
	})
end

return foundation.sections({
	summary = "Radio Group component",
	controls = {
		legend = "Choose an option",
		optionLabel = "Option",
		size = UILabs.Choose(SIZES),
		placement = UILabs.Choose(Dash.values(InputPlacement :: any)),
		isDisabled = false,
	},
	sections = {
		{ name = "Playground", story = BasicStory },
		{ name = "Sizes", summary = "Each size shown in a row", story = SizesStory },
		{
			name = "Different Label Lengths",
			summary = "Items with labels of varying length",
			story = DifferentLabelLengthsStory,
		},
		{
			name = "Custom Selection",
			summary = "Select images instead of radio buttons",
			story = CustomSelectionStory,
		},
	},
})
