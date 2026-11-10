local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local InputSize = VF.Enums.InputSize
local PopoverAlign = VF.Enums.PopoverAlign
local PopoverSide = VF.Enums.PopoverSide
local Radius = VF.Enums.Radius
local StateLayerAffordance = VF.Enums.StateLayerAffordance

type ColorStyleValue = VideFoundation.ColorStyleValue

local Popover = VF.Popover

--* An array, not a map, so the Choose control keeps this order.
local BACKGROUND_STYLE_KEYS = { "Default", "Surface_0", "Surface_200", "ActionAlert" }

local function useBackgroundStyle(key: () -> string): () -> ColorStyleValue
	local tokens = VF.Hooks.useTokens()
	return function()
		local styles: { [string]: ColorStyleValue } = {
			Surface_0 = tokens().Color.Surface.Surface_0 :: ColorStyleValue,
			Surface_200 = tokens().Color.Surface.Surface_200 :: ColorStyleValue,
			ActionAlert = tokens().Color.ActionAlert.Background :: ColorStyleValue,
		}
		--* Default leaves the style nil, so the content falls back to its own surface.
		return styles[key()] :: any
	end
end

local function Card(buttonText: any, onActivated: () -> ())
	--* React's keyed children tie on LayoutOrder and mount in table order, which puts the button above the text.
	return VF.View({
		tag = "col gap-large auto-xy padding-large stroke-neutral radius-medium bg-surface-100",
		children = {
			VF.Button({
				text = buttonText,
				size = InputSize.Medium,
				onActivated = onActivated,
			}),
			VF.Text({
				Text = "I am a card",
				tag = "auto-xy text-heading-medium",
			}),
		},
	})
end

local function TitleContent(title: string, subtitle: string)
	return VF.View({
		tag = "col gap-small auto-xy padding-medium",
		children = {
			VF.Text({
				Text = title,
				tag = "auto-xy text-title-medium content-emphasis",
			}),
			VF.Text({
				Text = subtitle,
				tag = "auto-xy text-body-small",
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local backgroundStyle = useBackgroundStyle(controls.backgroundStyle)

	return VF.View({
		Size = UDim2.new(1, 0, 0, 1000),
		tag = "row align-x-center align-y-center",
		children = Popover.Root({
			isOpen = true,
			children = function()
				return {
					Popover.Anchor({
						children = Card("Just a button!", function()
							print("Button activated")
						end),
					}),
					Popover.Content({
						align = controls.align,
						side = controls.side,
						backgroundStyle = backgroundStyle,
						radius = controls.radius,
						children = function()
							return TitleContent("Tooltip Title", "Here's the tootip's subtitle and content.")
						end,
					}),
				}
			end,
		}),
	})
end

local function ClickOutsideStory(controls: { [string]: any })
	local open = Vide.source(false)

	return VF.View({
		tag = "row align-x-center align-y-center size-full-0 auto-y",
		children = Popover.Root({
			isOpen = open,
			children = function()
				return {
					Popover.Anchor({
						children = Card("Click me to toggle!", function()
							open(not open())
						end),
					}),
					Popover.Content({
						align = controls.align,
						side = controls.side,
						onPressedOutside = function()
							open(false)
						end,
						children = function()
							return TitleContent("Click outside example", "Click anywhere outside to close this")
						end,
					}),
				}
			end,
		}),
	})
end

local function AnchorReferenceStory(controls: { [string]: any })
	local open = Vide.source(false)

	local button = VF.Button({
		text = "Click me to toggle!",
		size = InputSize.Medium,
		onActivated = function()
			open(not open())
		end,
	})

	return VF.View({
		Size = UDim2.new(1, 0, 0, 1000),
		tag = "row align-x-center align-y-center",
		children = {
			button,
			Popover.Root({
				isOpen = open,
				children = function()
					return {
						Popover.Anchor({
							anchorRef = button,
						}),
						Popover.Content({
							align = controls.align,
							side = controls.side,
							onPressedOutside = function()
								open(false)
							end,
							children = function()
								return TitleContent(
									"Anchor Reference Example",
									"This popover is anchored to a button using anchorRef"
								)
							end,
						}),
					}
				end,
			}),
		},
	})
end

local function KeyboardAwareInputStory()
	local open = Vide.source(false)
	local inputText = Vide.source("")

	local popover = Popover.Root({
		isOpen = open,
		children = function()
			return {
				Popover.Anchor({
					children = VF.View({
						tag = "col gap-medium auto-xy",
						children = {
							VF.TextInput({
								size = InputSize.Medium,
								label = "Test Input",
								placeholder = "Type something here...",
								text = inputText,
								onChanged = function(newText: string)
									inputText(newText)
								end,
								onFocusGained = function()
									open(true)
								end,
								onFocusLost = function()
									--* A short delay lets a press inside the popover land before it closes.
									task.delay(0.1, function()
										open(false)
									end)
								end,
							}),
							VF.Button({
								text = function()
									return if open() then "Close Popover" else "Open Popover"
								end,
								size = InputSize.Medium,
								onActivated = function()
									open(not open())
								end,
							}),
						},
					}),
				}),
				Popover.Content({
					side = PopoverSide.Bottom,
					align = PopoverAlign.Start,
					onPressedOutside = function()
						open(false)
					end,
					children = function()
						return VF.View({
							tag = "col gap-small auto-xy padding-medium",
							Size = UDim2.fromOffset(300, 0),
							--* In React's mount order, which is the order of its keyed children table.
							children = {
								VF.Text({
									Text = function()
										return `Current input: "{inputText()}"`
									end,
									tag = "auto-xy text-body-small",
								}),
								VF.Text({
									Text = "Keyboard-Aware Popover",
									tag = "auto-xy text-title-medium content-emphasis",
								}),
								VF.Text({
									Text = "This popover should avoid the on-screen keyboard on touch devices.",
									tag = "auto-xy text-body-small",
								}),
							},
						})
					end,
				}),
			}
		end,
	})

	return VF.View({
		tag = "col align-x-center align-y-center gap-large size-full-0 auto-y",
		children = {
			popover,
			--* Below the popover's anchor, as React mounts them. Vide parents the nested array Popover.Root returns
			--* after its siblings, so only a LayoutOrder keeps this order.
			VF.Text({
				Text = "Focus the input field to test keyboard-aware positioning",
				tag = "auto-xy text-body-medium content-emphasis",
				LayoutOrder = 1,
				padding = {
					bottom = UDim.new(0, 500),
				},
			}),
		},
	})
end

local function FocusablePluginInputStory()
	local open = Vide.source(false)
	local text = Vide.source("")

	return VF.View({
		tag = "size-full-0 auto-y",
		children = Popover.Root({
			isOpen = open,
			children = function()
				return {
					Popover.Anchor({
						children = VF.Button({
							text = function()
								return if open() then "Close focusable popover" else "Open focusable popover"
							end,
							size = InputSize.Medium,
							onActivated = function()
								open(not open())
							end,
						}),
					}),
					Popover.Content({
						isFocusable = true,
						onPressedOutside = function()
							open(false)
						end,
						children = function()
							return VF.View({
								tag = "auto-xy padding-medium",
								children = VF.TextInput({
									label = "Focusable text input",
									text = text,
									onChanged = function(newText: string)
										text(newText)
									end,
									placeholder = "Type or paste here",
								}),
							})
						end,
					}),
				}
			end,
		}),
	})
end

local function MousePositionTooltipStory(controls: { [string]: any })
	local open = Vide.source(false)
	local virtualRef = VF.Hooks.useMeasurableRef(Vector2.zero)

	local wrapper = VF.View({
		tag = "row align-x-center align-y-center size-full-3000 bg-surface-200",
		children = {
			VF.Text({
				Text = "Move the mouse over this area to see a tooltip",
				tag = "text-align-x-center",
			}),
			Popover.Root({
				isOpen = open,
				children = function()
					return {
						Popover.Anchor({ anchorRef = virtualRef }),
						Popover.Content({
							align = controls.align,
							side = controls.side,
							-- hasArrow has no effect on the virtualRef anchors, and is always false
							children = function()
								return VF.View({
									tag = "col gap-small auto-xy padding-medium",
									children = VF.Text({
										Text = "Can't close unless you are in the area",
										tag = "auto-xy text-title-medium content-emphasis",
									}),
								})
							end,
						}),
					}
				end,
			}),
		},
	})

	Vide.cleanup(wrapper.MouseMoved:Connect(function(x, y)
		virtualRef:SetPosition(Vector2.new(x, y))
		open(true)
	end))
	Vide.cleanup(wrapper.MouseLeave:Connect(function()
		open(false)
	end))

	return foundation.scroll(wrapper)
end

local function ContextMenuStory(controls: { [string]: any })
	local open = Vide.source(false)
	local virtualRef = VF.Hooks.useMeasurableRef(Vector2.zero)

	local wrapper = VF.View({
		tag = "align-x-center align-y-center size-full-3000 bg-surface-200",
		stateLayer = {
			affordance = StateLayerAffordance.None,
		},
		onActivated = function() end,
		children = {
			VF.Text({
				Text = "Right-click on this area to open the context menu.",
				tag = "size-full-full text-align-x-center",
			}),
			Popover.Root({
				isOpen = open,
				children = function()
					return {
						Popover.Anchor({ anchorRef = virtualRef }),
						Popover.Content({
							align = controls.align,
							side = controls.side,
							-- hasArrow has no effect on the virtualRef anchors, and is always false
							onPressedOutside = function()
								open(false)
							end,
							children = function()
								return TitleContent("Context Menu", "Right-click functionality enabled.")
							end,
						}),
					}
				end,
			}),
		},
	}) :: GuiButton

	Vide.cleanup(wrapper.MouseButton2Up:Connect(function(x, y)
		virtualRef:SetPosition(Vector2.new(x, y))
		open(true)
	end))

	return foundation.scroll(wrapper)
end

return foundation.sections({
	summary = "Popover",
	controls = {
		side = UILabs.Choose(Dash.values(PopoverSide :: any)),
		align = UILabs.Choose(Dash.values(PopoverAlign :: any)),
		radius = UILabs.Choose({ Radius.Small, Radius.Medium, Radius.Circle }),
		backgroundStyle = UILabs.Choose(BACKGROUND_STYLE_KEYS),
	},
	sections = {
		{
			name = "Playground",
			story = function(controls)
				return foundation.scroll(PlaygroundStory(controls))
			end,
		},
		{ name = "Click Outside", story = ClickOutsideStory },
		{
			name = "Anchor Reference",
			story = function(controls)
				return foundation.scroll(AnchorReferenceStory(controls))
			end,
		},
		{ name = "Keyboard Aware Input", story = KeyboardAwareInputStory },
		{ name = "Focusable Plugin Input", story = FocusablePluginInputStory },
		{ name = "MousePositionTooltip", story = MousePositionTooltipStory },
		{ name = "Context menu", story = ContextMenuStory },
	},
})
