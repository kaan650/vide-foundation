local foundation = require("../foundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")

local InputPlacement = VF.Enums.InputPlacement
local InputSize = VF.Enums.InputSize

type Value<T> = VideFoundation.Value<T>

type Item = {
	label: string,
	hint: Value<string?>?,
	isChecked: Value<boolean?>?,
	isDisabled: boolean?,
	isIndeterminate: boolean?,
	onActivated: ((boolean) -> ())?,
}

export type Options = {
	-- The group component (CheckboxGroup, ToggleGroup) and the item it holds (Checkbox, Toggle).
	Group: (props: any) -> any,
	Item: (props: any) -> any,
	itemName: string,
	summary: string,
	defaultLegend: string,
	labels: { string },
	hints: { string },
	states: { Item },
}

local SIZE_ORDER = { InputSize.XSmall, InputSize.Small, InputSize.Medium }
local PLACEMENT_ORDER = { InputPlacement.Start, InputPlacement.End }
local PLAYGROUND_SIZE_OPTIONS = { InputSize.Medium, InputSize.XSmall, InputSize.Small }
local PLAYGROUND_PLACEMENT_OPTIONS = PLACEMENT_ORDER

local function noop() end

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

local function Page(children: any)
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = children,
	})
end

local function createItems(ItemComponent: (props: any) -> any, items: { Item }): { any }
	local children = {}
	for index, item in items do
		children[index] = ItemComponent({
			label = item.label,
			hint = item.hint,
			isChecked = item.isChecked,
			isDisabled = item.isDisabled,
			isIndeterminate = item.isIndeterminate,
			onActivated = item.onActivated or noop,
			LayoutOrder = index,
		})
	end
	return children
end

local function staticItems(): { Item }
	return {
		{ label = "Option A", isChecked = true },
		{ label = "Option B", isChecked = false },
		{ label = "Option C", isChecked = true },
	}
end

--- The story of an input group (CheckboxGroup, ToggleGroup): Playground, Sizing, States and Placement.
local function create(options: Options)
	local function PlaygroundStory(controls: { [string]: any })
		local checked = Vide.source({ true, false, true, false })
		local items: { Item } = {}

		for index, label in options.labels do
			items[index] = {
				label = label,
				hint = function()
					return if controls.showHints() then options.hints[index] else nil
				end,
				isChecked = function()
					return checked()[index]
				end,
				onActivated = function(value: boolean)
					local updated = table.clone(Vide.untrack(checked))
					updated[index] = value
					checked(updated)
				end,
			}
		end

		return VF.View({
			tag = "auto-xy padding-medium",
			--* The group takes size and placement as plain values, so a change builds it again.
			children = foundation.rebuildOn(function()
				return `{controls.size()}/{controls.placement()}`
			end, function()
				return options.Group({
					legend = controls.legend,
					size = controls.size(),
					placement = controls.placement(),
					children = function()
						return createItems(options.Item, items)
					end,
				})
			end),
		})
	end

	local function SizingStory()
		local groups = {}
		for index, size in SIZE_ORDER do
			groups[index] = options.Group({
				legend = size,
				size = size,
				LayoutOrder = index,
				children = function()
					return createItems(options.Item, staticItems())
				end,
			})
		end
		return Page({
			Section({
				LayoutOrder = 1,
				name = "Size",
				contentTag = "row gap-xxlarge auto-xy wrap",
				children = groups,
			}),
		})
	end

	local function StatesStory()
		return Page({
			Section({
				LayoutOrder = 1,
				name = "Item states",
				contentTag = "auto-xy",
				children = options.Group({
					size = InputSize.Medium,
					children = function()
						return createItems(options.Item, options.states)
					end,
				}),
			}),
		})
	end

	local function PlacementStory()
		local groups = {}
		for index, placement in PLACEMENT_ORDER do
			groups[index] = options.Group({
				legend = placement,
				placement = placement,
				LayoutOrder = index,
				children = function()
					return createItems(options.Item, staticItems())
				end,
			})
		end
		return Page({
			Section({
				LayoutOrder = 1,
				name = "Placement",
				contentTag = "row gap-xxlarge auto-xy wrap",
				children = groups,
			}),
		})
	end

	return foundation.sections({
		summary = options.summary,
		controls = {
			legend = options.defaultLegend,
			size = UILabs.Choose(PLAYGROUND_SIZE_OPTIONS),
			placement = UILabs.Choose(PLAYGROUND_PLACEMENT_OPTIONS),
			showHints = false,
		},
		sections = {
			{ name = "Playground", story = PlaygroundStory },
			{ name = "Sizing", story = SizingStory },
			{ name = "States", story = StatesStory },
			{
				name = "Placement",
				summary = `placement positions each item's label relative to its {string.lower(options.itemName)}.`,
				story = PlacementStory,
			},
		},
	})
end

return {
	create = create,
}
