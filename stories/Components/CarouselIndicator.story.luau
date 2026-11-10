local foundation = require("../foundation")
local VF = foundation.VF
local Vide = foundation.Vide

local DEFAULT_COUNT = 5
local OVERFLOW_COUNT = 10

local function PlaygroundStory(controls: { [string]: any })
	return VF.View({
		tag = "align-x-center align-y-center gap-large size-full-2000 padding-large bg-surface-0",
		children = VF.UNSTABLE.CarouselIndicator({
			page = controls.page,
			count = controls.count,
			onActivated = function(page)
				print(`CarouselIndicator activated {page}`)
			end,
		}),
	})
end

local function InteractiveStory()
	local page = Vide.source(1)

	return VF.View({
		tag = "col align-x-center align-y-center gap-large size-full-2000 padding-large bg-surface-0",
		children = {
			VF.Text({
				LayoutOrder = 1,
				Text = function()
					return `Page {page()} of {OVERFLOW_COUNT}`
				end,
				tag = "auto-xy text-body-medium content-default",
			}),
			VF.UNSTABLE.CarouselIndicator({
				LayoutOrder = 2,
				page = page,
				count = OVERFLOW_COUNT,
				onActivated = function(newPage)
					page(newPage)
				end,
			}),
		},
	})
end

local function IndicatorExample(props: { layoutOrder: number, label: string, page: number, count: number })
	return VF.View({
		LayoutOrder = props.layoutOrder,
		tag = "col align-x-center gap-small auto-xy",
		children = {
			VF.Text({
				LayoutOrder = 1,
				Text = props.label,
				tag = "auto-xy text-caption-medium content-default",
			}),
			VF.UNSTABLE.CarouselIndicator({
				LayoutOrder = 2,
				page = props.page,
				count = props.count,
			}),
		},
	})
end

local function pages(count: number): { any }
	local children = {}
	for page = 1, count do
		children[page] = IndicatorExample({
			page = page,
			layoutOrder = page,
			label = tostring(page),
			count = count,
		})
	end
	return children
end

local function DefaultStory()
	return VF.View({
		tag = "row align-y-center gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = pages(DEFAULT_COUNT),
	})
end

local function OverflowStory()
	return VF.View({
		tag = "row wrap align-y-center gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = pages(OVERFLOW_COUNT),
	})
end

local function PaginationExample(props: { LayoutOrder: number, label: string, count: number })
	local page = Vide.source(1)

	return VF.View({
		LayoutOrder = props.LayoutOrder,
		tag = "col align-x-center gap-large auto-xy",
		children = {
			VF.Text({
				LayoutOrder = 1,
				Text = function()
					return `{props.label}: Page {page()} / {props.count}`
				end,
				tag = "auto-xy text-body-medium content-default",
			}),
			VF.View({
				LayoutOrder = 2,
				tag = "row align-y-center gap-medium auto-xy",
				children = {
					VF.Button({
						LayoutOrder = 1,
						text = "<",
						isDisabled = function()
							return page() == 1
						end,
						onActivated = function()
							page(math.max(page() - 1, 1))
						end,
					}),
					VF.Button({
						LayoutOrder = 2,
						text = ">",
						isDisabled = function()
							return page() == props.count
						end,
						onActivated = function()
							page(math.min(page() + 1, props.count))
						end,
					}),
				},
			}),
			VF.UNSTABLE.CarouselIndicator({
				LayoutOrder = 3,
				page = page,
				count = props.count,
			}),
		},
	})
end

local function PaginationStory()
	return VF.View({
		tag = "row wrap align-x-center align-y-center gap-xxlarge size-full-2000 padding-large bg-surface-0",
		children = {
			PaginationExample({ LayoutOrder = 1, label = "Default", count = DEFAULT_COUNT }),
			PaginationExample({ LayoutOrder = 2, label = "Overflow", count = OVERFLOW_COUNT }),
		},
	})
end

return foundation.sections({
	summary = "CarouselIndicator",
	controls = {
		page = 1,
		count = 5,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Interactive",
			summary = "A stateful carousel navigation example that updates the active page on activation",
			story = InteractiveStory,
		},
		{ name = "Default", summary = "Default carousel indicator pages 1 through 5", story = DefaultStory },
		{ name = "Overflow", summary = "Overflow carousel indicator pages 1 through 10", story = OverflowStory },
		{
			name = "Pagination",
			summary = "Arrow buttons driving default and overflow carousel indicators",
			story = PaginationStory,
		},
	},
})
