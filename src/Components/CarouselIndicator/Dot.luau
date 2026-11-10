local Vide = require("../../Packages/Vide")

local Motion = require("../../Utility/Motion")
local StateLayerMode = require("../../Enums/StateLayerMode")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local useTokens = require("../../Providers/Style/useTokens")

type EaseOptions = Motion.EaseOptions
type Value<T> = Types.Value<T>

local INACTIVE_DOT_TRANSPARENCY = 0.78

type DotProps = {
	colorEaseConfig: Value<EaseOptions>,
	isActive: Value<boolean>,
	maxSize: Value<number>,
	onActivated: ((page: number) -> ())?,
	page: number,
	scale: Value<number>,
	scaleEaseConfig: Value<EaseOptions>,
	-- Receives each instance the dot renders as, and nil with that instance when it goes away.
	ref: (instance: GuiObject?, previous: GuiObject?) -> (),
	LayoutOrder: Value<number>,
	testId: string,
} & Types.SelectionProps

--- One page dot. Its scale and transparency ease to new values. An active dot is not interactable, so with
--- `onActivated` the dot is rebuilt as a Frame or an ImageButton when it becomes active or inactive.
local function Dot(props: DotProps): GuiObject | () -> any
	local tokens = useTokens()

	local function isActive(): boolean
		return Value.read(props.isActive)
	end
	local function dotTransparency(): number
		return if isActive() then tokens().Color.System.Contrast.Transparency or 0 else INACTIVE_DOT_TRANSPARENCY
	end
	local function maxSize(): number
		return Value.read(props.maxSize)
	end

	local animatedScale, setAnimatedScaleGoal = Motion.useAnimatedBinding(Vide.untrack(function(): number
		return Value.read(props.scale)
	end))
	local animatedTransparency, setAnimatedTransparencyGoal = Motion.useAnimatedBinding(Vide.untrack(dotTransparency))

	Vide.effect(function()
		local scale: number = Value.read(props.scale)
		local config: EaseOptions = Value.read(props.scaleEaseConfig)
		Vide.untrack(function()
			setAnimatedScaleGoal(Motion.ease(scale, config))
		end)
	end)
	Vide.effect(function()
		local transparency = dotTransparency()
		local config: EaseOptions = Value.read(props.colorEaseConfig)
		Vide.untrack(function()
			setAnimatedTransparencyGoal(Motion.ease(transparency, config))
		end)
	end)

	local onActivated = props.onActivated
	local function activate()
		local callback = props.onActivated
		if callback and not Vide.untrack(isActive) then
			callback(props.page)
		end
	end

	local function view(interactable: boolean): GuiObject
		local instance = View({
			LayoutOrder = props.LayoutOrder,
			Size = function()
				return UDim2.fromOffset(maxSize(), maxSize())
			end,
			backgroundStyle = function(): Types.ColorStyleValue
				return {
					Color3 = tokens().Color.System.Contrast.Color3,
					Transparency = animatedTransparency(),
				}
			end,
			cornerRadius = function()
				return UDim.new(0, tokens().Radius.Circle)
			end,
			onActivated = if interactable then activate else nil,
			selection = {
				Selectable = props.Selectable,
				NextSelectionUp = props.NextSelectionUp,
				NextSelectionDown = props.NextSelectionDown,
				NextSelectionLeft = props.NextSelectionLeft,
				NextSelectionRight = props.NextSelectionRight,
			},
			stateLayer = {
				mode = function()
					return if isActive() then StateLayerMode.Inverse else StateLayerMode.Default
				end,
			},
			testId = props.testId,
			scale = animatedScale,
		})
		instance.Name = `Page{props.page}`
		props.ref(instance)
		Vide.cleanup(function()
			props.ref(nil, instance)
		end)
		return instance
	end

	if not onActivated then
		return view(false)
	end
	return (Vide.switch :: any)(function()
		return not isActive()
	end)({
		[true] = function()
			return view(true)
		end,
		[false] = function()
			return view(false)
		end,
	})
end

return Dot
