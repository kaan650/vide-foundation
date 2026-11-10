local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local PaginationSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/PaginationSize")
local PaginationVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/PaginationVariant")

type PaginationProps = VideFoundation.PaginationProps
type PaginationSize = PaginationSize.PaginationSize
type PaginationVariant = PaginationVariant.PaginationVariant

local SIZES: { PaginationSize } = { PaginationSize.Small, PaginationSize.Medium }

local VARIANT_ORDER: { PaginationVariant } = {
	PaginationVariant.MultiPage,
	PaginationVariant.SinglePage,
	PaginationVariant.NoPage,
}

local CONTROLLED_EXAMPLE_COUNT = 10

local STORY_CONTAINER_TAG = "col gap-large size-full-0 auto-y padding-y-large bg-surface-0"

local function noop() end

local function LabeledPagination(props: { label: string, LayoutOrder: number, children: any })
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
				children = props.children,
			}),
		},
	})
end

local function Subsection(props: { label: string, LayoutOrder: number, children: any })
	return VF.View({
		tag = "col gap-medium auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-label-medium text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "col gap-large auto-xy",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function variantProps(variant: PaginationVariant): PaginationProps
	if variant == PaginationVariant.MultiPage then
		return { variant = variant, count = 10, page = 5, onActivated = noop }
	elseif variant == PaginationVariant.SinglePage then
		return { variant = variant, page = 3, count = 10, onActivated = noop }
	end
	return { variant = variant, page = 3, count = 10, onActivated = noop, hasFirstLastButtons = true }
end

local function MultiPageExample(props: {
	count: number,
	label: string,
	LayoutOrder: number,
	page: number,
	size: PaginationSize?,
})
	return LabeledPagination({
		label = props.label,
		LayoutOrder = props.LayoutOrder,
		children = VF.Pagination({
			variant = PaginationVariant.MultiPage,
			count = props.count,
			page = props.page,
			onActivated = noop,
			size = props.size,
		}),
	})
end

local function ControlledPaginationExample(props: { pageLabel: () -> string, children: any })
	return VF.View({
		tag = "col gap-small auto-xy",
		children = {
			VF.Text({
				Text = props.pageLabel,
				tag = "auto-xy text-caption-small text-align-x-left content-muted",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "auto-xy",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

--- A pagination that keeps its page, labelled with it. Without a count, a simulated tenth page is the last.
local function ControlledExample(variant: PaginationVariant, withCount: boolean)
	local page = Vide.source(1)
	local simulatedMaxPage = 10

	local function hasNextPage(): boolean
		return page() < simulatedMaxPage
	end

	return ControlledPaginationExample({
		pageLabel = function()
			if withCount then
				return `Displaying page: {page()}/{CONTROLLED_EXAMPLE_COUNT}`
			end
			return `Displaying page: {page()} · has next: {if hasNextPage() then "true" else "false"}`
		end,
		children = VF.Pagination({
			variant = variant,
			count = if withCount then CONTROLLED_EXAMPLE_COUNT else nil,
			page = page,
			hasNextPage = if withCount then nil else hasNextPage,
			hasPreviousPage = if withCount
				then nil
				else function()
					return page() > 1
				end,
			hasFirstLastButtons = if withCount then true else nil,
			onActivated = function(newPage: number)
				page(newPage)
			end,
		}),
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local function isMultiPage(): boolean
		return controls.variant() == PaginationVariant.MultiPage
	end

	return VF.Pagination({
		variant = controls.variant,
		count = function(): number?
			local count: number = controls.count()
			return if isMultiPage() or count > 0 then count else nil
		end,
		page = controls.page,
		hasNextPage = function(): boolean?
			return if isMultiPage() then nil else controls.hasNextPage()
		end,
		hasPreviousPage = function(): boolean?
			return if isMultiPage() then nil else controls.hasPreviousPage()
		end,
		onActivated = function(page: number)
			print(`{controls.variant()} page: {page}`)
		end,
		size = controls.size,
		hasFirstLastButtons = controls.hasFirstLastButtons,
	})
end

local function SizeStory()
	local children = {}
	for index, size in SIZES do
		children[index] = LabeledPagination({
			label = size,
			LayoutOrder = index,
			children = VF.Pagination({
				variant = PaginationVariant.MultiPage,
				count = 10,
				page = 5,
				onActivated = noop,
				size = size,
			}),
		})
	end
	return VF.View({ tag = STORY_CONTAINER_TAG, children = children })
end

local function VariantsStory()
	local children = {}
	for index, variant in VARIANT_ORDER do
		children[index] = LabeledPagination({
			label = variant,
			LayoutOrder = index,
			children = VF.Pagination(variantProps(variant)),
		})
	end
	return VF.View({ tag = STORY_CONTAINER_TAG, children = children })
end

local function ControlledStory()
	return VF.View({
		tag = STORY_CONTAINER_TAG,
		children = {
			Subsection({
				label = "MultiPage",
				LayoutOrder = 1,
				children = LabeledPagination({
					label = "With count",
					LayoutOrder = 1,
					children = ControlledExample(PaginationVariant.MultiPage, true),
				}),
			}),
			Subsection({
				label = "SinglePage",
				LayoutOrder = 2,
				children = {
					LabeledPagination({
						label = "With count",
						LayoutOrder = 1,
						children = ControlledExample(PaginationVariant.SinglePage, true),
					}),
					LabeledPagination({
						label = "Without count (hasNextPage / hasPreviousPage)",
						LayoutOrder = 2,
						children = ControlledExample(PaginationVariant.SinglePage, false),
					}),
				},
			}),
			Subsection({
				label = "NoPage",
				LayoutOrder = 3,
				children = {
					LabeledPagination({
						label = "With count",
						LayoutOrder = 1,
						children = ControlledExample(PaginationVariant.NoPage, true),
					}),
					LabeledPagination({
						label = "Without count (hasNextPage / hasPreviousPage)",
						LayoutOrder = 2,
						children = ControlledExample(PaginationVariant.NoPage, false),
					}),
				},
			}),
		},
	})
end

local function ContentStory()
	local longCounts = {}
	local firstLastButtons = {}
	for index, size in SIZES do
		longCounts[index] = MultiPageExample({
			count = 1002,
			label = size,
			LayoutOrder = index,
			page = 1000,
			size = size,
		})
		firstLastButtons[index] = LabeledPagination({
			label = size,
			LayoutOrder = index,
			children = VF.Pagination({
				variant = PaginationVariant.MultiPage,
				count = 10,
				page = 5,
				onActivated = noop,
				size = size,
				hasFirstLastButtons = true,
			}),
		})
	end

	return VF.View({
		tag = STORY_CONTAINER_TAG,
		children = {
			Subsection({
				label = "No truncation (≤7 pages)",
				LayoutOrder = 1,
				children = {
					MultiPageExample({ count = 2, label = "2 pages", LayoutOrder = 1, page = 1 }),
					MultiPageExample({ count = 7, label = "7 pages (all slots visible)", LayoutOrder = 2, page = 4 }),
				},
			}),
			Subsection({
				label = "Truncation (>7 pages)",
				LayoutOrder = 2,
				children = {
					MultiPageExample({ count = 9, label = "Page 1 (trailing ellipsis)", LayoutOrder = 1, page = 1 }),
					MultiPageExample({
						count = 9,
						label = "Page 5 (leading and trailing ellipsis)",
						LayoutOrder = 2,
						page = 5,
					}),
					MultiPageExample({ count = 9, label = "Page 9 (leading ellipsis)", LayoutOrder = 3, page = 9 }),
				},
			}),
			Subsection({
				label = "Long page numbers (>999)",
				LayoutOrder = 3,
				children = longCounts,
			}),
			Subsection({
				label = "First and last buttons",
				LayoutOrder = 4,
				children = firstLastButtons,
			}),
		},
	})
end

type KeyboardNavigationWiring = "explicit" | "typical"

local function KeyboardNavigationDemo(props: { LayoutOrder: number, wiring: KeyboardNavigationWiring })
	local page = Vide.source(2)
	local contentAbove = Vide.source(nil :: GuiObject?)
	local contentAboveSecond = Vide.source(nil :: GuiObject?)
	local contentBelow = Vide.source(nil :: GuiObject?)
	local paginationSlot = Vide.source(nil :: GuiObject?)
	local getContentAbove: () -> GuiObject? = contentAbove :: any
	local getContentAboveSecond: () -> GuiObject? = contentAboveSecond :: any
	local getContentBelow: () -> GuiObject? = contentBelow :: any
	local getPaginationSlot: () -> GuiObject? = paginationSlot :: any

	local wireVerticalNeighbors = props.wiring == "explicit"

	local first = VF.Button({
		LayoutOrder = 1,
		text = "Content above (first)",
		onActivated = noop,
		NextSelectionDown = if wireVerticalNeighbors then getPaginationSlot else nil,
		NextSelectionRight = getContentAboveSecond,
		Selectable = true,
		variant = ButtonVariant.Standard,
	})
	contentAbove(first)

	local second = VF.Button({
		LayoutOrder = 2,
		text = "Content above (second)",
		onActivated = noop,
		NextSelectionDown = if wireVerticalNeighbors then getPaginationSlot else nil,
		NextSelectionLeft = getContentAbove,
		Selectable = true,
		variant = ButtonVariant.Standard,
	})
	contentAboveSecond(second)

	local below = VF.Button({
		LayoutOrder = 3,
		text = "Content below",
		onActivated = noop,
		NextSelectionUp = if wireVerticalNeighbors then getPaginationSlot else nil,
		Selectable = true,
		variant = ButtonVariant.Standard,
	})
	contentBelow(below)

	return VF.View({
		tag = "col gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.View({
				LayoutOrder = 1,
				tag = "row gap-small auto-xy",
				children = { first, second },
			}),
			VF.View({
				LayoutOrder = 2,
				tag = "auto-xy",
				children = VF.Pagination({
					ref = function(slot: GuiObject?)
						paginationSlot(slot)
					end,
					variant = PaginationVariant.MultiPage,
					count = 10,
					page = page,
					onActivated = function(newPage: number)
						page(newPage)
					end,
					hasFirstLastButtons = true,
					NextSelectionUp = if wireVerticalNeighbors then getContentAbove else nil,
					NextSelectionDown = if wireVerticalNeighbors then getContentBelow else nil,
				}),
			}),
			below,
		},
	})
end

local function KeyboardNavigationStory()
	return VF.View({
		tag = STORY_CONTAINER_TAG,
		children = {
			VF.Text({
				LayoutOrder = 1,
				Text = "Pagination ref resolves to the first interactive slot. To enter there predictably from siblings, "
					.. "wire NextSelectionDown = paginationRef on controls above and pass NextSelectionUp/NextSelectionDown on Pagination. "
					.. "Without that wiring, the engine may focus any pagination slot.",
				tag = "auto-xy text-body-medium text-wrap text-align-x-left content-default",
			}),
			Subsection({
				label = "Explicit wiring",
				LayoutOrder = 2,
				children = KeyboardNavigationDemo({ LayoutOrder = 1, wiring = "explicit" }),
			}),
			Subsection({
				label = "Unwired (typical)",
				LayoutOrder = 3,
				children = KeyboardNavigationDemo({ LayoutOrder = 1, wiring = "typical" }),
			}),
		},
	})
end

return foundation.sections({
	summary = "Pagination provides navigation controls for paginated content. MultiPage shows page number slots. SinglePage and NoPage share the same props and behavior — variant only controls whether the current page label is shown.",
	controls = {
		variant = UILabs.Choose(VARIANT_ORDER),
		size = UILabs.Choose(SIZES),
		count = 10,
		page = 5,
		hasFirstLastButtons = false,
		hasNextPage = false,
		hasPreviousPage = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Size", story = SizeStory },
		{ name = "Variants", story = VariantsStory },
		{ name = "Controlled component", story = ControlledStory },
		{ name = "Content", story = ContentStory },
		{
			name = "Keyboard navigation",
			summary = "Compare explicit paginationRef wiring with typical unwired vertical focus.",
			story = KeyboardNavigationStory,
		},
	},
})
