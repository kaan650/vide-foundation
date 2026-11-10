local Vide = require("../../Packages/Vide")

local Constants = require("../../Constants")
local Logger = require("../../Utility/Logger")
local Popover = require("../Popover")
local PopoverAlign = require("../../Enums/PopoverAlign")
local PopoverContext = require("../Popover/PopoverContext")
local PopoverSide = require("../../Enums/PopoverSide")
local Radius = require("../../Enums/Radius")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local Wrappers = require("../../Utility/Wrappers")
local useScaledValue = require("../../Utility/useScaledValue")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local UserInputService = Wrappers.Services.UserInputService

type PopoverAlign = PopoverAlign.PopoverAlign
type PopoverSide = PopoverSide.PopoverSide
type PopoverAnchorProps = Popover.PopoverAnchorProps
type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

export type TooltipProps = {
	-- A title for the tooltip. To omit, set it to an empty string.
	title: Value<string>,
	-- Body text for the tooltip.
	text: Value<string?>?,
	-- Shortcut associated with the action owning the tooltip
	shortcut: Value<{ Enum.KeyCode }?>?,
	align: Value<PopoverAlign>?,
	side: Value<PopoverSide>?,
	-- Whether the tooltip should have an arrow. Defaults to true.
	hasArrow: Value<boolean>?,
	children: Types.Children?,
} & Types.CommonProps

local defaultProps = {
	align = PopoverAlign.Start,
	side = PopoverSide.Right,
	hasArrow = true,
	testId = "--foundation-tooltip",
}

type AnchorWrapperProps = {
	onHover: (isHovered: boolean) -> (),
} & PopoverAnchorProps

local function AnchorWrapper(props: AnchorWrapperProps): GuiObject?
	local context = PopoverContext()

	Vide.effect(function()
		local anchor = context.anchor()
		if anchor == nil then
			return
		end
		if typeof(anchor) ~= "Instance" then
			Logger:warning("MeasurableRef cannot be an anchor for the tooltip")
			return
		end
		local guiAnchor = anchor :: GuiObject
		Vide.cleanup(guiAnchor:GetPropertyChangedSignal("GuiState"):Connect(function()
			props.onHover(guiAnchor.GuiState == Enum.GuiState.Hover)
		end))
	end)

	return Popover.Anchor(withCommonProps(props, { children = props.children } :: PopoverAnchorProps))
end

local function getShortcutText(shortcut: { Enum.KeyCode }): string
	local text = ""
	for index, keyCode in shortcut do
		local key = UserInputService:GetStringForKeyCode(keyCode)
		if key == nil or key == "" then
			key = keyCode.Name
		end
		if index > 1 then
			text ..= " + "
		end
		text ..= key
	end
	return text
end

--- A label that opens next to its anchor (`children`) while the pointer hovers it. Returns the anchor, plus the
--- tooltip itself when there is no overlay to render it into.
local function Tooltip(tooltipProps: TooltipProps): { any }
	local props = withDefaults(tooltipProps, defaultProps)
	local isOpen = Vide.source(false)
	local tokens = useTokens()
	local maxXSize = useScaledValue(Constants.TOOLTIP_MAX_WIDTH)
	local testId = props.testId

	local function title(): string
		return Value.read(props.title)
	end
	local function text(): string?
		return Value.read(props.text)
	end
	local function shortcut(): { Enum.KeyCode }?
		return Value.read(props.shortcut)
	end
	local function hasText(): boolean
		local value = text()
		return value ~= nil and value ~= ""
	end

	local function paddingSize(withText: string, withoutText: string): () -> UDim
		return function()
			return UDim.new(0, (tokens().Size :: any)[if hasText() then withText else withoutText])
		end
	end

	local function Title(): GuiObject
		local label = Text({
			LayoutOrder = 1,
			Text = title,
			tag = function()
				return {
					["shrink auto-xy text-truncate-end content-inverse-emphasis"] = true,
					["text-caption-medium"] = hasText(),
					["text-body-small"] = not hasText(),
				}
			end,
			testId = `{testId}--title`,
		})
		label.Name = "Title"
		return label
	end

	local function Shortcut(): GuiObject
		local label = Text({
			LayoutOrder = 2,
			Text = function()
				local keys = shortcut()
				return if keys then getShortcutText(keys) else ""
			end,
			tag = "auto-xy text-body-small content-inverse-muted",
			testId = `{testId}--shortcut`,
		})
		label.Name = "Shortcut"
		return label
	end

	local function Header(): GuiObject
		local header = View({
			LayoutOrder = 1,
			tag = "row flex-between gap-small size-full-0 auto-y",
			children = {
				Vide.show(function()
					return title() ~= ""
				end, Title),
				Vide.show(function()
					return shortcut() ~= nil
				end, Shortcut),
			},
		})
		header.Name = "Header"
		return header
	end

	local function BodyText(): GuiObject
		local label = Text({
			LayoutOrder = 2,
			Text = function()
				return text() or ""
			end,
			tag = "auto-xy text-body-small text-wrap text-align-x-left content-inverse-default",
			testId = `{testId}--text`,
		})
		label.Name = "Text"
		return label
	end

	local function Body(): GuiObject
		local body = View({
			tag = "col gap-xsmall auto-xy",
			padding = {
				top = paddingSize("Size_150", "Size_100"),
				bottom = paddingSize("Size_200", "Size_150"),
				left = paddingSize("Size_200", "Size_150"),
				right = paddingSize("Size_200", "Size_150"),
			},
			sizeConstraint = {
				MaxSize = function()
					return Vector2.new(maxXSize(), math.huge)
				end,
			},
			children = {
				Vide.show(function()
					return title() ~= "" or shortcut() ~= nil
				end, Header),
				Vide.show(hasText, BodyText),
			},
		})
		body.Name = "Children"
		return body
	end

	return Popover.Root({
		isOpen = isOpen,
		testId = testId,
		children = function()
			return {
				AnchorWrapper(withCommonProps(props, {
					onHover = function(isHovered: boolean)
						isOpen(isHovered)
					end,
					children = props.children,
				} :: AnchorWrapperProps)),
				Popover.Content({
					hasArrow = props.hasArrow,
					align = props.align,
					side = function()
						return {
							position = Value.read(props.side),
							offset = tokens().Size.Size_200,
						}
					end,
					radius = Radius.Small,
					backgroundStyle = function()
						return tokens().Inverse.Surface.Surface_0 :: ColorStyleValue
					end,
					selectionGroup = false,
					children = Body,
				}),
			}
		end,
	})
end

return Tooltip
