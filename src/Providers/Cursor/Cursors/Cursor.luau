local FoundationImages = require("../../../Packages/FoundationImages")
local Images = FoundationImages.Images

local ColorNamespace = require("../../../Enums/ColorNamespace")
local CursorComponent = require("../CursorComponent")
local CursorType = require("../../../Enums/CursorType")
local create = require("../../../Utility/create")
local getScaledSlice = require("../../../Components/Image/ImageSet/getScaledSlice")
local useTokens = require("../../Style/useTokens")

type CursorType = CursorType.CursorType
type ColorNamespace = ColorNamespace.ColorNamespace

local NAV_HIGHLIGHT_HEIGHT = 3

type SlicedImage = {
	Tag: "SlicedImage",
	Image: string,
	SliceCenter: Rect,
	InsetAdjustment: Vector2,
	Padding: number?,
}

type FixedSizeImage = {
	Tag: "FixedSizeImage",
	Image: string,
	Size: number,
}

type RoundedImage = {
	Tag: "RoundedImage",
	CornerRadius: UDim,
	Offset: number,
	BorderWidth: number,
}

local CURSOR_TYPE_DETAILS: { [CursorType]: SlicedImage | FixedSizeImage | RoundedImage } = {
	[CursorType.BulletUp] = {
		Tag = "SlicedImage",
		Image = "component_assets/bulletUp_17_stroke_3",
		SliceCenter = Rect.new(8, 8, 9, 9),
		InsetAdjustment = Vector2.new(2, 2),
	},
	[CursorType.BulletDown] = {
		Tag = "SlicedImage",
		Image = "component_assets/bulletDown_17_stroke_3",
		SliceCenter = Rect.new(8, 8, 9, 9),
		InsetAdjustment = Vector2.new(2, 2),
	},
	[CursorType.InputFields] = {
		Tag = "SlicedImage",
		Image = "component_assets/circle_22_stroke_3",
		SliceCenter = Rect.new(11, 11, 12, 12),
		InsetAdjustment = Vector2.new(7, 0),
	},
	[CursorType.SelectionCell] = {
		Tag = "SlicedImage",
		Image = "component_assets/square_7_stroke_3",
		SliceCenter = Rect.new(3.5, 3.5, 3.5, 3.5),
		InsetAdjustment = Vector2.new(2, 2),
		Padding = 50,
	},
	[CursorType.SelectedKnob] = {
		Tag = "FixedSizeImage",
		Image = "component_assets/circle_42_stroke_3",
		Size = 42,
	},
	[CursorType.UnselectedKnob] = {
		Tag = "FixedSizeImage",
		Image = "component_assets/circle_52_stroke_3",
		Size = 52,
	},
	[CursorType.InputButton] = { Tag = "RoundedImage", CornerRadius = UDim.new(0, 11), Offset = 11, BorderWidth = 3 },
	[CursorType.RoundedRect] = { Tag = "RoundedImage", CornerRadius = UDim.new(0, 8), Offset = 9, BorderWidth = 3 },
	[CursorType.RoundedRectNoInset] = {
		Tag = "RoundedImage",
		CornerRadius = UDim.new(0, 8),
		Offset = 0,
		BorderWidth = 3,
	},
	[CursorType.RoundedSlot] = { Tag = "RoundedImage", CornerRadius = UDim.new(0, 7), Offset = 0, BorderWidth = 3 },
	[CursorType.SkinToneCircle] = {
		Tag = "RoundedImage",
		CornerRadius = UDim.new(0.5, 0),
		Offset = 0,
		BorderWidth = 3,
	},
	[CursorType.SmallPill] = { Tag = "RoundedImage", CornerRadius = UDim.new(0, 15), Offset = 0, BorderWidth = 3 },
	[CursorType.LargePill] = { Tag = "RoundedImage", CornerRadius = UDim.new(0, 26), Offset = 0, BorderWidth = 3 },
	[CursorType.Square] = { Tag = "RoundedImage", CornerRadius = UDim.new(0, 0), Offset = 2, BorderWidth = 3 },
	[CursorType.Toggle] = { Tag = "RoundedImage", CornerRadius = UDim.new(0, 13), Offset = 0, BorderWidth = 3 },
}

type Props = {
	cursorType: CursorType,
	colorNamespace: ColorNamespace,
}

local function Cursor(props: Props): GuiObject
	local tokens = useTokens()
	local colorIndex = props.colorNamespace

	local function selectionColor(): Color3
		return (tokens() :: any)[colorIndex].Selection.Start.Color3
	end
	local function selectionTransparency(): number
		return (tokens() :: any)[colorIndex].Selection.Start.Transparency
	end

	if props.cursorType == CursorType.NavHighlight then
		return create("Frame")({
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, -NAV_HIGHLIGHT_HEIGHT),
			Size = UDim2.new(1, 0, 0, NAV_HIGHLIGHT_HEIGHT),
			BorderSizePixel = 1,
			BackgroundColor3 = selectionColor,
			BackgroundTransparency = 0,
			BorderColor3 = selectionColor,
		})
	elseif props.cursorType == CursorType.Invisible then
		return create("Frame")({
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		})
	end

	local details = CURSOR_TYPE_DETAILS[props.cursorType]
	if details.Tag == "FixedSizeImage" then
		local image = Images[details.Image]
		local size = UDim2.fromOffset(details.Size, details.Size)
		return create("ImageLabel")({
			ImageContent = Content.fromUri(image.Image),
			BackgroundTransparency = 1,
			ImageRectOffset = image.ImageRectOffset,
			ImageRectSize = image.ImageRectSize,
			Size = size,
			Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
			ImageColor3 = selectionColor,
			ImageTransparency = selectionTransparency,
		})
	elseif details.Tag == "SlicedImage" then
		local image = Images[details.Image]
		local inset = details.InsetAdjustment
		local scaledSlice = getScaledSlice(details.SliceCenter)
		return create("ImageLabel")({
			ImageContent = Content.fromUri(image.Image),
			BackgroundTransparency = 1,
			ImageRectOffset = image.ImageRectOffset,
			ImageRectSize = image.ImageRectSize,
			SliceCenter = scaledSlice.center,
			SliceScale = scaledSlice.scale,
			ScaleType = Enum.ScaleType.Slice,
			Size = UDim2.new(1, inset.X * 2, 1, inset.Y * 2),
			Position = UDim2.fromOffset(-inset.X, -inset.Y),
			ImageColor3 = selectionColor,
			ImageTransparency = selectionTransparency,

			if details.Padding
				then create("UIPadding")({
					PaddingTop = UDim.new(0, details.Padding),
					PaddingBottom = UDim.new(0, details.Padding),
					PaddingLeft = UDim.new(0, details.Padding),
					PaddingRight = UDim.new(0, details.Padding),
				})
				else nil,
		})
	end

	return CursorComponent({
		cornerRadius = details.CornerRadius,
		offset = details.Offset - details.BorderWidth,
		borderWidth = details.BorderWidth,
		colorNamespace = props.colorNamespace,
	})
end

return Cursor
