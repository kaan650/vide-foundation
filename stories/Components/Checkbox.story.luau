local foundation = require("../foundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local InputPlacement = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputPlacement")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")

type InputPlacement = InputPlacement.InputPlacement
type InputSize = InputSize.InputSize

local SIZES: { InputSize } = { InputSize.XSmall, InputSize.Small, InputSize.Medium, InputSize.Large }
local PLACEMENTS: { InputPlacement } = Dash.values(InputPlacement :: any)

local function activated(label: string)
	return function()
		print(`Checkbox: "{label}" activated`)
	end
end

local function Group(props: { caption: string, contentTag: string, LayoutOrder: number?, children: any })
	return VF.View({
		tag = "col gap-medium auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.caption,
				tag = "auto-xy text-body-small content-default",
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

local function PlaygroundStory(controls: { [string]: any })
	local isChecked = Vide.source(true)

	return VF.Checkbox({
		isChecked = isChecked,
		isDisabled = controls.isDisabled,
		onActivated = function()
			isChecked(not isChecked())
		end,
		size = controls.size,
		label = controls.label,
		hint = controls.hint,
		placement = controls.placement,
	})
end

local function SizesStory()
	local checkedBySize = Vide.source({
		[InputSize.XSmall] = true,
		[InputSize.Small] = true,
		[InputSize.Medium] = true,
		[InputSize.Large] = true,
	})

	local groups = {}
	for index, size in SIZES do
		groups[index] = Group({
			caption = size,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = VF.Checkbox({
				isChecked = function()
					return checkedBySize()[size]
				end,
				onActivated = function()
					local updated = table.clone(checkedBySize())
					updated[size] = not updated[size]
					checkedBySize(updated)
				end,
				size = size,
				label = "Label",
				placement = InputPlacement.Start,
			}),
		})
	end

	return VF.View({
		tag = "col gap-xxlarge auto-xy",
		children = groups,
	})
end

local function PlacementStory()
	local groups = {}
	for index, placement in PLACEMENTS do
		groups[index] = Group({
			caption = placement,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = VF.Checkbox({
				isChecked = true,
				onActivated = activated(placement),
				size = InputSize.Medium,
				label = "Label",
				placement = placement,
			}),
		})
	end

	return VF.View({
		tag = "row gap-xxlarge auto-xy",
		children = groups,
	})
end

local function OptionsStory(
	options: { { caption: string, isDisabled: boolean?, isIndeterminate: boolean? } },
	name: string
)
	local groups = {}
	for index, option in options do
		groups[index] = Group({
			caption = option.caption,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = VF.Checkbox({
				isChecked = true,
				onActivated = activated(`{name} {option.caption}`),
				isDisabled = option.isDisabled,
				isIndeterminate = option.isIndeterminate,
				size = InputSize.Medium,
				label = "Label",
				placement = InputPlacement.Start,
			}),
		})
	end

	return VF.View({
		tag = "row gap-xxlarge auto-xy",
		children = groups,
	})
end

local function IndeterminateAggregationStory()
	local isChecked1 = Vide.source(false)
	local isChecked2 = Vide.source(false)
	local isChecked3 = Vide.source(true)

	local function Item(label: string, isChecked: typeof(isChecked1), layoutOrder: number)
		return VF.Checkbox({
			LayoutOrder = layoutOrder,
			isChecked = isChecked,
			onActivated = function(value: boolean)
				isChecked(value)
			end,
			size = InputSize.Medium,
			label = label,
			placement = InputPlacement.Start,
		})
	end

	local children = {
		VF.Checkbox({
			LayoutOrder = 1,
			isChecked = function()
				return isChecked1() or isChecked2() or isChecked3()
			end,
			isIndeterminate = function()
				return isChecked1() ~= isChecked2() or isChecked2() ~= isChecked3()
			end,
			onActivated = function(value: boolean)
				Vide.batch(function()
					isChecked1(value)
					isChecked2(value)
					isChecked3(value)
				end)
			end,
			size = InputSize.Medium,
			label = "",
			placement = InputPlacement.Start,
		}),
		Item("Item 1", isChecked1, 2),
		Item("Item 2", isChecked2, 3),
		Item("Item 3", isChecked3, 4),
	}

	return VF.View({
		tag = "col gap-medium size-3000-0 auto-xy",
		children = children,
	})
end

local function CustomSelectionStory()
	local isChecked = Vide.source(true)
	local tokens = VF.Hooks.useTokens()

	local function toggle()
		isChecked(not isChecked())
	end

	return VF.View({
		cursor = function()
			return {
				radius = UDim.new(0, tokens().Radius.Medium),
				offset = tokens().Size.Size_150,
				borderWidth = tokens().Stroke.Thicker,
			}
		end,
		onActivated = toggle,
		tag = "col align-x-center align-y-center gap-medium auto-y padding-large stroke-muted radius-medium bg-surface-100",
		Size = UDim2.fromOffset(300, 120),
		children = {
			VF.Checkbox({
				isChecked = isChecked,
				onActivated = toggle,
				size = InputSize.Medium,
				label = "Enable notifications",
				placement = InputPlacement.Start,
				Selectable = false,
				LayoutOrder = 1,
			}),
			VF.Text({
				Text = "Get notified when someone mentions you or sends you a message",
				tag = "size-full-0 auto-y text-body-small text-wrap content-muted",
				LayoutOrder = 2,
			}),
		},
	})
end

local function UncontrolledStory()
	return VF.Checkbox({
		onActivated = function(value: boolean)
			print("isChecked: ", value)
		end,
		size = InputSize.Medium,
		label = "Label",
		placement = InputPlacement.Start,
	})
end

return foundation.sections({
	summary = "Checkbox component",
	controls = {
		isDisabled = false,
		label = "Label",
		hint = "",
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		placement = UILabs.Choose(PLACEMENTS),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizes", summary = "Checkbox rendered at every supported size", story = SizesStory },
		{ name = "Placement", summary = "Checkbox placement options", story = PlacementStory },
		{
			name = "IsDisabled",
			story = function()
				return OptionsStory({
					{ caption = "False", isDisabled = false },
					{ caption = "True", isDisabled = true },
				}, "IsDisabled")
			end,
		},
		{
			name = "IsIndeterminate",
			story = function()
				return OptionsStory({
					{ caption = "False", isIndeterminate = false },
					{ caption = "True", isIndeterminate = true },
				}, "IsIndeterminate")
			end,
		},
		{
			name = "Indeterminate Aggregation",
			summary = "A checkbox with an indeterminate state aggregating other checkboxes",
			story = IndeterminateAggregationStory,
		},
		{
			name = "Custom Selection",
			summary = "Select card container instead of checkbox",
			story = CustomSelectionStory,
		},
		{
			name = "Uncontrolled",
			summary = "State is controlled by the checkbox itself",
			story = UncontrolledStory,
		},
	},
})
