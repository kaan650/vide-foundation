local foundation = require("../foundation")
local StoryIcons = require("../Shared/StoryIcons")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local FillBehavior = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/FillBehavior")
local OptionSelectorGroupContext =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Components/OptionSelectorGroup/OptionSelectorGroupContext")
local OptionSelectorGroupSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/OptionSelectorGroupSize")
local Orientation = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/Orientation")
local Value = require("@game/ReplicatedStorage/Packages/VideFoundation/Utility/Value")

type FillBehavior = FillBehavior.FillBehavior
type OptionSelectorGroupSize = OptionSelectorGroupSize.OptionSelectorGroupSize
type Orientation = Orientation.Orientation
type Value<T> = VideFoundation.Value<T>

local IconName = VF.Enums.IconName

local SIZE_ORDER: { OptionSelectorGroupSize } = {
	OptionSelectorGroupSize.XSmall,
	OptionSelectorGroupSize.Small,
	OptionSelectorGroupSize.Medium,
}

local PLAYGROUND_GROUP_SIZE_OPTIONS = {
	foundation.NONE,
	OptionSelectorGroupSize.XSmall,
	OptionSelectorGroupSize.Small,
	OptionSelectorGroupSize.Medium,
}

local GROUP_ORIENTATION_ORDER: { Orientation } = {
	Orientation.Vertical,
	Orientation.Horizontal,
}

-- The three accepted icon input types (builder, migrated legacy string, non-migrated legacy string).
local ICON_TYPES = {
	{ caption = "Builder", icon = IconName.House },
	{ caption = "Migrated legacy", icon = "icons/placeholder/placeholderOn_small" },
	{ caption = "Non-migrated legacy", icon = "icons/menu/clothing/limited_on" },
}

local PLAYGROUND_GROUP_FILL_BEHAVIOR_OPTIONS = {
	foundation.NONE,
	FillBehavior.Fit,
	FillBehavior.Fill,
}

local LONG_TEXT =
	"With a lot of extra text to see how it behaves when it might need to wrap to multiple lines because it simply cannot fit on one line"

local ITEM_COLUMN_WIDTH = 280
-- Icon matrix cells need extra width at Medium (xxlarge padding + icon + checkmark chrome).
local ICON_MATRIX_COLUMN_WIDTH = 240
local ITEM_VALUE = "A"

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

local function captionCell(text: string, width: number, layoutOrder: number, muted: boolean)
	return VF.Text({
		Text = text,
		tag = `auto-xy text-caption-small text-align-x-left {if muted then "content-muted" else "content-default"}`,
		Size = UDim2.fromOffset(width, 0),
		LayoutOrder = layoutOrder,
	})
end

type ItemExampleProps = {
	LayoutOrder: number?,
	-- Layout props are plain unless `fillParent` is set, which sizes the wrapper on its own.
	groupOrientation: Value<Orientation>?,
	groupSize: Value<OptionSelectorGroupSize?>?,
	groupFillBehavior: Value<FillBehavior?>?,
	selectedValue: Value<string?>?,
	onValueChanged: ((string?) -> ())?,
	value: string?,
	icon: Value<string?>?,
	-- When omitted, defaults to "Option". Pass "" to render an empty label.
	label: Value<string>?,
	metadata: Value<string?>?,
	description: Value<string?>?,
	isDisabled: Value<boolean>?,
	containerWidth: number?,
	-- When true, the wrapper spans the parent width (e.g. playground gray surface).
	fillParent: boolean?,
	-- Draws a surface behind the bounded parent so Fill vs Fit sizing is easier to see.
	parentSurface: boolean?,
}

--- An Item inside a group context built by hand, so one item can be shown without its group.
local function ItemExample(props: ItemExampleProps)
	local groupOrientation: Value<Orientation> = props.groupOrientation or Orientation.Vertical
	-- Match Item fillBehavior resolution: vertical groups always Fill; horizontal groups honor Root fillBehavior.
	local needsBoundedWidth = groupOrientation == Orientation.Vertical
		or props.containerWidth ~= nil
		or props.groupFillBehavior == FillBehavior.Fill
	local label: Value<string> = if props.label ~= nil then props.label else "Option"

	local wrapperTag = if props.fillParent or needsBoundedWidth then "size-full-0 auto-y" else "auto-xy"
	if props.parentSurface then
		wrapperTag = `{wrapperTag} bg-surface-100 radius-medium padding-large`
	end

	return VF.View({
		tag = wrapperTag,
		Size = if props.fillParent
			then UDim2.fromScale(1, 0)
			elseif needsBoundedWidth then UDim2.fromOffset(props.containerWidth or ITEM_COLUMN_WIDTH, 0)
			else nil,
		LayoutOrder = props.LayoutOrder,
		children = OptionSelectorGroupContext({
			value = function(): string?
				return Value.read(props.selectedValue)
			end,
			onValueChanged = props.onValueChanged or noop,
			orientation = function(): Orientation
				return Value.read(groupOrientation)
			end,
			size = function(): OptionSelectorGroupSize?
				return Value.read(props.groupSize)
			end,
			fillBehavior = function(): FillBehavior?
				return Value.read(props.groupFillBehavior)
			end,
			Selectable = true,
			testId = "--foundation-option-selector-group",
		}, function()
			return VF.OptionSelectorGroup.Item({
				value = props.value or ITEM_VALUE,
				icon = props.icon,
				label = label,
				metadata = props.metadata,
				description = props.description,
				isDisabled = props.isDisabled,
			})
		end),
	})
end

local function LabeledItem(props: {
	label: string,
	LayoutOrder: number,
	groupOrientation: Orientation?,
	groupSize: OptionSelectorGroupSize?,
	groupFillBehavior: FillBehavior?,
	selectedValue: string?,
	containerWidth: number?,
	parentSurface: boolean?,
})
	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			ItemExample({
				LayoutOrder = 2,
				groupOrientation = props.groupOrientation,
				groupSize = props.groupSize,
				groupFillBehavior = props.groupFillBehavior,
				selectedValue = props.selectedValue,
				containerWidth = props.containerWidth,
				parentSurface = props.parentSurface,
			}),
		},
	})
end

local function nonEmpty(control: () -> string): () -> string?
	return function()
		local text = control()
		return if #text > 0 then text else nil
	end
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.View({
		tag = "size-full-0 auto-y",
		children = ItemExample({
			groupOrientation = controls.groupOrientation,
			groupSize = foundation.orNil(controls.groupSize),
			groupFillBehavior = foundation.orNil(controls.groupFillBehavior),
			selectedValue = function(): string?
				return if controls.isSelected() then ITEM_VALUE else nil
			end,
			onValueChanged = function(newValue: string?)
				print("OptionSelectorGroupItem value changed", newValue)
			end,
			value = ITEM_VALUE,
			icon = function()
				return StoryIcons.parseIconControl(controls.icon())
			end,
			label = controls.label,
			metadata = nonEmpty(controls.metadata),
			description = nonEmpty(controls.description),
			isDisabled = controls.isDisabled,
			parentSurface = true,
			fillParent = true,
		}),
	})
end

local function SizingStory()
	local sizes = {}
	for index, size in SIZE_ORDER do
		sizes[index] = LabeledItem({
			label = size,
			LayoutOrder = index,
			groupSize = size,
			containerWidth = 160,
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Size",
				contentTag = "row gap-large auto-xy",
				children = sizes,
			}),
			Section({
				LayoutOrder = 2,
				name = "Fill behavior",
				contentTag = "col gap-large align-x-left size-full-0 auto-y",
				children = {
					LabeledItem({
						label = "Fit",
						LayoutOrder = 1,
						groupOrientation = Orientation.Horizontal,
						groupFillBehavior = FillBehavior.Fit,
						containerWidth = 200,
						parentSurface = true,
					}),
					LabeledItem({
						label = "Fill",
						LayoutOrder = 2,
						groupOrientation = Orientation.Horizontal,
						groupFillBehavior = FillBehavior.Fill,
						containerWidth = 200,
						parentSurface = true,
					}),
				},
			}),
		},
	})
end

local function StatesStory()
	local selected = {}
	for index, size in SIZE_ORDER do
		selected[index] = LabeledItem({
			label = size,
			LayoutOrder = index,
			groupSize = size,
			selectedValue = ITEM_VALUE,
			containerWidth = 160,
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Selected",
				contentTag = "row gap-large auto-xy",
				children = selected,
			}),
			Section({
				LayoutOrder = 2,
				name = "Disabled",
				contentTag = "auto-xy",
				children = ItemExample({
					selectedValue = ITEM_VALUE,
					isDisabled = true,
					containerWidth = 160,
				}),
			}),
		},
	})
end

local ORIENTATION_MATRIX_ROWS: { { label: string, groupOrientation: Orientation, groupFillBehavior: FillBehavior? } } =
	{
		{ label = "Vertical", groupOrientation = Orientation.Vertical, groupFillBehavior = nil },
		{ label = "Horizontal Fit", groupOrientation = Orientation.Horizontal, groupFillBehavior = FillBehavior.Fit },
		{ label = "Horizontal Fill", groupOrientation = Orientation.Horizontal, groupFillBehavior = FillBehavior.Fill },
	}

type OrientationMatrixColumn = {
	label: string,
	selectedValue: string?,
	icon: string?,
}

local ICON_COLUMNS: { OrientationMatrixColumn } = {
	{ label = "Without icon", selectedValue = nil },
	{ label = "With icon", selectedValue = nil, icon = IconName.House },
}

local function OrientationSelectionMatrix(props: { LayoutOrder: number, columns: { OrientationMatrixColumn } })
	local headerCells = {
		VF.View({
			Size = UDim2.fromOffset(120, 0),
			LayoutOrder = 1,
		}),
	}
	for columnIndex, column in props.columns do
		table.insert(headerCells, captionCell(column.label, ITEM_COLUMN_WIDTH, columnIndex + 1, true))
	end

	local rows = {}
	for rowIndex, row in ORIENTATION_MATRIX_ROWS do
		local cells = { captionCell(row.label, 120, 1, false) }
		for columnIndex, column in props.columns do
			table.insert(
				cells,
				ItemExample({
					LayoutOrder = columnIndex + 1,
					groupOrientation = row.groupOrientation,
					groupFillBehavior = row.groupFillBehavior,
					selectedValue = column.selectedValue,
					icon = column.icon,
					description = "Description",
					containerWidth = ITEM_COLUMN_WIDTH,
				})
			)
		end
		rows[rowIndex] = VF.View({
			tag = "row gap-large auto-xy",
			LayoutOrder = rowIndex + 1,
			children = cells,
		})
	end

	return VF.View({
		tag = "col gap-large auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.View({
				tag = "row align-y-center gap-large auto-xy",
				LayoutOrder = 1,
				children = headerCells,
			}),
			VF.View({
				tag = "col gap-large auto-xy",
				LayoutOrder = 2,
				children = rows,
			}),
		},
	})
end

--* FoundationOptionSelectorGroupBeta is on live, so only its icon matrix is ported.
local function OrientationStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = OrientationSelectionMatrix({
			LayoutOrder = 1,
			columns = ICON_COLUMNS,
		}),
	})
end

local function ControlledExample()
	local selectedValue = Vide.source(nil :: string?)
	local getSelectedValue: () -> string? = selectedValue :: any

	return VF.View({
		tag = "col gap-medium auto-xy",
		children = {
			ItemExample({
				LayoutOrder = 1,
				selectedValue = getSelectedValue,
				onValueChanged = function(newValue: string?)
					selectedValue(newValue)
				end,
				description = "Click to select or clear",
				containerWidth = ITEM_COLUMN_WIDTH,
			}),
			VF.Text({
				Text = function()
					return `Selected: {getSelectedValue() or "none"}`
				end,
				tag = "auto-xy text-body-medium text-align-x-left content-emphasis",
				LayoutOrder = 2,
			}),
		},
	})
end

local function ControlledStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "Selection updates value",
			contentTag = "auto-xy",
			children = ControlledExample(),
		}),
	})
end

local function Matrix(header: { any }, rows: { any })
	return VF.View({
		tag = "col gap-large auto-xy",
		LayoutOrder = 1,
		children = {
			VF.View({
				tag = "row align-y-center gap-large auto-xy",
				LayoutOrder = 1,
				children = header,
			}),
			VF.View({
				tag = "col gap-large auto-xy",
				LayoutOrder = 2,
				children = rows,
			}),
		},
	})
end

local TEXT_COMBINATIONS: { { caption: string, label: string, metadata: string?, description: string? } } = {
	{ caption = "Label", label = "Title" },
	{ caption = "Label + metadata", label = "Title", metadata = "Metadata" },
	{ caption = "Label + description", label = "Title", description = "Description" },
	{
		caption = "Label + metadata + description",
		label = "Title",
		metadata = "Metadata",
		description = "Description",
	},
}

local function ContentStory()
	local iconHeaderCells = {
		VF.View({
			Size = UDim2.fromOffset(80, 0),
			LayoutOrder = 1,
		}),
	}
	for columnIndex, iconType in ICON_TYPES do
		table.insert(iconHeaderCells, captionCell(iconType.caption, ICON_MATRIX_COLUMN_WIDTH, columnIndex + 1, true))
	end

	local sizeRows = {}
	for rowIndex, size in SIZE_ORDER do
		local cells = { captionCell(size, 80, 1, false) }
		for columnIndex, iconType in ICON_TYPES do
			table.insert(
				cells,
				ItemExample({
					LayoutOrder = columnIndex + 1,
					groupSize = size,
					icon = iconType.icon,
					containerWidth = ICON_MATRIX_COLUMN_WIDTH,
				})
			)
		end
		sizeRows[rowIndex] = VF.View({
			tag = "row gap-large auto-xy",
			LayoutOrder = rowIndex + 1,
			children = cells,
		})
	end

	local textCombinationHeaderCells = {
		VF.View({
			Size = UDim2.fromOffset(220, 0),
			LayoutOrder = 1,
		}),
		captionCell("No icon", ITEM_COLUMN_WIDTH, 2, true),
		captionCell("With icon", ITEM_COLUMN_WIDTH, 3, true),
	}

	local textCombinationRows = {}
	for rowIndex, combination in TEXT_COMBINATIONS do
		textCombinationRows[rowIndex] = VF.View({
			tag = "row gap-large auto-xy",
			LayoutOrder = rowIndex + 1,
			children = {
				captionCell(combination.caption, 220, 1, false),
				ItemExample({
					LayoutOrder = 2,
					label = combination.label,
					metadata = combination.metadata,
					description = combination.description,
					containerWidth = ITEM_COLUMN_WIDTH,
				}),
				ItemExample({
					LayoutOrder = 3,
					icon = IconName.House,
					label = combination.label,
					metadata = combination.metadata,
					description = combination.description,
					containerWidth = ITEM_COLUMN_WIDTH,
				}),
			},
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Icon by type and size",
				contentTag = "auto-xy",
				children = Matrix(iconHeaderCells, sizeRows),
			}),
			Section({
				LayoutOrder = 2,
				name = "Label, metadata & description",
				contentTag = "auto-xy",
				children = Matrix(textCombinationHeaderCells, textCombinationRows),
			}),
			Section({
				LayoutOrder = 3,
				name = "Long text",
				contentTag = "auto-xy",
				children = Matrix({
					captionCell("Default", ITEM_COLUMN_WIDTH, 1, true),
					captionCell("With icon", ITEM_COLUMN_WIDTH, 2, true),
				}, {
					VF.View({
						tag = "row gap-large auto-xy",
						LayoutOrder = 1,
						children = {
							ItemExample({
								LayoutOrder = 1,
								label = LONG_TEXT,
								metadata = LONG_TEXT,
								description = LONG_TEXT,
								containerWidth = ITEM_COLUMN_WIDTH,
							}),
							ItemExample({
								LayoutOrder = 2,
								icon = IconName.House,
								label = LONG_TEXT,
								metadata = LONG_TEXT,
								description = LONG_TEXT,
								containerWidth = ITEM_COLUMN_WIDTH,
							}),
						},
					}),
				}),
			}),
		},
	})
end

return foundation.sections({
	summary = "A single selectable option inside an OptionSelectorGroup. Renders label, optional icon/metadata/description. Behind FoundationOptionSelectorGroupBeta, selection uses a Checked contrast stroke (no trailing checkmark) with Hover/Press state layers.",
	controls = {
		groupOrientation = UILabs.Choose(GROUP_ORIENTATION_ORDER),
		groupSize = UILabs.Choose(PLAYGROUND_GROUP_SIZE_OPTIONS),
		groupFillBehavior = UILabs.Choose(PLAYGROUND_GROUP_FILL_BEHAVIOR_OPTIONS),
		icon = UILabs.Choose(StoryIcons.buildIconControlOptions()),
		isDisabled = false,
		isSelected = false,
		label = "Label",
		metadata = "",
		description = "",
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Sizing",
			summary = "Prefer Root `size` and `fillBehavior` (Item props deprecated). fillBehavior applies in horizontal groups; default Fit. Vertical groups always Fill.",
			story = SizingStory,
		},
		{
			name = "States",
			summary = "Selected uses a contrast stroke (checkmark when FoundationOptionSelectorGroupBeta is off).",
			story = StatesStory,
		},
		{
			name = "Orientation",
			summary = "Rows: Vertical group, Horizontal Fit, Horizontal Fill. Columns: Without icon / With icon. Each Item lays out opposite the group (vertical group → horizontal item content; horizontal group → vertical item content).",
			story = function()
				return foundation.scroll(OrientationStory())
			end,
		},
		{ name = "Controlled component", story = ControlledStory },
		{
			name = "Content",
			summary = "XSmall and Small share text-title-small, so the footprint jump is subtler until Medium (title + padding both step up).",
			story = function()
				return foundation.scroll(ContentStory())
			end,
		},
	},
})
