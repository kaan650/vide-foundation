local foundation = require("../foundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local DialogSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/DialogSize")
local FillBehavior = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/FillBehavior")
local IconSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/IconSize")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local useScaledValue = require("@game/ReplicatedStorage/Packages/VideFoundation/Utility/useScaledValue")

type DialogSize = DialogSize.DialogSize

local IconName = VF.Enums.IconName

local DESCRIPTION_TAG =
	"size-full-0 auto-xy text-body-medium text-wrap text-align-x-left text-align-y-top content-default"

local function noop() end

local function Description(text: string, layoutOrder: number)
	return VF.Text({
		LayoutOrder = layoutOrder,
		Text = text,
		tag = DESCRIPTION_TAG,
	})
end

local function Attribute(label: string, value: string, layoutOrder: number)
	return VF.View({
		LayoutOrder = layoutOrder,
		tag = "col align-x-center gap-small auto-xy",
		children = {
			VF.Text({
				LayoutOrder = 1,
				Text = label,
				tag = "auto-xy text-body-small content-default",
			}),
			VF.Text({
				LayoutOrder = 2,
				Text = value,
				tag = "auto-xy text-title-medium content-emphasis",
			}),
		},
	})
end

local function HeaderTitle(text: string)
	return VF.Text({
		LayoutOrder = 1,
		Text = text,
		tag = "auto-xy text-heading-small text-truncate-split content-emphasis",
	})
end

local function OpenButton(text: string, isOpen: (boolean) -> any)
	return VF.Button({
		onActivated = function()
			isOpen(true)
		end,
		text = text,
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local isOpen = Vide.source(false)
	local tokens = VF.Hooks.useTokens()

	return {
		OpenButton("Open Sheet", isOpen),
		VF.Sheet.Root({
			isOpen = isOpen,
			snapPoints = { 0.5, 0.9 },
			preferCenterSheet = controls.preferCenterSheet,
			size = controls.size,
			onClose = function()
				isOpen(false)
			end,
			children = function()
				return {
					VF.Sheet.Header({
						children = {
							foundation.create("UIPadding")({
								PaddingTop = function()
									return UDim.new(0, tokens().Padding.Medium)
								end,
								PaddingBottom = function()
									return UDim.new(0, tokens().Padding.Medium)
								end,
								PaddingRight = function()
									return UDim.new(0, tokens().Padding.Small)
								end,
							}),
							VF.Image({
								LayoutOrder = 1,
								tag = "size-1200 radius-small bg-shift-200",
							}),
							VF.View({
								LayoutOrder = 2,
								tag = "col fill gap-xsmall auto-xy",
								children = {
									VF.Text({
										LayoutOrder = 1,
										Text = "Sheet Title",
										tag = "auto-xy text-title-large text-truncate-split content-emphasis",
									}),
									VF.Text({
										LayoutOrder = 2,
										Text = "Subtitle or description goes here",
										tag = "auto-xy text-body-small text-truncate-split content-default",
									}),
								},
							}),
							--* Foundation's story passes `Size = InputSize.Large`, which IconButton ignores, so it is Medium.
							VF.IconButton({
								LayoutOrder = 3,
								icon = IconName.Bell,
								onActivated = noop,
							}),
						},
					}),
					VF.Sheet.Content({
						isContentFullBleed = controls.isContentFullBleed,
						children = {
							VF.View({
								LayoutOrder = 2,
								tag = "size-full-full auto-y aspect-16-9 radius-medium bg-shift-200",
							}),
							VF.View({
								tag = "row flex-fill items-center gap-medium size-full-0 auto-y",
								LayoutOrder = 3,
								children = {
									Attribute("Rating", "94%", 1),
									Attribute("Active", "1.2K", 3),
									Attribute("Age", "13+", 5),
									Attribute("Maturity", "Everyone", 7),
								},
							}),
							VF.View({
								LayoutOrder = 4,
								tag = "row align-y-center gap-small size-full-0 auto-y padding-small radius-medium bg-shift-200",
								children = {
									VF.Icon({
										LayoutOrder = 1,
										name = IconName.ThumbUp,
										size = IconSize.Large,
									}),
									VF.View({
										LayoutOrder = 2,
										tag = "col grow auto-xy",
										children = {
											VF.Text({
												LayoutOrder = 1,
												Text = "94%",
												tag = "auto-xy text-body-medium content-emphasis",
											}),
											VF.Text({
												LayoutOrder = 2,
												Text = "100 VOTES",
												tag = "auto-xy text-body-small content-default",
											}),
										},
									}),
									VF.IconButton({
										LayoutOrder = 3,
										icon = IconName.ThumbUp,
										size = InputSize.Large,
										onActivated = noop,
									}),
									VF.IconButton({
										LayoutOrder = 4,
										icon = IconName.ThumbDown,
										size = InputSize.Large,
										onActivated = noop,
									}),
								},
							}),
							Description(
								"This is some example content inside of a sheet. Sheets can be used to display additional information or actions related to the current context without navigating away from the current screen.",
								5
							),
							Description(
								"Sheets can be dismissed by swiping down or tapping outside of the sheet area.",
								6
							),
							Description(
								"This sheet is fully responsive and will adapt to different screen sizes and orientations.",
								7
							),
							Description(
								"You can add as much content as you need inside the sheet, and it will scroll if the content exceeds the available space.",
								8
							),
							Description(
								"Sheets are a great way to provide additional context and actions without overwhelming the user with too much information at once.",
								9
							),
							Description(
								"This is the last piece of example content inside the sheet. You can customize the appearance and behavior of the sheet to fit your specific use case.",
								10
							),
							Description(
								"Thank you for checking out this example of a sheet component in Roblox using the Foundation library!",
								11
							),
							Description(
								"Feel free to reach out if you have any questions or need further assistance.",
								12
							),
							Description("Happy developing!", 13),
						},
					}),
					VF.Sheet.Actions({
						children = {
							VF.View({
								tag = "row auto-xy padding-right-small",
								children = {
									VF.IconButton({
										LayoutOrder = 1,
										icon = IconName.CircleThreeDotsHorizontal,
										size = InputSize.Large,
										onActivated = noop,
									}),
									VF.IconButton({
										LayoutOrder = 2,
										icon = IconName.PersonArrowFromBottomRight,
										size = InputSize.Large,
										onActivated = noop,
									}),
								},
							}),
							VF.Button({
								LayoutOrder = 3,
								text = "Join",
								icon = IconName.PlayLarge,
								size = InputSize.Large,
								variant = ButtonVariant.Emphasis,
								fillBehavior = FillBehavior.Fill,
								onActivated = function()
									isOpen(false)
								end,
							}),
						},
					}),
				}
			end,
		}),
	}
end

local function ManualStory(controls: { [string]: any })
	local isOpen = Vide.source(false)

	return {
		OpenButton("Open Sheet (Manual)", isOpen),
		Vide.show(isOpen, function()
			local scaled = useScaledValue(300)
			VF.Sheet.Root({
				centerSheetHeight = controls.centerSheetHeight,
				snapPoints = function()
					return { 0.2, scaled() }
				end,
				defaultSnapPointIndex = 2,
				preferCenterSheet = controls.preferCenterSheet,
				size = controls.size,
				onClose = function()
					isOpen(false)
				end,
				children = function()
					return VF.Sheet.Content({
						isContentFullBleed = controls.isContentFullBleed,
						children = {
							VF.View({
								LayoutOrder = 1,
								tag = "size-full-full auto-y aspect-16-9 radius-medium bg-shift-200",
							}),
							Description(
								"This is some example content inside of a sheet. Sheets can be used to display additional information or actions related to the current context without navigating away from the current screen.",
								2
							),
							Description(
								"Sheets can be dismissed by swiping down or tapping outside of the sheet area.",
								3
							),
							Description(
								"This sheet is fully responsive and will adapt to different screen sizes and orientations.",
								4
							),
						},
					})
				end,
			})
			return nil
		end),
	}
end

local function AccountItem(index: number)
	return VF.View({
		tag = "row items-center gap-medium size-full-0 auto-y",
		LayoutOrder = index,
		children = {
			VF.Avatar({
				size = InputSize.Large,
				userId = 24813339,
			}),
			VF.View({
				LayoutOrder = 2,
				tag = "col fill gap-xsmall auto-xy",
				children = {
					VF.Text({
						LayoutOrder = 1,
						Text = `User #{index}`,
						tag = "auto-xy text-body-medium text-truncate-split content-emphasis",
					}),
					VF.Text({
						LayoutOrder = 2,
						Text = `@user{index}`,
						tag = "auto-xy text-body-small text-truncate-split content-default",
					}),
				},
			}),
		},
	})
end

local function AutoSizeStory(controls: { [string]: any })
	local isOpen = Vide.source(false)
	local accounts = Vide.source(1)

	return {
		OpenButton("Open Sheet (Auto Size)", isOpen),
		Vide.show(isOpen, function()
			VF.Sheet.Root({
				preferCenterSheet = controls.preferCenterSheet,
				size = controls.size,
				onClose = function()
					isOpen(false)
				end,
				children = function()
					return {
						VF.Sheet.Header({
							children = HeaderTitle("Account Switcher"),
						}),
						VF.Sheet.Content({
							isContentFullBleed = controls.isContentFullBleed,
							children = Vide.indexes(function()
								local list = {}
								for index = 1, accounts() do
									list[index] = index
								end
								return list
							end, function(_, index: number)
								return AccountItem(index)
							end),
						}),
						VF.Sheet.Actions({
							children = {
								VF.Button({
									LayoutOrder = 1,
									text = "Add Account",
									size = InputSize.Large,
									variant = ButtonVariant.Emphasis,
									fillBehavior = FillBehavior.Fill,
									onActivated = function()
										accounts(accounts() + 1)
									end,
								}),
								VF.Button({
									LayoutOrder = 2,
									text = "Remove Account",
									size = InputSize.Large,
									variant = ButtonVariant.Alert,
									fillBehavior = FillBehavior.Fill,
									onActivated = function()
										accounts(math.max(1, accounts() - 1))
									end,
								}),
							},
						}),
					}
				end,
			})
			return nil
		end),
	}
end

local function ChatMessage(index: number)
	return VF.View({
		LayoutOrder = index,
		tag = {
			["col gap-xxsmall auto-xy padding-small radius-medium"] = true,
			["bg-shift-200"] = index % 2 == 1,
			["bg-shift-400"] = index % 2 == 0,
		},
		children = {
			VF.Text({
				LayoutOrder = 1,
				Text = if index % 2 == 1 then "Friend" else "You",
				tag = "auto-xy text-caption-medium content-muted",
			}),
			VF.Text({
				LayoutOrder = 2,
				Text = `Message #{index}`,
				tag = "auto-xy text-body-medium content-emphasis",
			}),
		},
	})
end

local function ReversedContentStory(controls: { [string]: any })
	local isOpen = Vide.source(false)
	local messages = Vide.source(12)

	return {
		OpenButton("Open Sheet (Reversed Content)", isOpen),
		Vide.show(isOpen, function()
			VF.Sheet.Root({
				snapPoints = { 0.5, 0.9 },
				preferCenterSheet = controls.preferCenterSheet,
				size = controls.size,
				onClose = function()
					isOpen(false)
				end,
				children = function()
					return {
						VF.Sheet.Header({
							children = HeaderTitle("Chat"),
						}),
						VF.Sheet.Content({
							isReversed = true,
							isContentFullBleed = controls.isContentFullBleed,
							children = Vide.indexes(function()
								local list = {}
								for index = 1, messages() do
									list[index] = index
								end
								return list
							end, function(_, index: number)
								return ChatMessage(index)
							end),
						}),
						VF.Sheet.Actions({
							children = VF.Button({
								LayoutOrder = 1,
								text = "Send Message",
								size = InputSize.Large,
								variant = ButtonVariant.Emphasis,
								fillBehavior = FillBehavior.Fill,
								onActivated = function()
									messages(messages() + 1)
								end,
							}),
						}),
					}
				end,
			})
			return nil
		end),
	}
end

local function FocusNavigationStory(controls: { [string]: any })
	local isOpen = Vide.source(false)
	local checkboxStates = Vide.source({
		notifications = false,
		analytics = false,
		marketing = false,
		thirdParty = false,
	})

	local function toggleCheckbox(key: string)
		return function(checked: boolean)
			local states = table.clone(Vide.untrack(checkboxStates))
			states[key] = checked
			checkboxStates(states)
		end
	end

	local function isChecked(key: string)
		return function(): boolean
			return (checkboxStates() :: any)[key]
		end
	end

	return {
		OpenButton("Open Sheet (Focus Navigation)", isOpen),
		VF.Sheet.Root({
			isOpen = isOpen,
			preferCenterSheet = controls.preferCenterSheet,
			size = controls.size,
			onClose = function()
				isOpen(false)
			end,
			children = function()
				local sheetNav = VF.Hooks.useSheetNavigation()

				local firstCheckbox = VF.Checkbox({
					label = "Enable notifications",
					isChecked = isChecked("notifications"),
					onActivated = toggleCheckbox("notifications"),
					NextSelectionUp = sheetNav.closeAffordanceRef,
					NextSelectionLeft = sheetNav.closeAffordanceRef,
					LayoutOrder = 1,
				})
				sheetNav.setContentStartRef(firstCheckbox)

				local lastCheckbox = VF.Checkbox({
					label = "Share usage analytics",
					isChecked = isChecked("analytics"),
					onActivated = toggleCheckbox("analytics"),
					LayoutOrder = 2,
				})

				return {
					VF.Sheet.Header({
						children = HeaderTitle("Settings"),
					}),
					VF.Sheet.Content({
						isContentFullBleed = controls.isContentFullBleed,
						children = {
							VF.View({
								tag = "col gap-small size-full-0 auto-y",
								children = { firstCheckbox, lastCheckbox },
							}),
							VF.View({
								tag = "row align-x-right size-full-0 auto-y padding-top-medium",
								children = VF.Button({
									text = "Close",
									onActivated = function()
										isOpen(false)
									end,
									variant = ButtonVariant.Emphasis,
									NextSelectionUp = lastCheckbox,
								}),
							}),
						},
					}),
				}
			end,
		}),
	}
end

local function ToolbarContentWithNavigation(onClose: () -> ())
	local sheetNav = VF.Hooks.useSheetNavigation()

	return VF.View({
		tag = "col gap-medium size-full-0 auto-y",
		children = {
			VF.View({
				LayoutOrder = 1,
				tag = "row items-center gap-small size-full-0 auto-y",
				children = {
					VF.IconButton({
						LayoutOrder = 1,
						icon = IconName.Heart,
						size = InputSize.Large,
						onActivated = noop,
					}),
					VF.IconButton({
						LayoutOrder = 2,
						icon = IconName.ArrowUpRightFromSquare,
						size = InputSize.Large,
						onActivated = noop,
					}),
					VF.IconButton({
						LayoutOrder = 3,
						icon = IconName.CircleThreeDotsHorizontal,
						size = InputSize.Large,
						onActivated = noop,
						NextSelectionRight = sheetNav.closeAffordanceRef,
					}),
				},
			}),
			VF.View({
				LayoutOrder = 2,
				tag = "size-full-full auto-y aspect-16-9 radius-medium bg-shift-200",
			}),
			VF.Text({
				LayoutOrder = 3,
				Text = "Featured Content",
				tag = "size-full-0 auto-xy text-heading-small text-align-x-left content-emphasis",
			}),
			Description(
				"This sheet has no header, so the floating CloseAffordance is visible in the top-right. "
					.. "Pressing left on the CloseAffordance navigates to the toolbar, and pressing right on the "
					.. "toolbar navigates back to the CloseAffordance.",
				4
			),
			VF.View({
				LayoutOrder = 5,
				tag = "row align-x-right size-full-0 auto-y padding-top-medium",
				children = VF.Button({
					text = "Close",
					onActivated = onClose,
					variant = ButtonVariant.Emphasis,
				}),
			}),
		},
	})
end

local function FocusNavigationLeftStory(controls: { [string]: any })
	local isOpen = Vide.source(false)

	local function close()
		isOpen(false)
	end

	return {
		OpenButton("Open Sheet (Left Navigation)", isOpen),
		VF.Sheet.Root({
			isOpen = isOpen,
			preferCenterSheet = controls.preferCenterSheet,
			size = controls.size,
			onClose = close,
			children = function()
				return VF.Sheet.Content({
					isContentFullBleed = controls.isContentFullBleed,
					children = ToolbarContentWithNavigation(close),
				})
			end,
		}),
	}
end

local function TextInputStory(controls: { [string]: any })
	local isOpen = Vide.source(false)
	local loading = Vide.source(false)

	return {
		OpenButton("Open Sheet With TextInput", isOpen),
		Vide.show(isOpen, function()
			VF.Sheet.Root({
				onClose = function()
					isOpen(false)
				end,
				preferCenterSheet = controls.preferCenterSheet,
				size = controls.size,
				children = function()
					return {
						VF.Sheet.Header({
							children = HeaderTitle("Enter Your Name"),
						}),
						VF.Sheet.Content({
							isContentFullBleed = controls.isContentFullBleed,
							children = VF.TextInput({
								LayoutOrder = 1,
								label = "Test",
								width = UDim.new(1, 0),
								onChanged = noop,
								text = "asdf",
							}),
						}),
						VF.Sheet.Actions({
							children = VF.Button({
								LayoutOrder = 1,
								text = "Submit",
								size = InputSize.Large,
								variant = ButtonVariant.Emphasis,
								fillBehavior = FillBehavior.Fill,
								isLoading = loading,
								onActivated = function()
									loading(true)
									task.delay(2, function()
										loading(false)
									end)
								end,
							}),
						}),
					}
				end,
			})
			return nil
		end),
	}
end

local function DateItem(description: string, date: string, layoutOrder: number?)
	return VF.List.Item({
		LayoutOrder = layoutOrder,
		description = description,
		trailing = VF.Text({
			tag = "auto-xy text-title-medium content-emphasis",
			Text = date,
		}),
	})
end

local function IconLabel(icon: string, text: string, layoutOrder: number)
	return VF.View({
		LayoutOrder = layoutOrder,
		tag = "row gap-xsmall auto-xy",
		children = {
			VF.Icon({
				LayoutOrder = 1,
				name = icon,
				size = IconSize.Small,
			}),
			VF.Text({
				LayoutOrder = 2,
				Text = text,
				tag = "auto-xy text-body-medium content-emphasis",
			}),
		},
	})
end

local function FullBleedStory(controls: { [string]: any })
	local isOpen = Vide.source(false)

	return {
		OpenButton("Open Sheet (FullBleed)", isOpen),
		VF.Sheet.Root({
			isOpen = isOpen,
			snapPoints = { 0.5, 0.9 },
			preferCenterSheet = controls.preferCenterSheet,
			size = controls.size,
			onClose = function()
				isOpen(false)
			end,
			children = function()
				return {
					--* `sticky` takes a plain value, so a change builds the media again.
					foundation.rebuildOn(controls.stickyFullBleed, function(sticky: boolean)
						return VF.Sheet.FullBleed({
							media = "component_assets/avatarBG_dark",
							sticky = sticky,
							aspectRatio = 16 / 9,
						}) :: any
					end),
					VF.Sheet.Content({
						isContentFullBleed = controls.isContentFullBleed,
						children = {
							VF.View({
								LayoutOrder = 1,
								tag = "col gap-xlarge size-full-0 auto-y padding-top-small",
								children = {
									VF.View({
										LayoutOrder = 1,
										tag = "row items-center gap-medium size-full-0 auto-y",
										children = {
											VF.Image({
												LayoutOrder = 1,
												tag = "size-1400 radius-medium bg-shift-200",
											}),
											VF.View({
												LayoutOrder = 2,
												tag = "col align-y-center fill auto-xy",
												children = {
													VF.Text({
														LayoutOrder = 1,
														Text = "Sheet Title",
														tag = "auto-xy text-heading-small text-truncate-split content-emphasis",
													}),
													VF.Text({
														LayoutOrder = 2,
														Text = "Subtitle or description goes here",
														tag = "auto-xy text-label-medium text-truncate-split content-default",
													}),
												},
											}),
										},
									}),
									VF.View({
										LayoutOrder = 2,
										tag = "row gap-medium size-full-0 auto-y",
										children = {
											IconLabel(IconName.Clock, "In 2 days", 1),
											IconLabel(IconName.PersonPlay, "1M Interested", 2),
										},
									}),
									VF.Text({
										LayoutOrder = 3,
										Text = "Style your look with iconic-inspired pieces and walk the runway to showcase your high-fashion vision. Compete, get inspired, and serve your best moment ✨...more ",
										tag = "auto-xy text-body-medium text-wrap text-align-x-left content-default",
									}),
									VF.View({
										LayoutOrder = 4,
										tag = "row align-y-center gap-medium size-full-0 auto-y padding-medium stroke-default radius-medium",
										children = {
											VF.View({
												tag = "size-1000-1300 bg-shift-200",
											}),
											VF.Text({
												Text = "Strong language, Mild Suggestive Themes • In-Game Purchases (Includes Random Items)",
												tag = "fill auto-xy text-body-small text-wrap text-align-x-left",
											}),
										},
									}),
								},
							}),
							VF.List.Root({
								LayoutOrder = 2,
								isContained = {
									isContained = false :: false,
									hasMargin = false,
								},
								hasDivider = {
									hasDivider = true :: true,
									isInset = false,
								},
								children = function()
									local items = { DateItem("Start date", "Sat, Mar 8 at 8:00 PM", -1) }
									for _ = 1, 7 do
										table.insert(items, DateItem("End date", "Tue, Mar 11 at 5:00 AM"))
									end
									return items
								end,
							}),
						},
					}),
					VF.Sheet.Actions({
						children = {
							VF.Button({
								LayoutOrder = 1,
								text = "Interested",
								size = InputSize.Medium,
								variant = ButtonVariant.Emphasis,
								fillBehavior = FillBehavior.Fill,
								onActivated = function()
									isOpen(false)
								end,
							}),
							VF.IconButton({
								LayoutOrder = 2,
								icon = IconName.ArrowThickToRight,
								variant = ButtonVariant.Standard,
								size = InputSize.Medium,
								onActivated = noop,
							}),
						},
					}),
				}
			end,
		}),
	}
end

return foundation.sections({
	summary = "Sheet",
	controls = {
		centerSheetHeight = 1,
		preferCenterSheet = false,
		size = UILabs.Choose({ DialogSize.Medium, DialogSize.Large } :: { DialogSize }),
		stickyFullBleed = false,
		isContentFullBleed = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sheet (manual sizing based on height prop)", story = ManualStory },
		{ name = "Sheet (auto size)", story = AutoSizeStory },
		{ name = "Sheet with Focus Navigation", story = FocusNavigationStory },
		{ name = "Sheet with Left Navigation (No Header)", story = FocusNavigationLeftStory },
		{ name = "Sheet (with TextInput)", story = TextInputStory },
		{ name = "Sheet (FullBleed)", story = FullBleedStory },
		{ name = "Sheet (reversed content)", story = ReversedContentStory },
	},
})
