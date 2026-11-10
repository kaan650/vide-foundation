local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local InputPlacement = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputPlacement")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")

type InputPlacement = InputPlacement.InputPlacement
type InputSize = InputSize.InputSize
type Value<T> = VideFoundation.Value<T>

local SIZES: { InputSize } = { InputSize.XSmall, InputSize.Small, InputSize.Medium, InputSize.Large }
local PLACEMENTS: { InputPlacement } = Dash.values(InputPlacement :: any)

local function activated(label: string)
	return function()
		print(`Toggle: "{label}" activated`)
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

local function ToggleCard(props: {
	label: string,
	description: string,
	isChecked: Value<boolean>,
	onToggle: (...any) -> (),
	cursor: Value<any>,
	LayoutOrder: number,
})
	return VF.View({
		cursor = props.cursor,
		onActivated = props.onToggle,
		tag = "col gap-medium padding-large stroke-muted radius-medium bg-surface-100",
		Size = UDim2.fromOffset(320, 100),
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.View({
				tag = "row flex-x-between gap-small size-full-0 auto-y",
				LayoutOrder = 1,
				children = {
					VF.Text({
						Text = props.label,
						tag = "auto-xy text-body-medium content-emphasis",
						LayoutOrder = 1,
					}),
					VF.Toggle({
						isChecked = props.isChecked,
						onActivated = props.onToggle,
						label = "",
						Selectable = false,
						LayoutOrder = 2,
					}),
				},
			}),
			VF.Text({
				Text = props.description,
				tag = "auto-xy text-body-small text-wrap content-muted",
				LayoutOrder = 2,
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local isChecked = Vide.source(false)

	return VF.Toggle({
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
			children = VF.Toggle({
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
			contentTag = "size-3000-0 auto-y",
			LayoutOrder = index,
			children = VF.Toggle({
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

local function IsDisabledStory()
	local groups = {}
	for index, option in { { caption = "False", isDisabled = false }, { caption = "True", isDisabled = true } } do
		groups[index] = Group({
			caption = option.caption,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = VF.Toggle({
				isChecked = true,
				onActivated = activated("IsDisabled " .. option.caption),
				isDisabled = option.isDisabled,
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

local function CustomSelectionStory()
	local isChatEnabled = Vide.source(false)
	local isNotifications = Vide.source(true)
	local tokens = VF.Hooks.useTokens()

	local function cursor()
		return {
			radius = UDim.new(0, tokens().Radius.Medium),
			offset = tokens().Size.Size_150,
			borderWidth = tokens().Stroke.Thicker,
		}
	end

	return VF.View({
		tag = "col gap-large auto-xy",
		--* React's cards are keyed with no LayoutOrder and render Chat first.
		children = {
			ToggleCard({
				label = "Push Notifications",
				description = "Receive notifications for messages and updates",
				isChecked = isNotifications,
				onToggle = function()
					isNotifications(not isNotifications())
				end,
				cursor = cursor,
				LayoutOrder = 2,
			}),
			ToggleCard({
				label = "Chat",
				description = "Enable chat for real-time communication",
				isChecked = isChatEnabled,
				onToggle = function()
					isChatEnabled(not isChatEnabled())
				end,
				cursor = cursor,
				LayoutOrder = 1,
			}),
		},
	})
end

local function UncontrolledStory()
	return VF.Toggle({
		onActivated = function(value: boolean)
			print("isChecked: ", value)
		end,
		size = InputSize.Medium,
		label = "Label",
		placement = InputPlacement.Start,
	})
end

return foundation.sections({
	summary = "Toggle component",
	controls = {
		isDisabled = false,
		label = "Label",
		hint = "",
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		placement = UILabs.Choose(PLACEMENTS),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizes", summary = "Toggle rendered at every supported size", story = SizesStory },
		{ name = "Placement", summary = "Toggle placement options", story = PlacementStory },
		{ name = "IsDisabled", story = IsDisabledStory },
		{
			name = "Custom Selection",
			summary = "Select card containers instead of toggles",
			story = CustomSelectionStory,
		},
		{
			name = "Uncontrolled",
			summary = "State is controlled by the toggle itself",
			story = UncontrolledStory,
		},
	},
})
