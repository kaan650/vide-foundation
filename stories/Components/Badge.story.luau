local foundation = require("../foundation")
local MatrixGrid = require("../Shared/MatrixGrid")
local StoryIcons = require("../Shared/StoryIcons")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local BadgeShape = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/BadgeShape")
local BadgeSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/BadgeSize")
local BadgeVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/BadgeVariant")
local IconPosition = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/IconPosition")

type BadgeIcon = VideFoundation.BadgeIcon
type BadgeShape = BadgeShape.BadgeShape
type BadgeSize = BadgeSize.BadgeSize
type BadgeVariant = BadgeVariant.BadgeVariant
type ColorStyleValue = VideFoundation.ColorStyleValue

local Icons = VF.Enums.IconName

local nonDeprecatedVariants: { BadgeVariant } = Dash.filter(Dash.values(BadgeVariant :: any), function(item)
	return item ~= BadgeVariant.Primary and item ~= BadgeVariant.Secondary and item ~= BadgeVariant.Neutral
end)

local defaultBadgeProps = {
	text = "Label",
	variant = BadgeVariant.Contrast,
	shape = BadgeShape.Pill,
	size = BadgeSize.XSmall,
}

local SIZE_ORDER: { BadgeSize } = {
	BadgeSize.XSmall,
	BadgeSize.Small,
}

local LABEL_COLUMN_WIDTH = 80
local INFO_COLUMN_WIDTH = 240
local CELL_COLUMN_WIDTH = 100
local LONG_LABEL_TEXT = "This is a very long badge label that should be truncated"
local PLACEMENT_EXAMPLE_ICON = Icons.DiamondSimplified
local ON_MEDIA_PANEL_SIZE = UDim2.fromOffset(120, 56)
local ON_MEDIA_EXAMPLE_ICON = Icons.DiamondSimplified

--* Foundation drops Neutral here behind FoundationBadgeBetaUpdate, which is off live.
local ON_MEDIA_SEMI_TRANSPARENT_VARIANTS: { BadgeVariant } = {
	BadgeVariant.Alert,
	BadgeVariant.Success,
	BadgeVariant.Warning,
	BadgeVariant.Neutral,
}

local ON_MEDIA_SOLID_VARIANTS: { BadgeVariant } = {
	BadgeVariant.Contrast,
	BadgeVariant.Emphasis,
	BadgeVariant.OverMedia,
}

local PLACEMENT_SIZE_ORDER: { BadgeSize } = {
	BadgeSize.XSmall,
	BadgeSize.Small,
}

local controlSizeOptions: { BadgeSize } = {
	BadgeSize.XSmall,
	BadgeSize.Small,
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

local function LabeledBadge(props: {
	label: string,
	LayoutOrder: number,
	variant: BadgeVariant?,
	shape: BadgeShape?,
	size: BadgeSize?,
	icon: (string | BadgeIcon)?,
})
	return VF.View({
		tag = "col gap-small auto-xy",
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
				children = VF.Badge({
					text = defaultBadgeProps.text,
					icon = props.icon,
					variant = props.variant or defaultBadgeProps.variant,
					shape = props.shape or defaultBadgeProps.shape,
					size = props.size or defaultBadgeProps.size,
				}),
			}),
		},
	})
end

local function OnMediaVariant(props: { label: string, LayoutOrder: number, variant: BadgeVariant })
	local tokens = VF.Hooks.useTokens()

	return VF.View({
		tag = "col gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				Size = ON_MEDIA_PANEL_SIZE,
				tag = "align-x-left align-y-center padding-small radius-medium clip",
				backgroundStyle = function(): ColorStyleValue
					return tokens().Color.Surface.Surface_100 :: ColorStyleValue
				end,
				LayoutOrder = 2,
				children = VF.Badge({
					text = defaultBadgeProps.text,
					icon = {
						name = ON_MEDIA_EXAMPLE_ICON,
						position = IconPosition.Left,
					},
					variant = props.variant,
					shape = defaultBadgeProps.shape,
					size = BadgeSize.Small,
				}),
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.Badge({
		text = controls.text,
		icon = function(): BadgeIcon?
			local icon = StoryIcons.parseIconControl(controls.icon())
			return if icon then { name = icon, position = controls.iconPosition() } else nil
		end,
		size = controls.size,
		variant = controls.variant,
		shape = controls.shape,
	})
end

local function VariantsStory()
	local badges = {}
	for index, variant in nonDeprecatedVariants do
		badges[index] = LabeledBadge({
			label = variant,
			LayoutOrder = index,
			variant = variant,
			size = BadgeSize.Small,
			icon = {
				name = PLACEMENT_EXAMPLE_ICON,
				position = IconPosition.Left,
			},
		})
	end
	return VF.View({
		tag = "row wrap gap-large auto-xy padding-y-large bg-surface-0",
		children = badges,
	})
end

local function SizingStory()
	local badges = {}
	for index, size in SIZE_ORDER do
		badges[index] = LabeledBadge({
			label = size,
			LayoutOrder = index,
			size = size,
		})
	end
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "Size",
			contentTag = "row gap-large auto-xy wrap",
			children = badges,
		}),
	})
end

local function sizeRows(cells: (size: BadgeSize) -> { any }): { MatrixGrid.MatrixGridRow }
	local rows = {}
	for index, size in SIZE_ORDER do
		rows[index] = {
			label = MatrixGrid.matrixLabel(size),
			cells = cells(size),
		}
	end
	return rows
end

local function ShapesStory()
	return VF.View({
		tag = "col gap-large auto-xy padding-y-large bg-surface-0",
		children = MatrixGrid.MatrixGrid({
			labelColumnWidth = LABEL_COLUMN_WIDTH,
			columnHeaders = { BadgeShape.Pill, BadgeShape.Box },
			cellColumnWidth = CELL_COLUMN_WIDTH,
			rows = sizeRows(function(size)
				return {
					VF.Badge({
						text = defaultBadgeProps.text,
						variant = defaultBadgeProps.variant,
						shape = BadgeShape.Pill,
						size = size,
					}),
					VF.Badge({
						text = defaultBadgeProps.text,
						variant = defaultBadgeProps.variant,
						shape = BadgeShape.Box,
						size = size,
					}),
				}
			end),
		}),
	})
end

local function placementRows(): { MatrixGrid.MatrixGridRow }
	local rows = {}
	for index, size in PLACEMENT_SIZE_ORDER do
		rows[index] = {
			label = MatrixGrid.matrixLabel(size),
			cells = {
				VF.Badge({
					text = defaultBadgeProps.text,
					icon = { name = PLACEMENT_EXAMPLE_ICON, position = IconPosition.Left },
					variant = defaultBadgeProps.variant,
					shape = defaultBadgeProps.shape,
					size = size,
				}),
				VF.Badge({
					text = defaultBadgeProps.text,
					icon = { name = PLACEMENT_EXAMPLE_ICON, position = IconPosition.Right },
					variant = defaultBadgeProps.variant,
					shape = defaultBadgeProps.shape,
					size = size,
				}),
			},
		}
	end
	return rows
end

local function ContentStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Truncation",
				contentTag = "auto-xy",
				children = VF.Badge({
					text = LONG_LABEL_TEXT,
					variant = defaultBadgeProps.variant,
					shape = defaultBadgeProps.shape,
					size = defaultBadgeProps.size,
				}),
			}),
			Section({
				LayoutOrder = 2,
				name = "Icon by type",
				contentTag = "auto-xy",
				children = MatrixGrid.MatrixGrid({
					labelColumnWidth = INFO_COLUMN_WIDTH,
					columnHeaders = { "Left", "Right" },
					cellColumnWidth = CELL_COLUMN_WIDTH,
					rowGap = "xxlarge",
					rows = StoryIcons.buildIconTypeMatrixRows(function(accessoryIcon)
						return {
							VF.Badge({
								text = defaultBadgeProps.text,
								icon = { name = accessoryIcon.name, position = IconPosition.Left },
								variant = defaultBadgeProps.variant,
								shape = defaultBadgeProps.shape,
								size = defaultBadgeProps.size,
							}),
							VF.Badge({
								text = defaultBadgeProps.text,
								icon = { name = accessoryIcon.name, position = IconPosition.Right },
								variant = defaultBadgeProps.variant,
								shape = defaultBadgeProps.shape,
								size = defaultBadgeProps.size,
							}),
						}
					end),
				}),
			}),
			Section({
				LayoutOrder = 3,
				name = "Icon placement by size",
				contentTag = "auto-xy",
				children = MatrixGrid.MatrixGrid({
					labelColumnWidth = LABEL_COLUMN_WIDTH,
					columnHeaders = { "Left", "Right" },
					cellColumnWidth = CELL_COLUMN_WIDTH,
					rows = placementRows(),
				}),
			}),
			Section({
				LayoutOrder = 4,
				name = "Icon only",
				contentTag = "auto-xy",
				children = MatrixGrid.MatrixGrid({
					labelColumnWidth = LABEL_COLUMN_WIDTH,
					columnHeaders = { BadgeShape.Pill, BadgeShape.Box },
					cellColumnWidth = CELL_COLUMN_WIDTH,
					rows = sizeRows(function(size)
						return {
							VF.Badge({
								icon = PLACEMENT_EXAMPLE_ICON,
								variant = defaultBadgeProps.variant,
								shape = BadgeShape.Pill,
								size = size,
							}),
							VF.Badge({
								icon = PLACEMENT_EXAMPLE_ICON,
								variant = defaultBadgeProps.variant,
								shape = BadgeShape.Box,
								size = size,
							}),
						}
					end),
				}),
			}),
		},
	})
end

local function onMediaVariants(variants: { BadgeVariant }): { any }
	local children = {}
	for index, variant in variants do
		children[index] = OnMediaVariant({
			label = variant,
			LayoutOrder = index,
			variant = variant,
		})
	end
	return children
end

local function InContextStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Semi-transparent on media",
				contentTag = "row gap-large auto-xy wrap",
				children = onMediaVariants(ON_MEDIA_SEMI_TRANSPARENT_VARIANTS),
			}),
			Section({
				LayoutOrder = 2,
				name = "Solid on media",
				contentTag = "row gap-large auto-xy wrap",
				children = onMediaVariants(ON_MEDIA_SOLID_VARIANTS),
			}),
		},
	})
end

return foundation.sections({
	summary = "Badge is a non-interactive visual cue that calls attention to additional information, such as a special condition, state, or quality.",
	controls = {
		text = "Label",
		icon = UILabs.Choose(StoryIcons.buildIconControlOptions()),
		variant = UILabs.Choose(nonDeprecatedVariants),
		shape = UILabs.Choose(Dash.values(BadgeShape :: any)),
		iconPosition = UILabs.Choose(Dash.values(IconPosition :: any)),
		size = UILabs.Choose(controlSizeOptions),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Variants", story = VariantsStory },
		{ name = "Sizing", story = SizingStory },
		{ name = "Shapes", story = ShapesStory },
		{
			name = "Content",
			story = function()
				return foundation.scroll(ContentStory())
			end,
		},
		{
			name = "In context",
			summary = "Badges on media backgrounds, grouped by transparency.",
			story = InContextStory,
		},
	},
})
