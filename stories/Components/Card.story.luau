local foundation = require("../foundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local CardDensity = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/CardDensity")
local CardHeaderSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/CardHeaderSize")
local CardHeight = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/CardHeight")
local CardMediaAspectRatio = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/CardMediaAspectRatio")
local CardMediaPlacement = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/CardMediaPlacement")
local CardVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/CardVariant")
--* Foundation exports CardMedia from the Card module only, not from the package root.
local CardModule = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Card")

type CardMedia = CardModule.CardMedia

type CardDensity = CardDensity.CardDensity
type CardHeaderSize = CardHeaderSize.CardHeaderSize
type CardHeight = CardHeight.CardHeight
type CardMediaAspectRatio = CardMediaAspectRatio.CardMediaAspectRatio
type CardVariant = CardVariant.CardVariant

local IconName = VF.Enums.IconName

local SAMPLE_IMAGE = Content.fromAssetId(78323814447735).Uri :: string

local VARIANT_ORDER: { CardVariant } = { CardVariant.Standard, CardVariant.Emphasis }
local DENSITY_ORDER: { CardDensity } = { CardDensity.Default, CardDensity.Compact, CardDensity.Comfortable }
local HEIGHT_ORDER: { CardHeight } = { CardHeight.Fit, CardHeight.Fill }
local HEADER_SIZE_ORDER: { CardHeaderSize } = {
	CardHeaderSize.XXSmall,
	CardHeaderSize.XSmall,
	CardHeaderSize.Small,
	CardHeaderSize.Medium,
	CardHeaderSize.Large,
}
local MEDIA_OPTIONS = { "None", "End", "Bottom" }

local CARD_WIDTH = 360
local PLAYGROUND_SIZE = UDim2.fromOffset(400, 360)
local FILL_ROW_HEIGHT = 220
local FILL_ROW_GAP = 12
local DESCRIPTION = "Supporting copy that describes what the card is about."
local LONG_DESCRIPTION =
	"Supporting copy that runs long enough to wrap onto several lines, so the line clamp has something to cut off at the end of the second line."

local function noop() end

local function action(name: string): () -> ()
	return function()
		print(`[Card] {name}`)
	end
end

local function Slot(): GuiObject
	return VF.View({
		Size = UDim2.new(1, 0, 0, 48),
		tag = "radius-medium bg-shift-300",
	})
end

local function Example(props: { label: string, LayoutOrder: number, width: number?, children: any })
	return VF.View({
		Size = UDim2.fromOffset(props.width or CARD_WIDTH, 0),
		tag = "col gap-small auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-muted",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "col size-full-0 auto-y",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function Grid(children: { any })
	return foundation.scroll(VF.View({
		tag = "row wrap gap-xlarge size-full-0 auto-y align-y-top",
		children = children,
	}))
end

local function PlaygroundStory(controls: { [string]: any })
	--* Callbacks and children are plain props, so toggling one builds the card again.
	local callbacks = function(): string
		return `{controls.onOverflow()}|{controls.onClose()}|{controls.onActivated()}|{controls.slot()}`
	end

	return VF.View({
		Size = PLAYGROUND_SIZE,
		tag = "col",
		children = foundation.rebuildOn(callbacks, function()
			return VF.Card({
				variant = controls.variant,
				density = controls.density,
				height = controls.height,
				headerSize = foundation.orNil(controls.headerSize),
				eyebrow = function(): string?
					local eyebrow = controls.eyebrow()
					return if eyebrow ~= "" then eyebrow else nil
				end,
				icon = function()
					return if controls.icon() then IconName.Diamond else nil
				end,
				title = function(): string?
					local title = controls.title()
					return if title ~= "" then title else nil
				end,
				description = function(): string?
					local description = controls.description()
					return if description ~= "" then description else nil
				end,
				media = function(): CardMedia?
					local placement = controls.media()
					if placement == "End" then
						return SAMPLE_IMAGE
					elseif placement == "Bottom" then
						return { image = SAMPLE_IMAGE, placement = CardMediaPlacement.Bottom }
					end
					return nil
				end,
				onOverflow = if controls.onOverflow() then action("overflow") else nil,
				onClose = if controls.onClose() then action("close") else nil,
				onActivated = if controls.onActivated() then action("activated") else nil,
				children = if controls.slot() then Slot() else nil,
			})
		end),
	})
end

local function VariantsStory()
	local examples = {}
	for index, variant in VARIANT_ORDER do
		examples[index] = Example({
			label = variant,
			LayoutOrder = index,
			children = VF.Card({
				variant = variant,
				title = "Title",
				description = DESCRIPTION,
				children = Slot(),
			}),
		})
	end
	return Grid(examples)
end

local function DensityStory()
	local examples = {}
	for index, density in DENSITY_ORDER do
		examples[index] = Example({
			label = density,
			LayoutOrder = index,
			children = VF.Card({
				density = density,
				title = "Title",
				description = DESCRIPTION,
				onOverflow = noop,
				children = Slot(),
			}),
		})
	end
	return Grid(examples)
end

local function HeaderSizesStory()
	local examples = {}
	for index, headerSize in HEADER_SIZE_ORDER do
		examples[index] = Example({
			label = headerSize,
			LayoutOrder = index,
			children = VF.Card({
				headerSize = headerSize,
				eyebrow = "Eyebrow",
				icon = IconName.Diamond,
				title = "Title",
				description = DESCRIPTION,
			}),
		})
	end
	return Grid(examples)
end

local function MediaStory()
	local bottomRatios: { CardMediaAspectRatio } = {
		CardMediaAspectRatio.Ratio2x1,
		CardMediaAspectRatio.Ratio16x9,
		CardMediaAspectRatio.Ratio1x1,
	}
	local examples = {
		Example({
			label = "End (default width)",
			LayoutOrder = 1,
			children = VF.Card({ title = "Title", description = DESCRIPTION, media = SAMPLE_IMAGE }),
		}),
		Example({
			label = "End, width 96",
			LayoutOrder = 2,
			children = VF.Card({
				title = "Title",
				description = DESCRIPTION,
				media = { image = SAMPLE_IMAGE, width = 96 },
			}),
		}),
	}
	for index, aspectRatio in bottomRatios do
		table.insert(
			examples,
			Example({
				label = `Bottom {aspectRatio}`,
				LayoutOrder = 2 + index,
				children = VF.Card({
					title = "Title",
					description = DESCRIPTION,
					media = { image = SAMPLE_IMAGE, placement = CardMediaPlacement.Bottom, aspectRatio = aspectRatio },
				}),
			})
		)
	end
	return Grid(examples)
end

local function ActionsStory()
	return Grid({
		Example({
			label = "Overflow",
			LayoutOrder = 1,
			children = VF.Card({ title = "Title", description = DESCRIPTION, onOverflow = noop }),
		}),
		Example({
			label = "Close",
			LayoutOrder = 2,
			children = VF.Card({ title = "Title", description = DESCRIPTION, onClose = noop }),
		}),
		Example({
			label = "Overflow and close, single line",
			LayoutOrder = 3,
			children = VF.Card({ title = "Title", onOverflow = noop, onClose = noop }),
		}),
		Example({
			label = "Over end media",
			LayoutOrder = 4,
			children = VF.Card({
				title = "Title",
				description = DESCRIPTION,
				media = SAMPLE_IMAGE,
				onOverflow = noop,
				onClose = noop,
			}),
		}),
		Example({
			label = "No header",
			LayoutOrder = 5,
			children = VF.Card({ onClose = noop, children = Slot() }),
		}),
		Example({
			label = "Activatable",
			LayoutOrder = 6,
			children = VF.Card({
				title = "Title",
				description = DESCRIPTION,
				onActivated = action("activated"),
				onOverflow = action("overflow"),
			}),
		}),
	})
end

local function HeightStory()
	local function column(height: CardHeight, description: string, layoutOrder: number)
		return VF.View({
			Size = UDim2.new(0.5, -FILL_ROW_GAP / 2, 1, 0),
			tag = "col",
			LayoutOrder = layoutOrder,
			children = VF.Card({ height = height, title = "Title", description = description }),
		})
	end

	local rows = {}
	for index, height in HEIGHT_ORDER do
		rows[index] = Example({
			label = `{height}: two columns {FILL_ROW_HEIGHT}px tall`,
			LayoutOrder = index,
			width = CARD_WIDTH * 2,
			children = VF.View({
				Size = UDim2.new(1, 0, 0, FILL_ROW_HEIGHT),
				layout = { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, FILL_ROW_GAP) },
				children = {
					column(height, DESCRIPTION, 1),
					column(height, LONG_DESCRIPTION, 2),
				},
			}),
		})
	end
	return foundation.scroll(VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y",
		children = rows,
	}))
end

local function LineClampStory()
	return Grid({
		Example({
			label = "No limit",
			LayoutOrder = 1,
			children = VF.Card({ title = "Title", description = LONG_DESCRIPTION }),
		}),
		Example({
			label = "lineClamp = { description = 2 }",
			LayoutOrder = 2,
			children = VF.Card({ title = "Title", description = LONG_DESCRIPTION, lineClamp = { description = 2 } }),
		}),
	})
end

return foundation.sections({
	summary = "Card groups related content in a configurable surface.",
	controls = {
		variant = UILabs.Choose(VARIANT_ORDER),
		density = UILabs.Choose(DENSITY_ORDER),
		height = UILabs.Choose(HEIGHT_ORDER),
		headerSize = UILabs.Choose({ foundation.NONE, table.unpack(HEADER_SIZE_ORDER) }),
		eyebrow = "Eyebrow",
		icon = false,
		title = "Title",
		description = DESCRIPTION,
		media = UILabs.Choose(MEDIA_OPTIONS),
		onOverflow = false,
		onClose = false,
		onActivated = false,
		slot = true,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Variants", summary = "Standard is bordered; Emphasis is filled.", story = VariantsStory },
		{
			name = "Density",
			summary = "Density sets the padding, the corner radius and the default header size.",
			story = DensityStory,
		},
		{ name = "Header sizes", story = HeaderSizesStory },
		{
			name = "Media",
			summary = "A string is an end image. Bottom media spans the card at an aspect ratio.",
			story = MediaStory,
		},
		{
			name = "Actions",
			summary = "Overflow and close sit in the header, or over the card's top right corner without a header or with end media.",
			story = ActionsStory,
		},
		{
			name = "Height",
			summary = "Fit hugs the content. Fill takes the height the parent layout assigns.",
			story = HeightStory,
		},
		{ name = "Line clamp", story = LineClampStory },
	},
})
