local foundation = require("../foundation")
local MatrixGrid = require("../Shared/MatrixGrid")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local BannerContext = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/BannerContext")
local InternalNotice = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/InternalNotice")

local BannerContextPresentation =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/BannerContextPresentation")
local BannerContextVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/BannerContextVariant")

type BannerContextPresentation = BannerContextPresentation.BannerContextPresentation
type BannerContextVariant = BannerContextVariant.BannerContextVariant
type InternalNoticeLink = InternalNotice.InternalNoticeLink

local IconName = VF.Enums.IconName

local VARIANTS: { BannerContextVariant } = { BannerContextVariant.Standard, BannerContextVariant.Emphasis }
local PRESENTATIONS: { BannerContextPresentation } =
	{ BannerContextPresentation.Inline, BannerContextPresentation.Affixed }

local NO_ICON = ""
local ICON_OPTIONS = { IconName.CircleI, IconName.TriangleExclamation, IconName.CircleCheck, NO_ICON }

local BANNER_WIDTH = 560
local NARROW_WIDTH = 320
local LONG_TEXT =
	"Your experience is in review. Some features stay unavailable until moderation approves the latest update."

local LINK: InternalNoticeLink = {
	text = "Link",
	onActivated = foundation.action("Link activated"),
}
local onClose = foundation.action("Banner dismissed")

local function Frame(props: { width: number, LayoutOrder: number?, children: any })
	return VF.View({
		tag = "auto-y",
		Size = UDim2.fromOffset(props.width, 0),
		LayoutOrder = props.LayoutOrder,
		children = props.children,
	})
end

local function Labeled(props: { label: string, LayoutOrder: number, width: number?, children: any })
	return VF.View({
		tag = "col gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			Frame({ width = props.width or BANNER_WIDTH, LayoutOrder = 2, children = props.children }),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	--* onClose is a plain callback, so turning the close button on or off builds the banner again.
	return foundation.rebuildOn(controls.hasClose, function(hasClose: boolean)
		return Frame({
			width = BANNER_WIDTH,
			children = BannerContext({
				variant = controls.variant,
				presentation = controls.presentation,
				text = controls.text,
				icon = function()
					local icon = controls.icon()
					return if icon == NO_ICON then nil else icon
				end,
				link = function(): InternalNoticeLink?
					return if controls.hasLink()
						then { text = controls.linkText(), onActivated = LINK.onActivated }
						else nil
				end,
				onClose = if hasClose then onClose else nil,
			}),
		})
	end)
end

local function UsageStory()
	return Frame({
		width = BANNER_WIDTH,
		children = BannerContext({
			variant = BannerContextVariant.Standard,
			presentation = BannerContextPresentation.Inline,
			text = "Banner context",
			icon = IconName.CircleI,
			link = LINK,
			onClose = onClose,
		}),
	})
end

local function VariantsStory()
	local rows: { MatrixGrid.MatrixGridRow } = {}
	for index, presentation in PRESENTATIONS do
		local cells = {}
		for cellIndex, variant in VARIANTS do
			cells[cellIndex] = Frame({
				width = 400,
				children = BannerContext({
					variant = variant,
					presentation = presentation,
					text = "Banner context",
					icon = IconName.CircleI,
					link = LINK,
					onClose = onClose,
				}),
			})
		end
		rows[index] = { label = MatrixGrid.matrixLabel(presentation), cells = cells }
	end
	return MatrixGrid.MatrixGrid({
		labelColumnWidth = 80,
		columnHeaders = VARIANTS :: { string },
		cellColumnWidth = 400,
		rows = rows,
	})
end

local function ContentStory()
	return foundation.scroll(VF.View({
		tag = "col gap-xlarge size-full-0 auto-y",
		children = {
			Labeled({
				label = "Message only",
				LayoutOrder = 1,
				children = BannerContext({ text = "Banner context" }),
			}),
			Labeled({
				label = "Icon and message",
				LayoutOrder = 2,
				children = BannerContext({ text = "Banner context", icon = IconName.CircleI }),
			}),
			Labeled({
				label = "Icon, message and link",
				LayoutOrder = 3,
				children = BannerContext({ text = "Banner context", icon = IconName.CircleI, link = LINK }),
			}),
			Labeled({
				label = "Icon, message, link and close",
				LayoutOrder = 4,
				children = BannerContext({
					text = "Banner context",
					icon = IconName.CircleI,
					link = LINK,
					onClose = onClose,
				}),
			}),
			Labeled({
				label = "Long message truncates to one line",
				LayoutOrder = 5,
				children = BannerContext({
					text = LONG_TEXT,
					icon = IconName.CircleI,
					link = { text = "Learn more", onActivated = LINK.onActivated },
					onClose = onClose,
				}),
			}),
			Labeled({
				label = `Narrow banner ({NARROW_WIDTH}px) stacks the link under the message`,
				LayoutOrder = 6,
				width = NARROW_WIDTH,
				children = BannerContext({
					text = "Banner context",
					icon = IconName.CircleI,
					link = { text = "Learn more", onActivated = LINK.onActivated },
					onClose = onClose,
				}),
			}),
		},
	}))
end

local function DismissStory()
	local isVisible = Vide.source(true)
	return VF.View({
		tag = "col gap-medium auto-xy",
		children = {
			VF.Button({
				text = "Show banner",
				onActivated = function()
					isVisible(true)
				end,
				LayoutOrder = 1,
			}),
			Vide.show(isVisible, function()
				return Frame({
					width = BANNER_WIDTH,
					LayoutOrder = 2,
					children = BannerContext({
						text = "Dismissal is consumer-owned: onClose hides this banner.",
						icon = IconName.CircleI,
						onClose = function()
							isVisible(false)
						end,
					}),
				})
			end),
		},
	})
end

return foundation.sections({
	summary = "BannerContext surfaces contextual information.",
	controls = {
		variant = UILabs.Choose(VARIANTS),
		presentation = UILabs.Choose(PRESENTATIONS),
		text = "Banner context",
		icon = UILabs.Choose(ICON_OPTIONS),
		hasLink = true,
		linkText = "Link",
		hasClose = true,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Usage", story = UsageStory },
		{
			name = "Variants",
			summary = "Standard is bordered and Emphasis filled. Inline sits in the flow; Affixed is full-bleed with edge borders, for sticky positioning.",
			story = VariantsStory,
		},
		{ name = "Content", story = ContentStory },
		{ name = "Dismiss", story = DismissStory },
	},
})
