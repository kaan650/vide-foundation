local AspectRatio = require("../Components/AspectRatio")
local CornerRadius = require("../Components/CornerRadius")
local Padding = require("../Components/Padding")
local Types = require("../Components/Types")
local create = require("./create")
local getTestIdTag = require("./getTestIdTag")
local tags = require("./tags")

type GuiObjectProps = Types.GuiObjectProps
type CommonProps = Types.CommonProps

--- The UI components Foundation's GuiObject props turn into (corner, padding, layout...), plus `props.children`.
local function GuiObjectChildren(props: GuiObjectProps & CommonProps): { any }
	local testId = props.testId
	local children: { any } = {}

	if props.children ~= nil then
		table.insert(children, props.children)
	end

	if props.aspectRatio ~= nil then
		table.insert(
			children,
			AspectRatio({ value = props.aspectRatio, testId = if testId then `{testId}--aspect-ratio` else nil })
		)
	end

	if props.cornerRadius ~= nil then
		table.insert(
			children,
			CornerRadius({ value = props.cornerRadius, testId = if testId then `{testId}--corner-radius` else nil })
		)
	end

	local flexItem = props.flexItem
	if flexItem ~= nil then
		table.insert(
			children,
			create("UIFlexItem")({
				FlexMode = flexItem.FlexMode,
				GrowRatio = flexItem.GrowRatio,
				ShrinkRatio = flexItem.ShrinkRatio,
				ItemLineAlignment = flexItem.ItemLineAlignment,
				tags(getTestIdTag(testId, "flex-item")),
			})
		)
	end

	local layout = props.layout
	if layout ~= nil and layout.FillDirection ~= nil then
		table.insert(
			children,
			create("UIListLayout")({
				FillDirection = layout.FillDirection,
				ItemLineAlignment = layout.ItemLineAlignment,
				HorizontalAlignment = layout.HorizontalAlignment,
				HorizontalFlex = layout.HorizontalFlex,
				VerticalAlignment = layout.VerticalAlignment,
				VerticalFlex = layout.VerticalFlex,
				Padding = layout.Padding,
				SortOrder = layout.SortOrder,
				Wraps = layout.Wraps,
				tags(getTestIdTag(testId, "list-layout")),
			})
		)
	end

	local sizeConstraint = props.sizeConstraint
	if sizeConstraint ~= nil then
		table.insert(
			children,
			create("UISizeConstraint")({
				MaxSize = sizeConstraint.MaxSize,
				MinSize = sizeConstraint.MinSize,
				tags(getTestIdTag(testId, "size-constraint")),
			})
		)
	end

	if props.padding ~= nil then
		table.insert(children, Padding({ value = props.padding, testId = if testId then `{testId}--padding` else nil }))
	end

	if props.scale ~= nil then
		table.insert(
			children,
			create("UIScale")({
				Scale = props.scale,
				tags(getTestIdTag(testId, "scale")),
			})
		)
	end

	local stroke = props.stroke
	if stroke ~= nil then
		table.insert(
			children,
			create("UIStroke")({
				Color = stroke.Color,
				Thickness = stroke.Thickness,
				Transparency = stroke.Transparency,
				LineJoinMode = stroke.LineJoinMode,
				BorderStrokePosition = stroke.BorderStrokePosition,
				tags(getTestIdTag(testId, "stroke")),
			})
		)
	end

	return children
end

return GuiObjectChildren
