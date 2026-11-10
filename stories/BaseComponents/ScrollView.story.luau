local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

type ColorStyleValue = VideFoundation.ColorStyleValue

local function ColorBlock(tokens: () -> any, color: string)
	return VF.View({
		Size = UDim2.fromOffset(120, 75),
		backgroundStyle = function(): ColorStyleValue
			return tokens().Color.Extended[color][`{color}_500`]
		end,
	})
end

local function ScrollingSample(controls: { [string]: any }, direction: "Vertical" | "Horizontal")
	local tokens = VF.Hooks.useTokens()
	local isVertical = direction == "Vertical"

	return VF.ScrollView({
		Size = UDim2.fromOffset(120, 120),
		layout = {
			FillDirection = if isVertical then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal,
		},
		selection = {
			Selectable = controls.selectable,
		},
		scroll = {
			AutomaticCanvasSize = if isVertical then Enum.AutomaticSize.Y else Enum.AutomaticSize.X,
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollingDirection = if isVertical then Enum.ScrollingDirection.Y else Enum.ScrollingDirection.X,
			scrollBarVisibility = controls.scrollBarVisibility,
		},
		children = {
			ColorBlock(tokens, "Turquoise"),
			ColorBlock(tokens, "Magenta"),
		},
	})
end

local function ScrollingStory(controls: { [string]: any })
	return VF.View({
		tag = "row gap-large auto-xy",
		--* React mounts its keyed children Horizontal first, so it sits on the left.
		children = {
			ScrollingSample(controls, "Horizontal"),
			ScrollingSample(controls, "Vertical"),
		},
	})
end

local function ScrollViewWithTagsStory(controls: { [string]: any })
	local tag = "row gap-medium bg-surface-100 padding-medium radius-medium size-full-3000"

	local items = {}
	for i = 1, 10 do
		items[i] = VF.Text({
			tag = "size-3000-2000 radius-medium bg-shift-100 content-muted",
			Text = `Item {i}`,
			LayoutOrder = i,
		})
	end

	return VF.View({
		tag = "col gap-large size-full-0 auto-y",
		children = {
			VF.ScrollView({
				tag = tag,
				selection = {
					Selectable = controls.selectable,
				},
				scroll = {
					AutomaticCanvasSize = Enum.AutomaticSize.X,
					CanvasSize = UDim2.fromScale(0, 1),
					ScrollingDirection = Enum.ScrollingDirection.X,
				},
				LayoutOrder = 1,
				children = items,
			}),
			VF.Text({
				tag = "size-full-200 text-label-small content-default",
				Text = `tag = {tag}`,
				LayoutOrder = 2,
			}),
		},
	})
end

return foundation.sections({
	summary = "ScrollView",
	controls = {
		scrollBarVisibility = UILabs.Choose({ "Auto", "Always", "None" }),
		selectable = true,
	},
	sections = {
		{ name = "Horizontal and Vertical scrolling", story = ScrollingStory },
		{ name = "ScrollView with tags", story = ScrollViewWithTagsStory },
	},
})
