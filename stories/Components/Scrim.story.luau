local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local Scrim = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/OverflowScrollContainer/Scrim")
local useScrimVariants =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Components/OverflowScrollContainer/useScrimVariants")

type ColorStyleValue = VideFoundation.ColorStyleValue
type InputSize = InputSize.InputSize

local INPUT_SIZES: { InputSize } = {
	InputSize.XSmall,
	InputSize.Small,
	InputSize.Medium,
	InputSize.Large,
}

type ScrimSampleProps = {
	size: () -> InputSize,
	isHovered: (() -> boolean)?,
	preferredInput: (() -> Enum.PreferredInput)?,
	isVisible: (() -> boolean)?,
	LayoutOrder: number?,
}

local function ScrimSample(props: ScrimSampleProps)
	local tokens = VF.Hooks.useTokens()
	local isHovered = props.isHovered or function()
		return false
	end
	local isVisible = props.isVisible or function()
		return true
	end
	local preferredInput = props.preferredInput or function()
		return Enum.PreferredInput.KeyboardAndMouse
	end

	local function stripHeight(): number
		return tokens().Size.Size_1000
	end

	local function Edge(alignment: Enum.HorizontalAlignment, layoutOrder: number)
		return Scrim({
			LayoutOrder = layoutOrder,
			size = props.size,
			rowHeight = stripHeight,
			alignment = alignment,
			isHovered = isHovered,
			preferredInput = preferredInput,
			isVisible = isVisible,
			onActivated = function() end,
		})
	end

	return VF.View({
		LayoutOrder = props.LayoutOrder,
		tag = "col gap-small auto-xy",
		children = {
			VF.Text({
				LayoutOrder = 1,
				Text = function()
					local variants = useScrimVariants(tokens(), Enum.HorizontalAlignment.Left, preferredInput())
					return `{props.size()}, {stripHeight()}px row, {stripHeight() + variants.fade}px scrim`
				end,
				tag = "auto-xy text-caption-large content-emphasis",
			}),
			VF.View({
				LayoutOrder = 2,
				Size = function()
					return UDim2.new(1, 0, 0, stripHeight())
				end,
				sizeConstraint = {
					MaxSize = Vector2.new(600, math.huge),
				},
				children = {
					VF.Text({
						Text = ("Content "):rep(10),
						tag = "size-full-full text-body-medium text-align-x-left",
						backgroundStyle = function(): ColorStyleValue
							return tokens().Inverse.Surface.Surface_0 :: ColorStyleValue
						end,
						textStyle = function(): ColorStyleValue
							return tokens().Inverse.Content.Emphasis :: ColorStyleValue
						end,
					}),
					VF.View({
						tag = "row flex-between size-full-full",
						ZIndex = 2,
						children = {
							Edge(Enum.HorizontalAlignment.Left, 1),
							Edge(Enum.HorizontalAlignment.Right, 2),
						},
					}),
				},
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return ScrimSample({
		size = controls.size,
		isHovered = controls.isHovered,
		preferredInput = controls.preferredInput,
		isVisible = controls.isVisible,
	})
end

local function SizesStory()
	local children = {}
	for index, size in INPUT_SIZES do
		children[index] = ScrimSample({
			LayoutOrder = index,
			size = function()
				return size
			end,
			isHovered = function()
				return false
			end,
			isVisible = function()
				return true
			end,
		})
	end

	return VF.View({
		tag = "col gap-xlarge size-full-0 auto-y",
		children = children,
	})
end

return foundation.sections({
	summary = "",
	controls = {
		size = UILabs.Choose({ InputSize.Medium, InputSize.XSmall, InputSize.Small, InputSize.Large }),
		isHovered = false,
		preferredInput = UILabs.Choose({
			Enum.PreferredInput.KeyboardAndMouse,
			Enum.PreferredInput.Gamepad,
			Enum.PreferredInput.Touch,
		}),
		isVisible = true,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizes", story = SizesStory },
	},
})
