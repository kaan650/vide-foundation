local Image = require("../Image")
local Motion = require("../../Utility/Motion")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local create = require("../../Utility/create")
local useRotation = require("../../Utility/useRotation")
local useSpinnerMotionStates = require("./useSpinnerMotionStates")

type ColorStyleValue = Types.ColorStyleValue

type SpinnerProps = {
	style: Types.ColorStyle?,
	Size: Types.Value<UDim2>,
	testId: string?,
}

--- The loading spinner Button shows in place of its icon. It grows and fades in when created.
--- FoundationUsePath2DSpinner is off live, so this is the image spinner.
local function Spinner(props: SpinnerProps): GuiObject
	local states = useSpinnerMotionStates()
	local values, animate = Motion.useMotion(states.Default :: any)
	animate(states.Loading :: any)

	local rotation = useRotation(2)
	local style = props.style

	local spinner = Image({
		Image = "icons/status/loading_large",
		imageStyle = function(): ColorStyleValue
			local base: ColorStyleValue = Value.read(style) or {}
			return {
				Color3 = base.Color3,
				Transparency = (base.Transparency :: number) + values.transparency() / 2,
			}
		end,
		Rotation = rotation,
		tag = "position-center-center anchor-center-center size-full-full",
		testId = props.testId,
		children = create("UIScale")({
			Scale = values.scale,
		}),
	})
	spinner.Name = "Spinner"

	return View({
		tag = "position-center-center anchor-center-center",
		Size = props.Size,
		children = spinner,
	})
end

return Spinner
