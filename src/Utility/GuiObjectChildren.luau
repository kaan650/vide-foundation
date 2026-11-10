local Vide = require("../Packages/Vide")

local AspectRatio = require("../Components/AspectRatio")
local CornerRadius = require("../Components/CornerRadius")
local Padding = require("../Components/Padding")
local Types = require("../Components/Types")
local Value = require("./Value")
local create = require("./create")
local getTestIdTag = require("./getTestIdTag")
local tags = require("./tags")

type GuiObjectProps = Types.GuiObjectProps
type CommonProps = Types.CommonProps

local function named<T>(name: string, instance: T): T
	(instance :: any).Name = name
	return instance
end

--- A UI component built from a table prop. A table makes it once, with each field a value or a source. A source of
--- a table (or nil) shows the component only while the table exists, `isPresent` deciding when that is.
local function tableChild(
	value: any,
	class: string,
	name: string,
	keys: { string },
	testId: string?,
	suffix: string,
	isPresent: ((any) -> boolean)?
): any
	if value == nil then
		return nil
	end

	local function build(field: (key: string) -> any, reactive: boolean)
		local properties: { [any]: any } = {
			Name = name,
			tags(getTestIdTag(testId, suffix)),
		}
		for _, key in keys do
			if reactive then
				table.insert(properties, Value.bindProperty(key, field(key)))
			else
				properties[key] = field(key)
			end
		end
		return (create :: any)(class)(properties)
	end

	if type(value) == "function" then
		return Vide.show(function()
			local current = (value :: any)()
			return if current and (not isPresent or isPresent(current)) then current else nil
		end, function(current: () -> any)
			return build(function(key)
				return function()
					return Value.read(current()[key])
				end
			end, true)
		end)
	end

	if isPresent and not isPresent(value) then
		return nil
	end
	return build(function(key)
		return value[key]
	end, false)
end

local function hasFillDirection(layout: Types.ListLayout): boolean
	return layout.FillDirection ~= nil
end

--- The UI components Foundation's GuiObject props turn into (corner, padding, layout...), plus `props.children`.
--- Names match the keys Foundation renders them under.
local function GuiObjectChildren(props: GuiObjectProps & CommonProps): { any }
	local testId = props.testId
	local children: { any } = {}

	if props.children ~= nil then
		table.insert(children, props.children)
	end

	if props.aspectRatio ~= nil then
		table.insert(
			children,
			named(
				"AspectRatio",
				AspectRatio({ value = props.aspectRatio, testId = if testId then `{testId}--aspect-ratio` else nil })
			)
		)
	end

	if props.cornerRadius ~= nil then
		table.insert(
			children,
			named(
				"CornerRadius",
				CornerRadius({ value = props.cornerRadius, testId = if testId then `{testId}--corner-radius` else nil })
			)
		)
	end

	table.insert(
		children,
		tableChild(
			props.flexItem,
			"UIFlexItem",
			"FlexItem",
			{ "FlexMode", "GrowRatio", "ShrinkRatio", "ItemLineAlignment" },
			testId,
			"flex-item"
		)
	)

	table.insert(
		children,
		tableChild(props.layout, "UIListLayout", "ListLayout", {
			"FillDirection",
			"ItemLineAlignment",
			"HorizontalAlignment",
			"HorizontalFlex",
			"VerticalAlignment",
			"VerticalFlex",
			"Padding",
			"SortOrder",
			"Wraps",
		}, testId, "list-layout", hasFillDirection)
	)

	table.insert(
		children,
		tableChild(
			props.sizeConstraint,
			"UISizeConstraint",
			"SizeConstraint",
			{ "MaxSize", "MinSize" },
			testId,
			"size-constraint"
		)
	)

	if props.padding ~= nil then
		table.insert(
			children,
			named("Padding", Padding({ value = props.padding, testId = if testId then `{testId}--padding` else nil }))
		)
	end

	if props.scale ~= nil then
		table.insert(
			children,
			create("UIScale")({
				Name = "Scale",
				Scale = props.scale,
				tags(getTestIdTag(testId, "scale")),
			})
		)
	end

	table.insert(
		children,
		tableChild(
			props.stroke,
			"UIStroke",
			"Stroke",
			{ "Color", "Thickness", "Transparency", "LineJoinMode", "BorderStrokePosition" },
			testId,
			"stroke"
		)
	)

	return children
end

return GuiObjectChildren
