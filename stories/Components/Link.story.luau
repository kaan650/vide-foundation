local foundation = require("../foundation")
local MatrixGrid = require("../Shared/MatrixGrid")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local Link = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Link")

local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local LinkVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/LinkVariant")
local TextOverflow = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/TextOverflow")

type ColorStyleValue = VideFoundation.ColorStyleValue
type InputSize = InputSize.InputSize
type LinkVariant = LinkVariant.LinkVariant
type TextOverflow = TextOverflow.TextOverflow

--* Link maps XSmall to Small, so the story shows the three sizes Link's docs list.
local SIZES: { InputSize } = { InputSize.Small, InputSize.Medium, InputSize.Large }
local TEXT_OVERFLOWS: { TextOverflow } =
	{ TextOverflow.None, TextOverflow.Wrap, TextOverflow.Truncate, TextOverflow.TruncateSplit }
local VARIANTS: { LinkVariant } = { LinkVariant.Standard, LinkVariant.Inverse }

local LONG_TEXT = "Read the full community guidelines before you publish your experience"
local OVERFLOW_WIDTH = 240

local openDocs = foundation.action("Link activated")

local function Surface(props: { isInverse: boolean, LayoutOrder: number?, children: any })
	local tokens = VF.Hooks.useTokens()
	return VF.View({
		tag = "auto-xy padding-medium radius-medium",
		backgroundStyle = function(): ColorStyleValue
			local current = tokens()
			return (
				if props.isInverse then current.Inverse.Surface.Surface_0 else current.Color.Surface.Surface_0
			) :: ColorStyleValue
		end,
		LayoutOrder = props.LayoutOrder,
		children = props.children,
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.View({
		tag = "auto-y",
		Size = UDim2.fromOffset(OVERFLOW_WIDTH, 0),
		children = Link({
			text = controls.text,
			variant = controls.variant,
			size = controls.size,
			hasUnderline = controls.hasUnderline,
			textOverflow = controls.textOverflow,
			onActivated = openDocs,
		}),
	})
end

local function UsageStory()
	return VF.View({
		tag = "col gap-large auto-xy",
		children = {
			Link({
				text = "View documentation",
				onActivated = openDocs,
				LayoutOrder = 1,
			}),
			Link({
				text = "Learn more",
				hasUnderline = true,
				onActivated = openDocs,
				LayoutOrder = 2,
			}),
		},
	})
end

local function VariantsStory()
	local variants = VARIANTS
	local cells = {}
	for index, variant in variants do
		cells[index] = Surface({
			isInverse = variant == LinkVariant.Inverse,
			children = Link({
				text = "View documentation",
				variant = variant,
				onActivated = openDocs,
			}),
		})
	end
	return MatrixGrid.MatrixGrid({
		showLabelColumn = false,
		columnHeaders = { LinkVariant.Standard, LinkVariant.Inverse },
		cellColumnWidth = 200,
		rows = { { cells = cells } },
	})
end

local function SizesStory()
	local rows: { MatrixGrid.MatrixGridRow } = {}
	for index, size in SIZES do
		rows[index] = {
			label = MatrixGrid.matrixLabel(size),
			cells = {
				Link({ text = "View documentation", size = size, onActivated = openDocs }),
				Link({ text = "View documentation", size = size, hasUnderline = true, onActivated = openDocs }),
			},
		}
	end
	return MatrixGrid.MatrixGrid({
		labelColumnWidth = 80,
		columnHeaders = { "Hover underline", "Persistent underline" },
		cellColumnWidth = 220,
		rows = rows,
	})
end

local function TextOverflowStory()
	local rows: { MatrixGrid.MatrixGridRow } = {}
	for index, textOverflow in TEXT_OVERFLOWS do
		rows[index] = {
			label = MatrixGrid.matrixLabel(textOverflow),
			cells = {
				VF.View({
					tag = "auto-y",
					Size = UDim2.fromOffset(OVERFLOW_WIDTH, 0),
					children = Link({
						text = LONG_TEXT,
						textOverflow = textOverflow,
						hasUnderline = true,
						onActivated = openDocs,
					}),
				}),
			},
		}
	end
	return MatrixGrid.MatrixGrid({
		labelColumnWidth = 120,
		columnHeaders = { `In a {OVERFLOW_WIDTH}px container` },
		cellColumnWidth = OVERFLOW_WIDTH,
		cellAlign = "left",
		rows = rows,
	})
end

return foundation.sections({
	summary = "Link is an interactive text control that navigates the user to another resource. It underlines on hover/focus and shows a focus ring while selected.",
	controls = {
		text = "View documentation",
		variant = UILabs.Choose(VARIANTS),
		size = UILabs.Choose({ InputSize.Medium, InputSize.Small, InputSize.Large }),
		hasUnderline = false,
		textOverflow = UILabs.Choose(TEXT_OVERFLOWS),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Usage", story = UsageStory },
		{
			name = "Variants",
			summary = "Inverse is for links on an inverted surface, one whose theme is flipped relative to the app.",
			story = VariantsStory,
		},
		{ name = "Sizes", story = SizesStory },
		{
			name = "Text overflow",
			summary = "None sizes to the text; Wrap, Truncate and TruncateSplit fill the container's width.",
			story = TextOverflowStory,
		},
	},
})
