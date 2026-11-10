local Vide = require("../../Packages/Vide")

local BackgroundStyleContext = require("../../Providers/Style/BackgroundStyleContext")
local Icon = require("../Icon")
local InputSize = require("../../Enums/InputSize")
local Motion = require("../../Utility/Motion")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Tokens = require("../../Providers/Style/Tokens")
local Types = require("../Types")
local View = require("../View")
local create = require("../../Utility/create")
local useScrimVariants = require("./useScrimVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")

type InputSize = InputSize.InputSize

local EASE_CONFIG: Motion.EaseOptions = {
	easingStyle = Tokens.defaultTokens.Ease.StandardOut,
	duration = Tokens.defaultTokens.Time.Time_200,
}

-- Both sequences must have the same number of keypoints.
local function lerpNumberSequence(from: NumberSequence, to: NumberSequence, progress: number): NumberSequence
	local fromKeypoints = from.Keypoints
	local toKeypoints = to.Keypoints
	local keypoints = {}
	for index, fromKeypoint in fromKeypoints do
		local toKeypoint = toKeypoints[index]
		keypoints[index] = NumberSequenceKeypoint.new(
			fromKeypoint.Time + (toKeypoint.Time - fromKeypoint.Time) * progress,
			fromKeypoint.Value + (toKeypoint.Value - fromKeypoint.Value) * progress
		)
	end
	return NumberSequence.new(keypoints)
end

export type ScrimProps = {
	size: () -> InputSize,
	rowHeight: () -> number,
	alignment: Enum.HorizontalAlignment,
	isHovered: () -> boolean,
	preferredInput: () -> Enum.PreferredInput,
	isVisible: () -> boolean,
	onActivated: () -> (),
	onStateChanged: Types.StateChangedCallback?,
} & Types.CommonProps

--- The fade at one end of an overflowing row, with a chevron (or a bumper glyph on gamepad) that scrolls the row.
local function Scrim(props: ScrimProps): GuiObject
	local tokens = useTokens()
	local backgroundStyle = BackgroundStyleContext.useBackgroundStyle()
	local variants = Vide.derive(function()
		return useScrimVariants(tokens(), props.alignment, props.preferredInput())
	end)

	local isEnd = props.alignment == Enum.HorizontalAlignment.Right
	local function isAlwaysShown(): boolean
		local preferredInput = props.preferredInput()
		return preferredInput == Enum.PreferredInput.Touch or preferredInput == Enum.PreferredInput.Gamepad
	end

	local progress, setProgress = Motion.useAnimatedBinding(if Vide.untrack(props.isHovered) then 1 else 0)
	Vide.effect(function()
		local target = if props.isHovered() then 1 else 0
		Vide.untrack(function()
			setProgress(Motion.ease(target, EASE_CONFIG))
		end)
	end)

	local transparency, setTransparency = Motion.useAnimatedBinding(if Vide.untrack(props.isVisible) then 0 else 1)
	Vide.effect(function()
		local target = if props.isVisible() then 0 else 1
		Vide.untrack(function()
			setTransparency(Motion.ease(target, EASE_CONFIG))
		end)
	end)

	local icon = Icon({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = function()
			if isAlwaysShown() then
				return UDim2.fromScale(0.5, 0.5)
			end
			local direction = if isEnd then 1 else -1
			return UDim2.fromScale(0.5 + direction * (1 - progress()), 0.5)
		end,
		size = props.size,
		name = function()
			return variants().directionIcon
		end,
		testId = `{props.testId}--direction-indicator`,
	})
	icon.Name = "Icon"

	local directionIcon = View({
		tag = function()
			return variants().iconAlignmentTag
		end,
		Size = UDim2.fromScale(0, 1),
		aspectRatio = {
			AspectRatio = 1,
			AspectType = Enum.AspectType.ScaleWithParentSize,
			DominantAxis = Enum.DominantAxis.Height,
		},
		ZIndex = 2,
		children = icon,
	})
	directionIcon.Name = "DirectionIcon"

	local scrim = View({
		tag = "size-full",
		backgroundStyle = backgroundStyle,
		onActivated = function()
			props.onActivated()
		end,
		stateLayer = {
			affordance = StateLayerAffordance.None,
		},
		onStateChanged = props.onStateChanged,
		isDisabled = function()
			return not props.isVisible()
		end,
		selection = { Selectable = false },
		testId = `{props.testId}--button`,
		children = {
			create("UIGradient")({
				Name = "Gradient",
				Transparency = function()
					local current = variants()
					if isAlwaysShown() then
						return current.hoverGradient
					end
					return lerpNumberSequence(current.gradient, current.hoverGradient, progress())
				end,
			}),
			directionIcon,
		},
	})
	scrim.Name = "Scrim"

	return View(withCommonProps(props, {
		Size = function()
			return UDim2.new(0, props.rowHeight() + variants().fade, 1, 0)
		end,
		GroupTransparency = transparency,
		children = scrim,
	}) :: any)
end

return Scrim
