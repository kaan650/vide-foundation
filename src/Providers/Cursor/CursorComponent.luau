local ColorNamespace = require("../../Enums/ColorNamespace")
local create = require("../../Utility/create")
local useTokens = require("../Style/useTokens")

type Props = {
	cornerRadius: UDim,
	offset: number,
	borderWidth: number,
	colorNamespace: ColorNamespace.ColorNamespace,
}

local function CursorComponent(props: Props): Frame
	local tokens = useTokens()
	local colorIndex = props.colorNamespace

	return create("Frame")({
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(-props.offset, -props.offset),
		Size = UDim2.new(1, props.offset * 2, 1, props.offset * 2),

		create("UICorner")({
			CornerRadius = props.cornerRadius,
		}),
		create("UIStroke")({
			Color = function()
				return (tokens() :: any)[colorIndex].Selection.Start.Color3
			end,
			Transparency = function()
				return (tokens() :: any)[colorIndex].Selection.Start.Transparency
			end,
			Thickness = props.borderWidth,
		}),
	})
end

return CursorComponent
