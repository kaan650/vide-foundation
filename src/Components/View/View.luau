local GuiObjectChildren = require("../../Utility/GuiObjectChildren")
local Logger = require("../../Utility/Logger")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local create = require("../../Utility/create")
local getTestIdTag = require("../../Utility/getTestIdTag")
local tags = require("../../Utility/tags")
local withDefaults = require("../../Utility/withDefaults")
local withGuiObjectProps = require("../../Utility/withGuiObjectProps")
local withInteractable = require("../Interactable/withInteractable")

type Value<T> = Types.Value<T>
type ListLayout = Types.ListLayout
type GuiObjectProps = Types.GuiObjectProps
type CommonProps = Types.CommonProps

export type ViewProps = {
	-- Fades the view and its descendants. Makes the view a CanvasGroup.
	GroupTransparency: Value<number>?,
} & GuiObjectProps & CommonProps

local defaultProps = {
	layout = {
		SortOrder = Enum.SortOrder.LayoutOrder,
	} :: ListLayout,
	AutoLocalize = false,
	BorderSizePixel = 0,
	isDisabled = false,
}

local DEFAULT_TAGS = "gui-object-defaults"
local DEFAULT_TAGS_WITH_BG = `{DEFAULT_TAGS} x-default-transparency`

local warnedAboutGroupTransparency = false

--- Foundation's base container: a Frame, an ImageButton when it handles input, or a CanvasGroup when it fades.
local function View(viewProps: ViewProps): GuiObject
	local props = withDefaults(viewProps, defaultProps)

	local isInteractable = props.onStateChanged ~= nil or props.onActivated ~= nil or props.onSecondaryActivated ~= nil
	local groupTransparency = props.GroupTransparency
	--* A source may become non-zero later, so it always needs a CanvasGroup.
	local usesCanvasGroup = groupTransparency ~= nil
		and (type(groupTransparency) == "function" or (groupTransparency :: number) > 0)

	local class = if usesCanvasGroup then "CanvasGroup" elseif isInteractable then "ImageButton" else "Frame"
	if usesCanvasGroup and isInteractable and not Value.read(props.isDisabled) and not warnedAboutGroupTransparency then
		warnedAboutGroupTransparency = true
		Logger:warning("Some state changes are not supported with GroupTransparency")
	end

	local properties: { [any]: any } = {
		GroupTransparency = if usesCanvasGroup then groupTransparency else nil,
		--* ImageButton is needed for some state changes (Enter triggering SelectedPressed), but its auto color is not.
		AutoButtonColor = if class == "ImageButton" then false else nil,
		tags(
			function()
				return if Value.read(props.backgroundStyle) ~= nil then DEFAULT_TAGS_WITH_BG else DEFAULT_TAGS
			end,
			props.tag,
			getTestIdTag(props.testId)
		),
		GuiObjectChildren(props),
	}
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

return View
