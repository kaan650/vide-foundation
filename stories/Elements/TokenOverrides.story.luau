local foundation = require("../foundation")
local TokenOverridesStore = require("../Shared/TokenOverridesStore")
local TokenProcessingUtilities = require("../Shared/TokenProcessingUtilities")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash

local ButtonVariant = VF.Enums.ButtonVariant
local InputSize = VF.Enums.InputSize
local PopoverSide = VF.Enums.PopoverSide

type StoryColorOverride = TokenOverridesStore.Override
type ColorLiteral = { Color3: Color3, Transparency: number }
type TokenRef = { key: string, path: string }
type ColorStyleValue = VideFoundation.ColorStyleValue

type OverrideKind = "None" | "Path" | "Custom"

local OverrideKind = {
	None = "None" :: "None",
	Path = "Path" :: "Path",
	Custom = "Custom" :: "Custom",
}

local function isColorStyleLiteral(value: unknown): boolean
	return type(value) == "table"
		and typeof((value :: any).Color3) == "Color3"
		and typeof((value :: any).Transparency) == "number"
end

local function overrideKind(value: StoryColorOverride?): OverrideKind
	if value == nil then
		return OverrideKind.None
	end
	if type(value) == "string" then
		return OverrideKind.Path
	end
	if isColorStyleLiteral(value) then
		return OverrideKind.Custom
	end
	return OverrideKind.None
end

local function getSourceCategories(tokens: any): { string }
	local categories = { "Surface" }
	if tokens and tokens.Color and tokens.Color.Extended then
		for subCategory in tokens.Color.Extended do
			table.insert(categories, subCategory)
		end
	end
	table.sort(categories)
	return categories
end

local function sortByKey(list: { TokenRef })
	table.sort(list, function(a: TokenRef, b: TokenRef)
		return a.key < b.key
	end)
end

local function getTokensInSourceCategory(tokens: any, category: string): { TokenRef }
	local result = {}
	if not tokens or not tokens.Color then
		return result
	end

	if category == "Surface" then
		for key in tokens.Color.Surface or {} do
			table.insert(result, { key = key, path = `Color.Surface.{key}` })
		end
	else
		local extendedTokens = tokens.Color.Extended and tokens.Color.Extended[category]
		for key in extendedTokens or {} do
			table.insert(result, { key = key, path = `Color.Extended.{category}.{key}` })
		end
	end

	sortByKey(result)
	return result
end

local function getTargetTokens(tokens: any, category: string): { TokenRef }
	local result = {}
	if not tokens or not tokens.Color then
		return result
	end

	for key in tokens.Color[category] or {} do
		table.insert(result, { key = key, path = `Color.{category}.{key}` })
	end

	sortByKey(result)
	return result
end

local function initialCategoryFromPath(sourcePath: string): string?
	if string.find(sourcePath, "Color.Surface.") then
		return "Surface"
	end
	return string.match(sourcePath, "Color%.Extended%.([^.]+)%.")
end

local function defaultLiteralFromTarget(tokens: any, targetPath: string): ColorLiteral
	local target = TokenProcessingUtilities.getTokenValue(tokens, targetPath)
	if isColorStyleLiteral(target) then
		return { Color3 = target.Color3, Transparency = target.Transparency }
	end
	local fallback = tokens.Color.Extended.Magenta.Magenta_700
	return { Color3 = fallback.Color3, Transparency = fallback.Transparency }
end

local function PopoverButton(props: { name: string, text: string, onActivated: () -> (), LayoutOrder: number })
	local tokens = VF.Hooks.useTokens()

	local label = VF.View({
		tag = "auto-xy padding-small radius-small",
		backgroundStyle = function()
			return tokens().Color.Surface.Surface_100 :: ColorStyleValue
		end,
		stroke = {
			Color = function()
				return tokens().Color.System.Neutral.Color3
			end,
			Transparency = function()
				return tokens().Color.System.Neutral.Transparency
			end,
			Thickness = 1,
		},
		children = VF.Text({
			Text = props.text,
			fontStyle = function()
				return tokens().Typography.BodyMedium :: any
			end,
			textStyle = function()
				return tokens().Color.Content.Default :: ColorStyleValue
			end,
			tag = "auto-xy",
		}),
	})
	label.Name = `{props.name}Label`

	return VF.UNSTABLE.Interactable({
		Name = props.name,
		onActivated = props.onActivated,
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = props.LayoutOrder,
		label,
	} :: any)
end

local function TokenRow(props: {
	tokenKey: string,
	tokenPath: string,
	tokens: () -> any,
	currentOverride: () -> StoryColorOverride?,
	onChanged: (StoryColorOverride?) -> (),
	LayoutOrder: number,
})
	local currentOverride = props.currentOverride
	local sourceCategories = getSourceCategories(Vide.untrack(props.tokens))

	local initialOverride = Vide.untrack(currentOverride)
	local selectedCategory =
		Vide.source(if type(initialOverride) == "string" then initialCategoryFromPath(initialOverride) else nil)
	local getSelectedCategory: () -> string? = selectedCategory :: any
	local kind = Vide.source(overrideKind(initialOverride))
	local isColorPopoverOpen = Vide.source(false)
	local popoverDraft = Vide.source(nil :: { Color3: Color3, alpha: number }?)
	local getPopoverDraft: () -> { Color3: Color3, alpha: number }? = popoverDraft :: any
	local originalLiteral: ColorLiteral? = nil
	local tokens = VF.Hooks.useTokens()

	Vide.effect(function()
		local override = currentOverride()
		Vide.untrack(function()
			if override ~= nil then
				kind(overrideKind(override))
				selectedCategory(if type(override) == "string" then initialCategoryFromPath(override) else nil)
			else
				--* Clearing the override must not jump Path → None (Custom → Path clears the literal).
				local previous = kind()
				if previous ~= OverrideKind.Path and previous ~= OverrideKind.None then
					kind(OverrideKind.None)
				end
				selectedCategory(nil)
			end
		end)
	end)

	Vide.effect(function()
		if kind() ~= OverrideKind.Custom then
			Vide.untrack(function()
				isColorPopoverOpen(false)
			end)
		end
	end)

	local function displayColor(): (Color3, number)
		local draft = getPopoverDraft()
		if isColorPopoverOpen() and draft then
			return draft.Color3, draft.alpha
		end
		local override = currentOverride()
		if type(override) == "table" and isColorStyleLiteral(override) then
			return override.Color3, 1 - override.Transparency
		end
		return tokens().Color.Extended.Magenta.Magenta_700.Color3, 1
	end

	local function colorHex(): string
		local color = displayColor()
		return string.format(
			"#%02X%02X%02X",
			math.floor(color.R * 255),
			math.floor(color.G * 255),
			math.floor(color.B * 255)
		)
	end

	local categoryItems: { VideFoundation.DropdownItem } = { { id = "__none__", text = "(Pick category)" } }
	for _, category in sourceCategories do
		table.insert(categoryItems, { id = category, text = category })
	end

	local function valueItems(): { VideFoundation.DropdownItem }
		local items: { VideFoundation.DropdownItem } = { { id = "__select__", text = "Select token…" } }
		local category = getSelectedCategory()
		if category then
			for _, token in getTokensInSourceCategory(props.tokens(), category) do
				table.insert(items, { id = token.path, text = token.key })
			end
		end
		return items
	end

	local function closePopover()
		isColorPopoverOpen(false)
		popoverDraft(nil)
	end

	local function isPath(): boolean
		return kind() == OverrideKind.Path
	end

	return VF.View({
		tag = "col gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = VF.View({
			tag = "row align-y-center gap-small auto-xy",
			LayoutOrder = 1,
			children = {
				VF.View({
					tag = "auto-y",
					Size = UDim2.fromOffset(100, 0),
					LayoutOrder = 1,
					children = VF.Text({
						Text = props.tokenKey,
						tag = "auto-xy text-label-small",
					}),
				}),
				VF.SegmentedControl({
					segments = Dash.map(Dash.values(OverrideKind), function(k: OverrideKind)
						return { id = k, text = k }
					end),
					value = kind,
					size = InputSize.Small,
					onActivated = function(id)
						selectedCategory(nil)
						if id == OverrideKind.None then
							kind(OverrideKind.None)
							props.onChanged(nil)
						elseif id == OverrideKind.Path then
							kind(OverrideKind.Path)
							if type(Vide.untrack(currentOverride)) ~= "string" then
								props.onChanged(nil)
							end
						else
							kind(OverrideKind.Custom)
							props.onChanged(defaultLiteralFromTarget(Vide.untrack(props.tokens), props.tokenPath))
						end
					end,
					LayoutOrder = 2,
				}),
				Vide.show(isPath, function()
					return VF.Dropdown.Root({
						label = "",
						value = function()
							return getSelectedCategory() or "__none__"
						end,
						items = categoryItems,
						size = InputSize.Small,
						onItemChanged = function(id)
							selectedCategory(if id == "__none__" then nil else id :: string)
							props.onChanged(nil)
						end,
						width = UDim.new(0, 120),
						LayoutOrder = 3,
					})
				end),
				Vide.show(function()
					return isPath() and getSelectedCategory() ~= nil
				end, function()
					return VF.Dropdown.Root({
						label = "",
						value = function()
							local override = currentOverride()
							return if type(override) == "string" then override else "__select__"
						end,
						items = valueItems,
						size = InputSize.Small,
						onItemChanged = function(id)
							props.onChanged(if id == "__select__" then nil else id :: string)
						end,
						width = UDim.new(0, 200),
						LayoutOrder = 4,
					})
				end),
				Vide.show(function()
					return kind() == OverrideKind.Custom and isColorStyleLiteral(currentOverride())
				end, function()
					return VF.Popover.Root({
						isOpen = isColorPopoverOpen,
						children = function()
							return {
								VF.Popover.Anchor({
									LayoutOrder = 5,
									children = VF.View({
										onActivated = function()
											if Vide.untrack(isColorPopoverOpen) then
												closePopover()
												return
											end
											local literal = Vide.untrack(currentOverride) :: ColorLiteral
											originalLiteral = {
												Color3 = literal.Color3,
												Transparency = literal.Transparency,
											}
											popoverDraft({ Color3 = literal.Color3, alpha = 1 - literal.Transparency })
											isColorPopoverOpen(true)
										end,
										tag = "row align-y-center gap-small size-2500-800 padding-x-small radius-medium clip bg-shift-200",
										children = {
											VF.View({
												LayoutOrder = 1,
												tag = "size-500-500 radius-small",
												children = {
													VF.Image({
														Image = "component_assets/checkerboard_12",
														ScaleType = Enum.ScaleType.Tile,
														TileSize = UDim2.fromOffset(10, 10),
														tag = "size-full radius-small",
														ZIndex = 1,
													}),
													VF.View({
														tag = "size-full radius-small",
														backgroundStyle = function()
															local color, opacity = displayColor()
															return { Color3 = color, Transparency = 1 - opacity }
														end,
														ZIndex = 2,
													}),
												},
											}),
											VF.Text({
												LayoutOrder = 2,
												Text = colorHex,
												tag = "size-0-0 auto-xy text-body-small text-truncate-end content-emphasis",
											}),
										},
									}),
								}),
								VF.Popover.Content({
									side = PopoverSide.Right,
									hasArrow = true,
									onPressedOutside = closePopover,
									children = function()
										local draft = Vide.untrack(getPopoverDraft)
										if not draft then
											return nil
										end
										return VF.View({
											tag = "col gap-medium padding-medium",
											Size = UDim2.fromOffset(300, 300),
											children = {
												VF.Text({
													Text = "Color + alpha → token Color3 and Transparency.",
													tag = "auto-xy text-caption-small",
													LayoutOrder = 0,
												}),
												VF.ColorPicker({
													initialColor = draft.Color3,
													initialAlpha = draft.alpha,
													onColorChanged = function(newColor: Color3)
														local current = Vide.untrack(getPopoverDraft)
														if current then
															popoverDraft({ Color3 = newColor, alpha = current.alpha })
														end
													end,
													onAlphaChanged = function(newAlpha: number)
														local current = Vide.untrack(getPopoverDraft)
														if current then
															popoverDraft({ Color3 = current.Color3, alpha = newAlpha })
														end
													end,
													LayoutOrder = 1,
												}),
												VF.View({
													tag = "row align-x-right gap-small size-full-0 auto-y",
													LayoutOrder = 2,
													children = {
														PopoverButton({
															name = "CancelButton",
															text = "Cancel",
															onActivated = function()
																local original = originalLiteral
																if original then
																	props.onChanged({
																		Color3 = original.Color3,
																		Transparency = original.Transparency,
																	})
																end
																closePopover()
															end,
															LayoutOrder = 1,
														}),
														PopoverButton({
															name = "DoneButton",
															text = "Done",
															onActivated = function()
																local current = Vide.untrack(getPopoverDraft)
																if current then
																	props.onChanged({
																		Color3 = current.Color3,
																		Transparency = 1 - current.alpha,
																	})
																end
																closePopover()
															end,
															LayoutOrder = 2,
														}),
													},
												}),
											},
										})
									end,
								}),
							}
						end,
					})
				end),
				Vide.show(function()
					return currentOverride() ~= nil
				end, function()
					return VF.Button({
						text = "Reset",
						size = InputSize.Small,
						variant = ButtonVariant.Standard,
						onActivated = function()
							kind(OverrideKind.None)
							selectedCategory(nil)
							props.onChanged(nil)
						end,
						LayoutOrder = 6,
					})
				end),
			},
		}),
	})
end

local function createCategoryStory(category: string)
	return function()
		local tokens = VF.Hooks.useTokens()
		local overrides = Vide.source(TokenOverridesStore.get() or {} :: TokenOverridesStore.Overrides)

		Vide.effect(function()
			local current = overrides()
			Vide.untrack(function()
				TokenOverridesStore.set(if next(current) then current else nil)
			end)
		end)

		local rows = {}
		for index, targetToken in getTargetTokens(Vide.untrack(tokens), category) do
			rows[index] = TokenRow({
				tokenKey = targetToken.key,
				tokenPath = targetToken.path,
				tokens = tokens,
				--* A derive, so a row hears only about its own override, as React's effect compares its deps.
				currentOverride = Vide.derive(function()
					return overrides()[targetToken.path]
				end),
				onChanged = function(value)
					local newOverrides = table.clone(Vide.untrack(overrides))
					newOverrides[targetToken.path] = value
					overrides(newOverrides)
				end,
				LayoutOrder = index,
			})
		end

		return foundation.scroll(VF.View({
			tag = "col gap-xsmall auto-xy padding-medium",
			children = rows,
		}))
	end
end

local sections = {}
for _, category in
	{
		"Surface",
		"Shift",
		"OverMedia",
		"ActionAlert",
		"ActionEmphasis",
		"ActionSoftEmphasis",
		"ActionStandard",
		"ActionSubtle",
		"ActionLink",
		"ActionUtility",
		"Content",
		"Stroke",
		"System",
		"Common",
	}
do
	table.insert(sections, { name = category, story = createCategoryStory(category) })
end

return foundation.sections({
	summary = "Configure token overrides (path remap or custom color) for all other stories",
	sections = sections,
})
