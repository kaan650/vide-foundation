local foundation = require("../foundation")
local StoryIcons = require("../Shared/StoryIcons")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local AccessoryType = VF.Enums.AccessoryType
local IconSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/IconSize")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local ListItemInputType = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ListItemInputType")

type InputSize = InputSize.InputSize
type IconSize = IconSize.IconSize
type ListItemInputType = ListItemInputType.ListItemInputType

local IconName = VF.Enums.IconName
local List = VF.List

local INPUT_SIZE_TO_ICON_SIZE: { [InputSize]: IconSize } = {
	[InputSize.XSmall] = IconSize.XSmall,
	[InputSize.Small] = IconSize.Small,
	[InputSize.Medium] = IconSize.Medium,
	[InputSize.Large] = IconSize.Large,
}

--! The List API takes a thumbnail as a string, so it stays an rbxthumb URI.
local MEDIA_LEADING: any = { iconName = "rbxthumb://type=GameIcon&id=1818&w=150&h=150" }

local function CheckAccessory(size: () -> InputSize)
	return VF.Icon({
		name = IconName.Check,
		size = function()
			return INPUT_SIZE_TO_ICON_SIZE[size()]
		end,
	})
end

local LEADING_OPTIONS: { string } = {}
for _, example in StoryIcons.ICON_TYPE_EXAMPLES do
	table.insert(LEADING_OPTIONS, example.name)
end
table.insert(LEADING_OPTIONS, AccessoryType.Avatar)
table.insert(LEADING_OPTIONS, AccessoryType.Media)
table.insert(LEADING_OPTIONS, foundation.NONE)

local SIZE_ORDER: { InputSize } = {
	InputSize.Small,
	InputSize.Medium,
	InputSize.Large,
}

local INPUT_TYPE_EXAMPLES: { { title: string, description: string, inputType: ListItemInputType? } } = {
	{ title = "Chevron", description = "Default trailing accessory for a tappable row", inputType = nil },
	{ title = "Checkbox", description = "Toggles a checkbox", inputType = ListItemInputType.Checkbox },
	{ title = "Toggle", description = "Toggles a switch", inputType = ListItemInputType.Toggle },
	{ title = "Radio", description = "Selects a radio input", inputType = ListItemInputType.Radio },
	{ title = "None", description = "No input accessory", inputType = ListItemInputType.None },
}

local SELECTION_OPTIONS = { "Private", "Friends", "Public" }

--- An onActivated handler that logs, so it's obvious in the output when a row is activated.
local function logActivated(label: string)
	return function()
		print(`ListItem activated: {label}`)
	end
end

local function resolveLeading(leading: string): any
	if leading == AccessoryType.Avatar then
		return { type = AccessoryType.Avatar, userId = 24813339 }
	elseif leading == AccessoryType.Media then
		return MEDIA_LEADING
	elseif leading ~= foundation.NONE then
		return leading
	end
	return nil
end

local function nonEmpty(text: string): string?
	return if text == "" then nil else text
end

local function InputTypeItem(props: {
	LayoutOrder: number,
	title: string,
	description: string?,
	inputType: ListItemInputType?,
})
	local isChecked = Vide.source(false)

	return List.Item({
		title = props.title,
		description = props.description,
		LayoutOrder = props.LayoutOrder,
		onActivated = function()
			print(`ListItem activated: {props.title}`)
			isChecked(not isChecked())
		end,
		--* The Chevron example passes no `input`: a tappable row defaults to a chevron.
		input = if props.inputType then { type = props.inputType :: any, isChecked = isChecked } else nil,
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local isChecked = Vide.source(false)

	--* Starts at the control and follows it; the row toggles it in between.
	Vide.effect(function()
		local value = controls.isChecked()
		Vide.untrack(function()
			isChecked(value)
		end)
	end)

	return List.Root({
		size = controls.size,
		children = function()
			--* `onActivated` takes a plain function, so the control builds the row again.
			return foundation.rebuildOn(controls.onActivated, function(hasHandler: boolean)
				return List.Item({
					leading = function()
						return resolveLeading(controls.leading())
					end,
					title = function()
						return {
							title = nonEmpty(controls.title()),
							metadata = nonEmpty(controls.metadata()),
						}
					end,
					description = function()
						return nonEmpty(controls.description())
					end,
					LayoutOrder = 1,
					--* The main use case: the whole item is tappable. The trailing accessory comes from `inputType`
					--* and shows the checked state; tapping the row (or its input) runs `onActivated`.
					onActivated = if hasHandler
						then function()
							print("ListItem activated")
							isChecked(not isChecked())
						end
						else nil,
					input = function(): any
						local inputType = controls.inputType()
						return if inputType ~= "" then { type = inputType, isChecked = isChecked } else nil
					end,
				})
			end)
		end,
	})
end

local function InputTypesStory(controls: { [string]: any })
	return List.Root({
		size = controls.size,
		children = function()
			local items = {}
			for index, example in INPUT_TYPE_EXAMPLES do
				items[index] = InputTypeItem({
					LayoutOrder = index,
					title = example.title,
					description = example.description,
					inputType = example.inputType,
				})
			end
			return items
		end,
	})
end

local function SelectionStory(controls: { [string]: any })
	local selected = Vide.source(SELECTION_OPTIONS[1])

	return List.Root({
		size = controls.size,
		children = function()
			local items = {}
			for index, option in SELECTION_OPTIONS do
				--* Only the selected row has trailing content, so a new selection builds the row again.
				items[index] = foundation.rebuildOn(function()
					return selected() == option
				end, function(isSelected: boolean)
					--* Tapping the row selects it; the selected row shows a Check as a clickable trailing accessory
					--* (the whole row is activatable, with no chevron).
					return List.Item({
						title = option,
						LayoutOrder = index,
						onActivated = function()
							print(`ListItem selected: {option}`)
							selected(option)
						end,
						input = ListItemInputType.None,
						trailing = if isSelected then CheckAccessory(controls.size) else nil,
					})
				end)
			end
			return items
		end,
	})
end

local function LeadingAccessoriesStory(controls: { [string]: any })
	return List.Root({
		size = controls.size,
		children = function()
			local items = {}
			for index, iconExample in StoryIcons.ICON_TYPE_EXAMPLES do
				items[index] = List.Item({
					leading = iconExample.name,
					title = iconExample.title,
					description = iconExample.subtitle,
					onActivated = logActivated(iconExample.title),
					input = ListItemInputType.Chevron,
					LayoutOrder = index,
				})
			end

			local count = #items
			table.insert(
				items,
				List.Item({
					leading = { type = AccessoryType.Avatar, userId = 24813339 },
					title = "Avatar accessory",
					description = "leading = { type = Avatar, userId }",
					onActivated = logActivated("Avatar accessory"),
					input = ListItemInputType.Chevron,
					LayoutOrder = count + 1,
				})
			)
			table.insert(
				items,
				List.Item({
					leading = MEDIA_LEADING,
					title = "Media accessory",
					description = "leading = { iconName = rbxthumb://... }",
					onActivated = logActivated("Media accessory"),
					input = ListItemInputType.Chevron,
					LayoutOrder = count + 2,
				})
			)
			table.insert(
				items,
				List.Item({
					title = "No leading",
					description = "leading = nil",
					onActivated = logActivated("No leading"),
					input = ListItemInputType.Chevron,
					LayoutOrder = count + 3,
				})
			)
			return items
		end,
	})
end

local function SizeSection(props: { LayoutOrder: number, size: InputSize })
	return VF.View({
		tag = "col gap-small size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.size,
				tag = "auto-xy text-label-medium content-default",
				LayoutOrder = 1,
			}),
			List.Root({
				size = props.size,
				LayoutOrder = 2,
				--* One representative row: the leading accessory, text and trailing accessory all scale together.
				children = function()
					return List.Item({
						leading = MEDIA_LEADING,
						title = { title = "List item", metadata = "Metadata" },
						description = "Leading, text, and trailing scale with size",
						onActivated = logActivated("List item"),
						input = ListItemInputType.Chevron,
						LayoutOrder = 1,
					})
				end,
			}),
		},
	})
end

local function SizesStory()
	local sections = {}
	for index, size in SIZE_ORDER do
		sections[index] = SizeSection({
			LayoutOrder = index,
			size = size,
		})
	end

	return VF.View({
		tag = "col gap-large size-full-0 auto-y",
		children = sections,
	})
end

local function ActivationStory(controls: { [string]: any })
	local isChecked = Vide.source(false)
	local isSelected = Vide.source(true)

	return List.Root({
		size = controls.size,
		children = function()
			return {
				--* Main use case: the item-level `onActivated` owns activation. The whole row is tappable and the
				--* trailing accessory is chosen independently via `input`.
				List.Item({
					title = "Open Build chat",
					description = "Item onActivated — whole row tappable, no accessory",
					onActivated = function()
						print("navigate to Build chat")
					end,
					input = ListItemInputType.None,
					LayoutOrder = 1,
				}),
				List.Item({
					title = "Settings",
					description = "Item onActivated — whole row tappable, default chevron",
					onActivated = function()
						print("navigate to Settings")
					end,
					LayoutOrder = 2,
				}),
				foundation.rebuildOn(isSelected, function(selected: boolean)
					return List.Item({
						title = "Default option",
						description = "Item onActivated — whole row tappable, Check accessory",
						onActivated = function()
							print("ListItem activated: Default option")
							isSelected(not isSelected())
						end,
						input = ListItemInputType.None,
						trailing = if selected then CheckAccessory(controls.size) else nil,
						LayoutOrder = 3,
					})
				end),
				--* Advanced: the trailing `input.onActivated` owns activation instead. Only the checkbox is
				--* interactive and the row itself is not tappable. Never set both this and the item-level handler.
				List.Item({
					title = "Notifications",
					description = "Input onActivated — only the checkbox activates (row not tappable)",
					input = {
						type = ListItemInputType.Checkbox,
						isChecked = isChecked,
						onActivated = function(checked: boolean)
							print(`ListItem input activated: Notifications = {checked}`)
							isChecked(checked)
						end,
					},
					LayoutOrder = 4,
				}),
			}
		end,
	})
end

return foundation.sections({
	summary = "A tappable list row. The primary API is a whole-item `onActivated`; the trailing accessory is "
		.. "chosen independently via `input`.",
	controls = {
		leading = UILabs.Choose(LEADING_OPTIONS),
		title = "List Item Title",
		metadata = "List Item Metadata",
		description = "The title prop can be a string or an object with a title and metadata field.",
		size = UILabs.Choose(Dash.values(InputSize :: any)),
		inputType = UILabs.Choose(Dash.values(Dash.join(ListItemInputType :: any, { "" }))),
		onActivated = true,
		isChecked = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Input types",
			summary = "The trailing input accessory: Chevron (default), Checkbox, Toggle, or Radio.",
			story = InputTypesStory,
		},
		{
			name = "Selection",
			summary = "Tapping a row selects it. The selected row shows a Check placed in the trailing slot as a clickable accessory.",
			story = SelectionStory,
		},
		{ name = "Leading accessories", story = LeadingAccessoriesStory },
		{ name = "Sizes", story = SizesStory },
		{
			name = "Activation",
			summary = "The main use case is a whole-item `onActivated` — the entire row is tappable and the accessory "
				.. "is chosen independently via `input`. Advanced: the trailing input can own its own `onActivated` "
				.. "(and then the row itself is not tappable).",
			story = ActivationStory,
		},
	},
})
