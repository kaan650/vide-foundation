local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local foundation = require("../foundation")
local VF = foundation.VF
local Vide = foundation.Vide

local Breakpoint = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/Breakpoint")
local BreakpointConfig = require("@game/ReplicatedStorage/Packages/VideFoundation/Utility/Responsive/BreakpointConfig")
local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local Orientation = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/Orientation")

type Breakpoint = Breakpoint.Breakpoint
type ColorStyleValue = VideFoundation.ColorStyleValue
type HeaderBarAction = VideFoundation.HeaderBarAction

local IconName = VF.Enums.IconName
local HeaderBar = VF.HeaderBar

local function StoryWrapper(controls: { [string]: any }, children: any)
	local tokens = VF.Hooks.useTokens()

	--* HeaderBar blends in with the story background, so the wrapper uses a different one.
	return VF.View({
		tag = "col gap-small size-full-0 auto-y padding-large",
		--* No background when hasBackground is off; View resets the color when the style reads nil.
		backgroundStyle = function(): ColorStyleValue
			return (if controls.hasBackground() then tokens().Inverse.Surface.Surface_0 else nil) :: any
		end,
		children = children,
	})
end

local function Title(controls: { [string]: any }, layoutOrder: number?)
	return VF.Text({
		tag = "auto-xy text-heading-medium content-emphasis",
		Text = controls.title,
		LayoutOrder = layoutOrder,
	})
end

local function TrailingIconButtons()
	return {
		VF.IconButton({
			icon = IconName.MagnifyingGlass,
			onActivated = function()
				print("Search activated")
			end,
			LayoutOrder = 1,
		}),
		VF.IconButton({
			icon = IconName.Robux,
			onActivated = function()
				print("Robux activated")
			end,
			LayoutOrder = 2,
		}),
		VF.IconButton({
			icon = IconName.Bell,
			onActivated = function()
				print("Notifications activated")
			end,
			LayoutOrder = 3,
		}),
	}
end

local function isCompact(breakpoint: Breakpoint): boolean
	return breakpoint == Breakpoint.XSmall or breakpoint == Breakpoint.Small
end

local function PlaygroundStory(controls: { [string]: any })
	local isSearchOpen = Vide.source(false)

	return StoryWrapper(
		controls,
		HeaderBar.Root({
			hasBackground = controls.hasBackground,
			children = function()
				return {
					HeaderBar.Leading({
						children = function()
							return {
								HeaderBar.Actions({
									actions = {
										{
											id = "menu",
											icon = IconName.ThreeBarsHorizontal,
											onActivated = function()
												print("Toggle menu")
											end,
										},
									},
								}),
								Title(controls, 2),
							}
						end,
					}),
					HeaderBar.Content({
						children = function()
							return Vide.show(isSearchOpen, function()
								return VF.SearchInput({
									text = "",
									onChanged = function() end,
								})
							end)
						end,
					}),
					HeaderBar.Trailing({
						children = function()
							return HeaderBar.Actions({
								actions = {
									{
										id = "search",
										icon = IconName.MagnifyingGlass,
										onActivated = function()
											isSearchOpen(not isSearchOpen())
										end,
									},
									{
										id = "robux",
										icon = IconName.Robux,
										onActivated = function()
											print("Robux")
										end,
									},
									{
										id = "notifications",
										icon = IconName.Bell,
										onActivated = function()
											print("Notifications")
										end,
									},
								},
							})
						end,
					}),
				}
			end,
		})
	)
end

local LEADING_ACTIONS: { HeaderBarAction } = {
	{
		id = "menu",
		icon = IconName.ThreeBarsHorizontal,
		onActivated = function()
			print("Toggle menu")
		end,
	},
}

local TRAILING_ACTIONS: { HeaderBarAction } = {
	{
		id = "search",
		icon = IconName.MagnifyingGlass,
		onActivated = function()
			print("Search")
		end,
	},
	{
		id = "robux",
		icon = IconName.Robux,
		onActivated = function()
			print("Robux")
		end,
	},
	{
		id = "notifications",
		icon = IconName.Bell,
		onActivated = function()
			print("Notifications")
		end,
	},
}

local function NegativeMarginsStory(controls: { [string]: any })
	return StoryWrapper(controls, {
		HeaderBar.Root({
			hasBackground = controls.hasBackground,
			LayoutOrder = 1,
			children = function()
				return {
					HeaderBar.Leading({
						children = function()
							return {
								HeaderBar.Actions({ actions = LEADING_ACTIONS }),
								Title(controls, 2),
							}
						end,
					}),
					HeaderBar.Trailing({
						children = function()
							return HeaderBar.Actions({ actions = TRAILING_ACTIONS })
						end,
					}),
				}
			end,
		}),
		HeaderBar.Root({
			hasBackground = controls.hasBackground,
			LayoutOrder = 2,
			children = function()
				return {
					HeaderBar.Leading({
						children = function()
							return Title(controls)
						end,
					}),
					HeaderBar.Trailing({
						children = function()
							return HeaderBar.Actions({ actions = TRAILING_ACTIONS })
						end,
					}),
				}
			end,
		}),
		HeaderBar.Root({
			hasBackground = controls.hasBackground,
			LayoutOrder = 3,
			children = function()
				return {
					HeaderBar.Leading({
						children = function()
							return {
								HeaderBar.Actions({ actions = LEADING_ACTIONS }),
								Title(controls, 2),
							}
						end,
					}),
					HeaderBar.Trailing({
						children = function()
							return VF.Button({
								text = "Sign in",
								onActivated = function()
									print("Sign in")
								end,
							})
						end,
					}),
				}
			end,
		}),
	})
end

local function DualPaneStory(controls: { [string]: any })
	local container = Vide.source(nil :: GuiObject?)
	local breakpoint = VF.Hooks.useBreakpoint(container)
	local isMessageViewVisible = Vide.source(false)

	local function isMessageViewCollapsed(): boolean
		return isCompact(breakpoint())
	end
	local function showChatHistory(): boolean
		return not isMessageViewCollapsed() or not isMessageViewVisible()
	end
	local function showMessageView(): boolean
		return not isMessageViewCollapsed() or isMessageViewVisible()
	end

	local story = VF.View({
		tag = "row size-full-0 auto-y stroke-default bg-surface-0",
		sizeConstraint = {
			MaxSize = Vector2.new(math.huge, 300),
		},
		LayoutOrder = 1,
		children = {
			Vide.show(showChatHistory, function()
				return VF.View({
					tag = "col shrink size-full",
					sizeConstraint = {
						MaxSize = Vector2.new(BreakpointConfig.widths[Breakpoint.Small], math.huge),
					},
					LayoutOrder = 1,
					children = {
						HeaderBar.Root({
							hasBackground = controls.hasBackground,
							LayoutOrder = 1,
							children = function()
								return {
									HeaderBar.Leading({
										children = function()
											return Title(controls, 1)
										end,
									}),
									HeaderBar.Trailing({
										children = TrailingIconButtons,
									}),
								}
							end,
						}),
						VF.View({
							tag = "col fill gap-medium size-full-0 padding-large",
							LayoutOrder = 2,
							children = {
								VF.Text({
									tag = "size-full-0 auto-y text-body-medium text-align-x-left content-default",
									Text = "Recent conversations",
									LayoutOrder = 1,
								}),
								VF.Button({
									text = "Username",
									variant = ButtonVariant.Standard,
									size = InputSize.Medium,
									width = UDim.new(1, 0),
									onActivated = function()
										isMessageViewVisible(true)
									end,
									LayoutOrder = 2,
								}),
							},
						}),
					},
				})
			end),
			Vide.show(function()
				return not isMessageViewCollapsed()
			end, function()
				return VF.Divider({
					orientation = Orientation.Vertical,
					LayoutOrder = 2,
				})
			end),
			Vide.show(showMessageView, function()
				return VF.View({
					tag = "col fill size-full",
					LayoutOrder = 3,
					children = {
						HeaderBar.Root({
							hasBackground = controls.hasBackground,
							LayoutOrder = 1,
							children = function()
								return {
									HeaderBar.Leading({
										children = function()
											return {
												Vide.show(isMessageViewCollapsed, function()
													return VF.IconButton({
														icon = IconName.ChevronLargeLeft,
														isCircular = true,
														onActivated = function()
															isMessageViewVisible(false)
														end,
														LayoutOrder = 1,
													})
												end),
												VF.View({
													tag = "row align-y-center gap-small auto-xy",
													LayoutOrder = 2,
													children = {
														VF.Avatar({
															userId = 24813339,
															size = InputSize.Medium,
															LayoutOrder = 1,
														}),
														VF.View({
															tag = "col auto-xy",
															LayoutOrder = 2,
															children = {
																VF.Text({
																	tag = "auto-xy text-label-medium content-emphasis",
																	Text = "Username",
																	LayoutOrder = 1,
																}),
																VF.Text({
																	tag = "auto-xy text-body-small content-default",
																	Text = "@handle",
																	LayoutOrder = 2,
																}),
															},
														}),
													},
												}),
											}
										end,
									}),
									HeaderBar.Trailing({
										children = function()
											return VF.Button({
												text = "Button",
												variant = ButtonVariant.Standard,
												size = InputSize.Medium,
												onActivated = function()
													print("Button activated")
												end,
												LayoutOrder = 1,
											})
										end,
									}),
								}
							end,
						}),
						VF.Text({
							tag = "fill size-full-0 padding-large text-body-medium text-align-x-left text-align-y-top content-default",
							Text = "Conversation pane",
							LayoutOrder = 2,
						}),
					},
				})
			end),
		},
	})
	container(story)

	return StoryWrapper(controls, story)
end

local function MenuLeadingAccessoryStory(controls: { [string]: any })
	local container = Vide.source(nil :: GuiObject?)
	local breakpoint = VF.Hooks.useBreakpoint(container)

	--* React sets the ref after the new view mounts. Setting it while the switch below builds the view would make
	--* the switch rerun from inside itself, and until its tags are styled the view is 0 wide, which reads as XSmall
	--* and swaps the layout back.
	local function measure(view: GuiObject)
		task.defer(function()
			if view.AbsoluteSize.X > 0 then
				container(view)
			else
				view:GetPropertyChangedSignal("AbsoluteSize"):Once(function()
					task.defer(function()
						container(view)
					end)
				end)
			end
		end)
	end

	local function MobileStory()
		local view = VF.View({
			tag = "col size-full-0 auto-y stroke-default bg-surface-0",
			LayoutOrder = 1,
			children = {
				HeaderBar.Root({
					hasBackground = controls.hasBackground,
					LayoutOrder = 1,
					children = function()
						return {
							HeaderBar.Leading({
								children = function()
									return {
										VF.IconButton({
											icon = IconName.ThreeBarsHorizontal,
											onActivated = function()
												print("Menu activated")
											end,
											LayoutOrder = 1,
										}),
										VF.Text({
											tag = "auto-xy text-heading-medium content-emphasis",
											Text = "ROBLOX",
											LayoutOrder = 2,
										}),
									}
								end,
							}),
							HeaderBar.Trailing({
								children = TrailingIconButtons,
							}),
						}
					end,
				}),
				VF.Text({
					tag = "auto-xy padding-large text-body-medium content-default",
					Text = "Mobile menu lives in HeaderBar.",
					LayoutOrder = 2,
				}),
			},
		})
		measure(view)
		return view
	end

	local function DesktopStory()
		local view = VF.View({
			tag = "row size-full-0 auto-y stroke-default bg-surface-0",
			LayoutOrder = 1,
			children = {
				VF.View({
					tag = "col gap-small padding-medium bg-surface-0",
					Size = UDim2.new(0, 72, 1, 0),
					LayoutOrder = 1,
					children = VF.IconButton({
						icon = IconName.ThreeBarsHorizontal,
						onActivated = function()
							print("Menu activated")
						end,
						LayoutOrder = 1,
					}),
				}),
				VF.View({
					tag = "col size-full-0",
					Size = UDim2.new(1, -72, 1, 0),
					LayoutOrder = 2,
					children = {
						HeaderBar.Root({
							hasBackground = controls.hasBackground,
							LayoutOrder = 1,
							children = function()
								return {
									HeaderBar.Leading({
										children = function()
											return VF.Text({
												tag = "auto-xy text-heading-medium content-emphasis",
												Text = "ROBLOX",
												LayoutOrder = 1,
											})
										end,
									}),
									HeaderBar.Trailing({
										children = TrailingIconButtons,
									}),
								}
							end,
						}),
						VF.Text({
							tag = "auto-xy padding-large text-body-medium content-default",
							Text = "Collapsed nav leaves logo content in HeaderBar.",
							LayoutOrder = 2,
						}),
					},
				}),
			},
		})
		measure(view)
		return view
	end

	return StoryWrapper(
		controls,
		foundation.rebuildOn(function()
			return isCompact(breakpoint())
		end, function(isMobile: boolean)
			return if isMobile then MobileStory() else DesktopStory()
		end)
	)
end

local function TitlePositioningStory(controls: { [string]: any })
	local container = Vide.source(nil :: GuiObject?)
	local breakpoint = VF.Hooks.useBreakpoint(container)

	local function titleInHeader(): boolean
		return isCompact(breakpoint())
	end

	local function Breadcrumb(text: string, layoutOrder: number, tag: string?)
		return VF.Text({
			tag = tag or "auto-xy text-body-medium content-default",
			Text = text,
			LayoutOrder = layoutOrder,
		})
	end

	local story = VF.View({
		tag = "col size-full-0 auto-y stroke-default bg-surface-0",
		LayoutOrder = 1,
		children = {
			HeaderBar.Root({
				hasBackground = controls.hasBackground,
				LayoutOrder = 1,
				children = function()
					return {
						HeaderBar.Leading({
							children = function()
								return {
									Vide.show(function()
										return not titleInHeader()
									end, function()
										return VF.IconButton({
											icon = IconName.ThreeBarsHorizontal,
											onActivated = function()
												print("Menu activated")
											end,
											LayoutOrder = 1,
										})
									end),
									Vide.show(function()
										return not titleInHeader()
									end, function()
										return VF.View({
											tag = "row align-y-center gap-small auto-xy",
											LayoutOrder = 2,
											children = {
												Breadcrumb("Link", 1),
												Breadcrumb("/", 2),
												Breadcrumb("Link", 3),
												Breadcrumb("/", 4),
												Breadcrumb("Link", 5, "auto-xy text-label-medium content-emphasis"),
											},
										})
									end, function()
										return Title(controls, 1)
									end),
								}
							end,
						}),
						HeaderBar.Trailing({
							children = TrailingIconButtons,
						}),
					}
				end,
			}),
			Vide.show(function()
				return not titleInHeader()
			end, function()
				return VF.View({
					tag = "row align-y-center size-full-1200 padding-x-large",
					LayoutOrder = 2,
					children = Title(controls, 1),
				})
			end),
			VF.Text({
				tag = "auto-xy padding-large text-body-medium content-default",
				Text = function()
					return if titleInHeader()
						then "Title is inside HeaderBar."
						else "Title is positioned below HeaderBar."
				end,
				LayoutOrder = 3,
			}),
		},
	})
	container(story)

	return StoryWrapper(controls, story)
end

return foundation.sections({
	summary = "",
	controls = {
		hasBackground = true,
		title = "Title",
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Negative margins",
			summary = "`HeaderBar.Actions` implicitly applies a negative margin so that the glyph of the left- or right-most IconButton will be aligned with the page content.",
			story = NegativeMarginsStory,
		},
		{
			name = "Dual-pane layout",
			summary = "Shows how HeaderBar composition adapts across multiple panes. At Small breakpoints, the Primary pane collapses and can be opened from the Aside pane.",
			story = DualPaneStory,
		},
		{
			name = "Menu leading accessory",
			summary = "Shows when menu and logo content belongs in HeaderBar versus the surrounding navigation shell.",
			story = MenuLeadingAccessoryStory,
		},
		{
			name = "Title positioning",
			summary = "Shows whether title content lives inside HeaderBar or below it in the page body.",
			story = TitlePositioningStory,
		},
	},
})
