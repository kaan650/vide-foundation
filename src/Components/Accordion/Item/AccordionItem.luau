local Vide = require("../../../Packages/Vide")

local BuilderIcons = require("../../../Packages/BuilderIcons")
local IconName = BuilderIcons.Icon
type IconVariant = BuilderIcons.IconVariant

local Divider = require("../../Divider")
local Icon = require("../../Icon")
local InputPlacement = require("../../../Enums/InputPlacement")
local Motion = require("../../../Utility/Motion")
local Text = require("../../Text")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local useAccordion = require("../useAccordion")
local useAccordionItemVariants = require("../useAccordionItemVariants")
local usePreferences = require("../../../Providers/Preferences/usePreferences")
local useTokens = require("../../../Providers/Style/useTokens")
local withCommonProps = require("../../../Utility/withCommonProps")
local withDefaults = require("../../../Utility/withDefaults")

type ItemId = Types.ItemId
type Value<T> = Types.Value<T>

export type AccordionItemIcon = string | {
	name: string,
	variant: IconVariant,
}

export type AccordionItemProps = {
	-- **DEPRECATED**: Use `icon` instead.
	leadingIcon: Value<AccordionItemIcon?>?,
	-- Builder Icon on the side opposite the collapse chevron, with its variant.
	icon: Value<AccordionItemIcon?>?,
	-- Text in the item's header.
	text: Value<string>,
	-- Supplementary text below the title.
	description: Value<string?>?,
	-- Whether a divider closes the item.
	hasDivider: Value<boolean>?,
	-- Replaces both the default toggle and the parent Accordion's onActivated.
	onActivated: (() -> ())?,
	-- Identifies the item to the parent Accordion's onActivated.
	id: ItemId,
	-- Controls expansion.
	isExpanded: Value<boolean>?,
	-- Shown while expanded.
	children: Types.Children?,
} & Types.CommonProps

local defaultProps = {
	hasDivider = true,
	isExpanded = false,
}

--- A header that expands and collapses its content with a height animation.
local function AccordionItem(accordionItemProps: AccordionItemProps): GuiObject
	local props = withDefaults(accordionItemProps, defaultProps)
	local tokens = useTokens()
	local preferences = usePreferences()
	local accordionContext = useAccordion()
	local testId = `{accordionContext.testId}--item-{props.id}`

	local function easeConfig(): Motion.EaseOptions
		local current = tokens()
		return {
			easingStyle = current.Ease.StandardOut,
			duration = current.Time.Time_300,
		}
	end
	local function reducedMotion(): boolean
		return preferences().reducedMotion == true
	end

	local isExpanded = Vide.source(Vide.untrack(function(): boolean
		return Value.read(props.isExpanded) == true
	end))
	local isClosing = false
	local chevronRotation, setChevronRotation = Motion.useAnimatedBinding(0)
	local currentHeight, setCurrentHeight = Motion.useAnimatedBinding(0, function()
		if isClosing then
			isExpanded(false)
			isClosing = false
		end
	end)

	local function onClose()
		if Vide.untrack(reducedMotion) then
			setCurrentHeight(Motion.instant(0))
			setChevronRotation(Motion.instant(0))
			isExpanded(false)
			isClosing = false
			return
		end

		isClosing = true
		local config = Vide.untrack(easeConfig)
		setCurrentHeight(Motion.ease(0, config))
		setChevronRotation(Motion.ease(0, config))
	end

	local function onContentSizeChange(content: GuiObject)
		if Vide.untrack(isExpanded) then
			if Vide.untrack(reducedMotion) then
				setCurrentHeight(Motion.instant(content.AbsoluteSize.Y))
			else
				setCurrentHeight(Motion.ease(content.AbsoluteSize.Y, Vide.untrack(easeConfig)))
			end
		end
	end

	Vide.effect(function()
		local expanded = Value.read(props.isExpanded) == true
		Vide.untrack(function()
			if isExpanded() and not expanded then
				onClose()
			else
				isExpanded(expanded)
			end
		end)
	end)

	Vide.effect(function()
		if isExpanded() then
			local reduced = reducedMotion()
			local config = easeConfig()
			Vide.untrack(function()
				if reduced then
					setChevronRotation(Motion.instant(-180))
				else
					setChevronRotation(Motion.ease(-180, config))
				end
			end)
		end
	end)

	local variantProps = Vide.derive(function()
		return useAccordionItemVariants(tokens(), accordionContext.itemSize(), accordionContext.isContained())
	end)

	local onAccordionItemActivated = accordionContext.onAccordionItemActivated
	local onActivated: () -> ()
	if props.onActivated then
		onActivated = props.onActivated
	elseif onAccordionItemActivated then
		onActivated = function()
			local handler = onAccordionItemActivated(props.id, Vide.untrack(isExpanded))
			if handler then
				handler()
			end
		end
	else
		onActivated = function()
			if Vide.untrack(isExpanded) then
				onClose()
			else
				isExpanded(true)
			end
		end
	end

	local function iconStyle()
		return variantProps().icon.style
	end
	local function iconSize()
		return variantProps().icon.size
	end

	local function hasDescription(): boolean
		return Value.read(props.description) ~= nil
	end
	local function isChevronLeading(): boolean
		return accordionContext.chevronPosition() == InputPlacement.Start
	end

	local getIcon: () -> AccordionItemIcon? = function()
		return Value.read(props.icon) or Value.read(props.leadingIcon)
	end
	local icon = Vide.show(getIcon, function(current: () -> AccordionItemIcon)
		local view = Icon({
			LayoutOrder = function()
				return if isChevronLeading() then 3 else 1
			end,
			name = function()
				local value = current()
				return if type(value) == "table" then value.name else value
			end,
			variant = function(): IconVariant?
				local value = current()
				return if type(value) == "table" then value.variant else nil
			end :: any,
			style = iconStyle,
			size = iconSize,
			testId = `{testId}--leading-icon`,
		})
		view.Name = "Icon"
		return view
	end)

	local function title(hasDescriptionBelow: boolean): GuiObject
		local view = Text({
			LayoutOrder = 2,
			Text = props.text,
			tag = function()
				return {
					[variantProps().text.tag] = true,
					grow = not hasDescriptionBelow,
					["size-full-0"] = hasDescriptionBelow,
				}
			end,
			testId = `{testId}--title`,
		})
		view.Name = "Title"
		return view
	end

	local soloTitle = Vide.show(function()
		return not hasDescription()
	end, function()
		return title(false)
	end)

	local textContainer = Vide.show(hasDescription, function()
		local description = Text({
			LayoutOrder = 3,
			Text = function()
				return Value.read(props.description) or ""
			end,
			TextWrapped = false,
			TextTruncate = Enum.TextTruncate.AtEnd,
			tag = function()
				return variantProps().description.tag
			end,
			testId = `{testId}--description`,
		})
		description.Name = "Description"
		local view = View({
			LayoutOrder = 2,
			tag = function()
				return variantProps().textContainer.tag
			end,
			testId = `{testId}--text-container`,
			children = { title(true), description },
		})
		view.Name = "TextContainer"
		return view
	end)

	local chevron = Icon({
		name = IconName.ChevronLargeDown,
		Rotation = chevronRotation,
		style = iconStyle,
		size = iconSize,
		testId = `{testId}--collapse-icon`,
	})
	chevron.Name = "Icon"
	local collapseIcon = View({
		tag = "auto-xy",
		LayoutOrder = function()
			return if isChevronLeading() then 1 else 3
		end,
		testId = `{testId}--collapse-icon-container`,
		children = chevron,
	})
	collapseIcon.Name = "CollapseIcon"

	local header = View({
		LayoutOrder = 1,
		tag = function()
			return variantProps().header.tag
		end,
		onActivated = function()
			onActivated()
		end,
		testId = `{testId}--header`,
		children = {
			Value.bindProperty("AutomaticSize", function(): Enum.AutomaticSize?
				return if hasDescription() then Enum.AutomaticSize.Y else nil
			end),
			icon,
			soloTitle,
			textContainer,
			collapseIcon,
		},
	})
	header.Name = "Header"

	--* Collapsing only unparents the content view, so the caller's children move into the next one.
	local content = Vide.show(isExpanded, function()
		local animatedContainer = View({
			tag = function()
				return variantProps().content.tag
			end,
			onAbsoluteSizeChanged = onContentSizeChange,
			flexItem = {
				FlexMode = Enum.UIFlexMode.None,
			},
			testId = `{testId}--animated-content`,
			children = props.children,
		})
		animatedContainer.Name = "AnimatedContainer"
		local view = View({
			tag = "col",
			LayoutOrder = 2,
			testId = `{testId}--content`,
			Size = function()
				return UDim2.new(1, 0, 0, currentHeight())
			end,
			ClipsDescendants = true,
			children = animatedContainer,
		})
		view.Name = "Content"
		return view
	end)

	local divider = Vide.show(function()
		return Value.read(props.hasDivider) == true
	end, function()
		local view = Divider({
			LayoutOrder = 3,
			testId = `{testId}--divider`,
		})
		view.Name = "Divider"
		return view
	end)

	local itemProps = table.clone(props)
	itemProps.testId = testId
	return View(withCommonProps(itemProps, {
		tag = function()
			return variantProps().container.tag
		end,
		AutomaticSize = Enum.AutomaticSize.Y,
		stateLayer = Vide.untrack(variantProps).container.stateLayer,
		children = { header, content, divider },
	}) :: any)
end

return AccordionItem
