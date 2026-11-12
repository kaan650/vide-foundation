local Vide = require("../../../Packages/Vide")

local BuilderIcons = require("../../../Packages/BuilderIcons")

local Checkbox = require("../../Checkbox")
local Divider = require("../../Divider")
local Icon = require("../../Icon")
local InputSize = require("../../../Enums/InputSize")
local ListAccessory = require("./ListAccessory")
local ListItemInputType = require("../../../Enums/ListItemInputType")
local RadioGroup = require("../../RadioGroup")
local Text = require("../../Text")
local Toggle = require("../../Toggle")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local devAssert = require("../../../Utility/devAssert")
local escapeRichText = require("../../../Utility/escapeRichText")
local getTestIdTag = require("../../../Utility/getTestIdTag")
local named = require("../../../Utility/named")
local rebuildOn = require("../../../Utility/rebuildOn")
local useList = require("../useList")
local useListAccessoryVariants = require("./useListAccessoryVariants")
local useListItemVariants = require("./useListItemVariants")
local useTokens = require("../../../Providers/Style/useTokens")

type InputSize = InputSize.InputSize
type ListAccessory = ListAccessory.ListAccessory
type ListItemInputType = ListItemInputType.ListItemInputType
type Value<T> = Types.Value<T>

local RADIO_VALUE = "radio"

local DESCRIPTION_GAP_TAG: { [InputSize]: string } = {
	[InputSize.XSmall] = "gap-xxsmall",
	[InputSize.Small] = "gap-xxsmall",
	[InputSize.Medium] = "gap-xsmall",
	[InputSize.Large] = "gap-xsmall",
}

-- The trailing input accessory. Use the `"Chevron"`/`"None"` string shorthands for the static accessories,
-- or a config object to select an interactive control (Checkbox / Toggle / Radio) with its checked state
-- and an `onActivated(checked)` handler that activates only the input (see `ListItemProps.input`).
--
-- `Chevron`/`None` are not valid config-object `type`s: a chevron is a static icon and `None` renders
-- nothing, so `isChecked`/`onActivated` would be dead. Pass them as the string shorthands instead.
export type ListItemInput = "Chevron" | "None" | {
	type: "Checkbox" | "Toggle" | "Radio",
	isChecked: Value<boolean?>?,
	onActivated: ((boolean) -> ())?,
}

export type ListItemTitle = string | {
	title: string?,
	metadata: string?,
}

-- **DEPRECATED** The legacy coupled form of `onActivated`, which also selects the input.
export type ListItemActivationConfig = {
	onActivated: () -> (),
	inputType: ListItemInputType?,
	isChecked: Value<boolean?>?,
}

export type ListItemProps = {
	-- Leading accessory: an icon-name string, or a `ListAccessory` config (Avatar / Media / Icon).
	leading: Value<(string | ListAccessory)?>?,
	-- Custom trailing content rendered in the trailing slot (alongside or instead of an input accessory).
	trailing: Types.Children?,
	-- Row title: a plain string, or `{ title, metadata }` to render secondary metadata next to the title.
	title: Value<ListItemTitle?>?,
	-- Secondary description line shown under the title.
	description: Value<string?>?,
	-- Activates the WHOLE item: runs when the row is tapped. As a plain function the trailing accessory
	-- defaults to a chevron.
	--
	-- Activation belongs in exactly one place — either here (whole item) OR on `input.onActivated` (the
	-- trailing input), never both. Passing both throws in dev. Priority: when the trailing input is
	-- tapped, its own `input.onActivated` runs if set; otherwise it falls back to this item-level handler.
	--
	-- **DEPRECATED** The config-object form `{ onActivated, inputType, isChecked }` is the legacy coupled
	-- API that also selected the input. Prefer a plain function together with the `input` prop.
	onActivated: ((() -> ()) | ListItemActivationConfig)?,
	-- Trailing input accessory, chosen independently of whether the row is tappable. Either the `"Chevron"`/
	-- `"None"` string shorthands, or `{ type, isChecked, onActivated }` for an interactive control (Checkbox
	-- / Toggle / Radio) where `onActivated(checked)` activates ONLY the input and takes priority over the
	-- item-level `onActivated`. Set one owner of activation, not both.
	input: Value<ListItemInput?>?,
	-- Runs on a secondary activation (right click) of the whole item.
	onSecondaryActivated: ((self: GuiObject, inputObject: InputObject) -> ())?,
} & Types.SelectionProps & Types.CommonProps

type ResolvedInput = {
	type: ListItemInputType?,
	isChecked: Value<boolean?>?,
	onActivated: ((boolean) -> ())?,
}

type ActivatedIcon = "Chevron" | "Radio" | "Checkbox" | "Toggle"
type DividerKind = "Inset" | "Full"

--- One row of a `List.Root`: leading accessory, title, metadata and description, trailing content and an optional
--- input. Create it inside the list's `children`. Of the common props only `LayoutOrder` and `testId` are used.
local function ListItem(props: ListItemProps): GuiObject
	local listContext = useList()
	local tokens = useTokens()

	local itemOnActivated = props.onActivated
	local configTable: ListItemActivationConfig? = if type(itemOnActivated) == "table"
			and itemOnActivated.onActivated ~= nil
		then itemOnActivated
		else nil
	local onActivated: (() -> ())? = if configTable
		then configTable.onActivated
		elseif type(itemOnActivated) == "function" then itemOnActivated
		else nil

	local function input(): ListItemInput?
		return Value.read(props.input) :: ListItemInput?
	end

	Vide.effect(function()
		local current = input()
		devAssert(
			not (itemOnActivated ~= nil and type(current) == "table" and current.onActivated ~= nil),
			"ListItem: set `onActivated` on the item or on `input`, not both."
		)
	end)

	local function resolvedInput(): ResolvedInput?
		local current = input()
		if current ~= nil then
			if type(current) == "table" then
				return { type = current.type, isChecked = current.isChecked, onActivated = current.onActivated }
			end
			return { type = current }
		elseif configTable then
			return { type = configTable.inputType or ListItemInputType.Chevron, isChecked = configTable.isChecked }
		elseif itemOnActivated ~= nil then
			return { type = ListItemInputType.Chevron }
		end
		return nil
	end

	local function size(): InputSize
		return listContext.size() or InputSize.Medium
	end

	local variantProps = Vide.derive(function()
		return useListItemVariants(tokens(), size())
	end)

	local function title(): string?
		local current: ListItemTitle? = Value.read(props.title)
		if type(current) == "string" then
			return current
		elseif type(current) == "table" then
			return current.title
		end
		return nil
	end

	local function metadata(): string?
		local current: ListItemTitle? = Value.read(props.title)
		if type(current) == "table" then
			return if current.title ~= nil then current.metadata else nil
		end
		return nil
	end

	local explicitTestId = props.testId
	local function testId(): string
		if explicitTestId then
			return explicitTestId
		end
		local current = title()
		local sanitizedTitle = if current then string.gsub(current, "%s+", "-") else ""
		return `{listContext.testId}--item-{sanitizedTitle}`
	end
	local testIdValue: Value<string> = if explicitTestId or type(props.title) ~= "function"
		then Vide.untrack(testId)
		else testId

	local function isChecked(): boolean?
		local resolved = resolvedInput()
		return if resolved then Value.read(resolved.isChecked) else nil
	end

	local function onInputActivated(checked: boolean)
		local resolved = Vide.untrack(resolvedInput)
		if resolved and resolved.onActivated then
			resolved.onActivated(checked)
		elseif onActivated then
			onActivated()
		end
	end

	local function getLeading(): (string | ListAccessory)?
		return Value.read(props.leading)
	end
	local leading = Vide.show(getLeading, function(config: () -> string | ListAccessory)
		return named(
			"LeadingContainer",
			ListAccessory({
				config = config,
				size = size,
				testId = function()
					return `{Value.read(testIdValue)}--leading-accessory`
				end,
				LayoutOrder = 0,
			})
		)
	end)

	local titleContainer = Vide.show(title, function(currentTitle: () -> string)
		return named(
			"TitleContainer",
			View({
				tag = "col auto-xy",
				LayoutOrder = 0,
				children = {
					named(
						"Title",
						Text({
							Text = function()
								return escapeRichText(currentTitle())
							end,
							RichText = true,
							tag = function()
								return variantProps().title.tag
							end,
							LayoutOrder = 0,
						})
					),
					Vide.show(metadata, function(currentMetadata: () -> string)
						return named(
							"Metadata",
							Text({
								Text = currentMetadata,
								RichText = true,
								tag = function()
									return variantProps().metadata.tag
								end,
								LayoutOrder = 1,
							})
						)
					end),
				},
			})
		)
	end)

	local function getDescription(): string?
		return Value.read(props.description)
	end
	local description = Vide.show(getDescription, function(currentDescription: () -> string)
		return named(
			"Description",
			Text({
				Text = currentDescription,
				RichText = true,
				tag = function()
					return variantProps().description.tag
				end,
				LayoutOrder = 1,
			})
		)
	end)

	local textContainer = named(
		"TextContainer",
		View({
			tag = function()
				return {
					["col fill auto-y padding-y-xsmall"] = true,
					[DESCRIPTION_GAP_TAG[size()]] = true,
				}
			end,
			LayoutOrder = 1,
			children = { titleContainer, description },
		})
	)

	local trailingContainer = if props.trailing ~= nil
		then named(
			"TrailingContainer",
			View({
				tag = "align-x-center align-y-center auto-xy",
				LayoutOrder = 2,
				children = props.trailing,
			})
		)
		else nil

	local function activatedIcon(): ActivatedIcon?
		local resolved = resolvedInput()
		if resolved == nil or resolved.type == ListItemInputType.None then
			return nil
		end
		local inputType = resolved.type
		if inputType == nil or inputType == ListItemInputType.Chevron then
			return "Chevron"
		elseif inputType == ListItemInputType.Radio then
			return "Radio"
		end
		return if inputType == ListItemInputType.Checkbox then "Checkbox" else "Toggle"
	end

	--* Icon's testId is fixed at creation, so a title that renames the item rebuilds the chevron.
	local function chevron(id: string): GuiObject
		return Icon({
			name = BuilderIcons.Icon.ChevronLargeRight,
			size = function()
				return variantProps().icon.size
			end,
			testId = `{id}--activated-icon`,
		})
	end

	local activatedIcons: { [ActivatedIcon]: () -> any } = {
		Chevron = function()
			return named("ActivatedIcon", rebuildOn(testIdValue, chevron))
		end,
		Radio = function()
			return named(
				"ActivatedIcon",
				RadioGroup.Root({
					value = function()
						return if isChecked() then RADIO_VALUE else ""
					end,
					onValueChanged = function(value: string)
						onInputActivated(value == RADIO_VALUE)
					end,
					Selectable = false,
					children = function()
						return named(
							"RadioGroupContext",
							RadioGroup.Item({
								value = RADIO_VALUE,
								label = "",
								size = size,
							})
						)
					end,
				})
			)
		end,
		Checkbox = function()
			return named(
				"ActivatedIcon",
				Checkbox({
					label = "",
					onActivated = onInputActivated,
					isChecked = isChecked,
					size = size,
					Selectable = false,
				})
			)
		end,
		Toggle = function()
			return named(
				"ActivatedIcon",
				Toggle({
					label = "",
					onActivated = onInputActivated,
					isChecked = isChecked,
					size = size,
					Selectable = false,
				})
			)
		end,
	}

	local activatedIconContainer = Vide.show(function()
		return activatedIcon() ~= nil
	end, function()
		return named(
			"ActivatedIconContainer",
			View({
				tag = "align-x-center align-y-center auto-xy",
				LayoutOrder = 3,
				children = Vide.switch(activatedIcon)(activatedIcons :: any),
			})
		)
	end)

	local content = named(
		"Content",
		View({
			tag = "row flex-between align-x-center align-y-center fill gap-medium auto-y",
			LayoutOrder = 1,
			children = { textContainer, trailingContainer, activatedIconContainer },
		})
	)

	local listItem = named(
		"ListItem",
		View({
			tag = function()
				return `row align-y-center gap-medium size-full-0 auto-y padding-y-small radius-medium {getTestIdTag(
					Value.read(testIdValue)
				)}`
			end,
			children = { leading, content },
		})
	)

	local listItemContainer = named(
		"ListItemContainer",
		View({
			onActivated = onActivated :: any,
			onSecondaryActivated = props.onSecondaryActivated,
			tag = function()
				local margin = listContext.hasMargin()
				return {
					["size-full-0 auto-y radius-medium"] = true,
					["margin-x-small"] = margin,
					["padding-x-small"] = not margin,
				}
			end,
			children = listItem,
		})
	)

	local function sidePadding(): UDim
		local current = tokens()
		return UDim.new(
			0,
			if listContext.isContained() or listContext.hasMargin()
				then current.Padding.Small
				else -current.Padding.Small
		)
	end
	local function verticalPadding(): UDim
		return UDim.new(0, if listContext.isContained() then tokens().Padding.Small else 0)
	end

	local hoverWrapper = named(
		"HoverWrapper",
		View({
			padding = {
				top = verticalPadding,
				bottom = verticalPadding,
				left = sidePadding,
				right = sidePadding,
			},
			tag = "size-full-0 auto-y padding-y-xsmall",
			LayoutOrder = 1,
			children = listItemContainer,
		})
	)

	local function dividerKind(): DividerKind?
		if not listContext.hasDivider() or Value.read(props.LayoutOrder) == listContext.lastLayoutOrder() then
			return nil
		end
		return if listContext.isInset() then "Inset" else "Full"
	end

	local dividers: { [DividerKind]: () -> GuiObject } = {
		Inset = function()
			local leadingSpacer = named(
				"LeadingSpacer",
				View({
					Size = function()
						local current = tokens()
						local margin = if listContext.hasMargin()
							then current.Padding.Small + current.Margin.Small
							else 0
						local leadingWidth = if getLeading() ~= nil
							then useListAccessoryVariants(current, size(), "Icon").container.Size.X.Offset
								+ current.Gap.Medium
							else 0
						return UDim2.fromOffset(margin + leadingWidth, 0)
					end,
					LayoutOrder = 0,
				})
			)
			local dividerLine = named(
				"DividerLine",
				View({
					tag = "fill auto-y",
					LayoutOrder = 1,
					children = named("Children", Divider({})),
				})
			)
			return named(
				"Divider",
				View({
					tag = "row size-full-0 auto-y",
					LayoutOrder = 2,
					children = { leadingSpacer, dividerLine },
				})
			)
		end,
		Full = function()
			return named("Divider", Divider({ LayoutOrder = 2 }))
		end,
	}

	return View({
		tag = "col size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			hoverWrapper,
			Vide.switch(dividerKind)(dividers :: any),
		},
	})
end

return ListItem
