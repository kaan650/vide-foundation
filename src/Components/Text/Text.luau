local FontScales = require("./FontScales")
local GuiObjectChildren = require("../../Utility/GuiObjectChildren")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local create = require("../../Utility/create")
local getTestIdTag = require("../../Utility/getTestIdTag")
local tags = require("../../Utility/tags")
local withDefaults = require("../../Utility/withDefaults")
local withGuiObjectProps = require("../../Utility/withGuiObjectProps")
local withInteractable = require("../Interactable/withInteractable")

type ColorStyle = Types.ColorStyle
type FontFace = Types.FontFace
type FontFaceTable = Types.FontFaceTable
type FontStyle = Types.FontStyle
type Value<T> = Types.Value<T>

export type TextProps = {
	textStyle: ColorStyle?,
	fontStyle: Value<FontStyle?>?,
	AutoButtonColor: Value<boolean>?,
	RichText: Value<boolean>?,
	Text: Value<string>?,
	TextDirection: Value<Enum.TextDirection>?,
	TextScaled: Value<boolean>?,
	TextTruncate: Value<Enum.TextTruncate>?,
	TextWrapped: Value<boolean>?,
	TextXAlignment: Value<Enum.TextXAlignment>?,
	TextYAlignment: Value<Enum.TextYAlignment>?,
} & Types.GuiObjectProps & Types.CommonProps

local defaultProps = {
	AutoLocalize = false,
	AutoButtonColor = false,
	BorderSizePixel = 0,
	isDisabled = false,
}

local DEFAULT_TAGS = "gui-object-defaults text-defaults text-size-defaults text-color-defaults"

local function toFont(font: FontFace?): Font?
	if typeof(font) == "table" then
		local fontTable = font :: FontFaceTable
		return Font.new(fontTable.Family, fontTable.Weight, fontTable.Style)
	elseif typeof(font) == "EnumItem" then
		return Font.fromEnum(font :: Enum.Font)
	end
	return Value.read(font :: Value<Font>?)
end

--- Half the extra height `LineHeight` adds, so text sits where Foundation's design expects it.
local function getLineHeightPaddingOffset(fontStyle: FontStyle?, fontFace: Font?): number
	if fontStyle == nil or fontStyle.LineHeight == nil or fontStyle.FontSize == nil or fontFace == nil then
		return 0
	end
	local nominalScale = FontScales[fontFace.Family]
	if nominalScale == nil then
		return 0
	end
	local rawTextSize = fontStyle.FontSize / nominalScale
	local rawLineHeight = fontStyle.LineHeight * nominalScale
	return (rawTextSize * rawLineHeight - fontStyle.FontSize) / 2
end

--- Foundation's text: a TextLabel, or a TextButton when it handles input.
local function Text(textProps: TextProps): GuiObject
	local props = withDefaults(textProps, defaultProps)
	local isInteractable = props.onStateChanged ~= nil or props.onActivated ~= nil or props.onSecondaryActivated ~= nil
	local class = if isInteractable then "TextButton" else "TextLabel"

	local function fontStyle(): FontStyle?
		return Value.read(props.fontStyle)
	end
	local function fontFace(): Font?
		local style = fontStyle()
		return if style then toFont(style.Font) else nil
	end

	local defaultTags = function(): string
		local style = fontStyle()
		local base = if props.backgroundStyle ~= nil then `{DEFAULT_TAGS} x-default-transparency` else DEFAULT_TAGS
		return if style and style.FontSize then `{base} x-default-text-size` else base
	end

	--* Line height padding only applies when the caller set no padding, like Foundation's styling does.
	local guiObjectProps = props
	if props.padding == nil and props.fontStyle ~= nil then
		local isStatic = type(props.fontStyle) ~= "function"
		local staticOffset = if isStatic then getLineHeightPaddingOffset(fontStyle(), fontFace()) else nil
		if not isStatic or staticOffset ~= 0 then
			local offset = function(): UDim
				return UDim.new(0, getLineHeightPaddingOffset(fontStyle(), fontFace()))
			end
			guiObjectProps = table.clone(props)
			guiObjectProps.padding = {
				top = offset,
				bottom = offset,
				left = UDim.new(0, 0),
				right = UDim.new(0, 0),
			}
		end
	end

	local properties: { [any]: any } = {
		AutoButtonColor = if class == "TextButton" then props.AutoButtonColor else nil,
		RichText = props.RichText,
		Text = props.Text,
		TextDirection = props.TextDirection,
		TextScaled = props.TextScaled,
		TextTruncate = props.TextTruncate,
		TextWrapped = props.TextWrapped,
		TextXAlignment = props.TextXAlignment,
		TextYAlignment = props.TextYAlignment,
		tags(defaultTags, props.tag, getTestIdTag(props.testId)),
		GuiObjectChildren(guiObjectProps),
	}

	if props.fontStyle ~= nil then
		table.insert(properties, Value.bindProperty("FontFace", fontFace))
		table.insert(
			properties,
			Value.bindProperty("LineHeight", function()
				local style = fontStyle()
				return if style then style.LineHeight else nil
			end)
		)
		table.insert(
			properties,
			Value.bindProperty("TextSize", function()
				local style = fontStyle()
				return if style then style.FontSize else nil
			end)
		)
	end

	local textStyle = props.textStyle
	if textStyle ~= nil then
		if type(textStyle) == "function" then
			table.insert(properties, Value.bindProperty("TextColor3", Value.index(textStyle, "Color3")))
			table.insert(properties, Value.bindProperty("TextTransparency", Value.index(textStyle, "Transparency")))
		else
			properties.TextColor3 = textStyle.Color3
			properties.TextTransparency = textStyle.Transparency
		end
	end

	withGuiObjectProps.withGuiObjectProps(props, properties)

	if isInteractable then
		local backgroundStyle = props.backgroundStyle
		withInteractable({
			BackgroundColor3 = if backgroundStyle then Value.index(backgroundStyle, "Color3") else nil,
			BackgroundTransparency = if backgroundStyle then Value.index(backgroundStyle, "Transparency") else nil,
			SelectionImageObject = if props.selection then props.selection.SelectionImageObject else nil,
			isDisabled = props.isDisabled,
			onActivated = props.onActivated,
			onSecondaryActivated = props.onSecondaryActivated,
			onStateChanged = props.onStateChanged,
			stateLayer = props.stateLayer,
			cursor = props.cursor,
		}, properties)
	else
		withGuiObjectProps.backgroundProperties(props, properties)
	end

	return (create :: any)(class)(properties)
end

return Text
