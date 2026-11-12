local Vide = require("../../Packages/Vide")

local FontScales = require("./FontScales")
local GuiObjectChildren = require("../../Utility/GuiObjectChildren")
local Padding = require("../Padding")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local create = require("../../Utility/create")
local getTestIdTag = require("../../Utility/getTestIdTag")
local normalizeFontFace = require("../../Utility/normalizeFontFace")
local tags = require("../../Utility/tags")
local withDefaults = require("../../Utility/withDefaults")
local withGuiObjectProps = require("../../Utility/withGuiObjectProps")
local withInteractable = require("../Interactable/withInteractable")

type ColorStyle = Types.ColorStyle
type FontStyle = Types.FontStyle
type Value<T> = Types.Value<T>

export type TextProps = {
	textStyle: ColorStyle?,
	fontStyle: Value<FontStyle?>?,
	AutoButtonColor: Value<boolean>?,
	OpenTypeFeatures: Value<string>?,
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
		return if style then Value.read(normalizeFontFace(style.Font)) else nil
	end

	local defaultTags = function(): string
		local style = fontStyle()
		local base = if Value.read(props.backgroundStyle) ~= nil
			then `{DEFAULT_TAGS} x-default-transparency`
			else DEFAULT_TAGS
		return if style and style.FontSize then `{base} x-default-text-size` else base
	end

	--* Line height padding only applies when the caller set no padding, like Foundation's styling does.
	local function lineHeightPadding(): UDim
		--! Foundation passes the offset through a Vector2, whose float32 rounds 3.9999 up to 4 before UDim truncates it.
		return UDim.new(0, Vector2.new(0, getLineHeightPaddingOffset(fontStyle(), fontFace())).Y)
	end
	local function paddingFor(offset: Types.Value<UDim>): Types.PaddingTable
		return { top = offset, bottom = offset, left = UDim.new(0, 0), right = UDim.new(0, 0) }
	end

	local guiObjectProps: any = props
	local reactivePadding: any = nil
	if props.padding == nil and props.fontStyle ~= nil then
		if type(props.fontStyle) == "function" then
			reactivePadding = Vide.show(function()
				return getLineHeightPaddingOffset(fontStyle(), fontFace()) ~= 0
			end, function()
				local padding = Padding({
					value = paddingFor(lineHeightPadding),
					testId = if props.testId then `{props.testId}--padding` else nil,
				})
				padding.Name = "Padding"
				return padding
			end)
		elseif getLineHeightPaddingOffset(fontStyle(), fontFace()) ~= 0 then
			guiObjectProps = table.clone(props)
			guiObjectProps.padding = paddingFor(lineHeightPadding())
		end
	end

	local properties: { [any]: any } = {
		AutoButtonColor = if class == "TextButton" then props.AutoButtonColor else nil,
		OpenTypeFeatures = props.OpenTypeFeatures,
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
		reactivePadding,
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
