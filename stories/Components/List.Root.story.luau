local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local AccessoryType = VF.Enums.AccessoryType
local BadgeVariant = VF.Enums.BadgeVariant
local IconSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/IconSize")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local ListItemInputType = VF.Enums.ListItemInputType

type InputSize = InputSize.InputSize
type IconSize = IconSize.IconSize
type DropdownItem = VideFoundation.DropdownItem

local IconName = VF.Enums.IconName
local List = VF.List

local INPUT_SIZE_TO_ICON_SIZE: { [InputSize]: IconSize } = {
	[InputSize.XSmall] = IconSize.XSmall,
	[InputSize.Small] = IconSize.Small,
	[InputSize.Medium] = IconSize.Medium,
	[InputSize.Large] = IconSize.Large,
}

--! The List API takes a thumbnail as a string, so it stays an rbxthumb URI.
local function gameThumbnail(id: string): any
	return { iconName = `rbxthumb://type=GameIcon&id={id}&w=150&h=150` }
end

--- An onActivated handler that logs, so it's obvious in the output when a row is activated.
local function logActivated(label: string?)
	return function()
		print(if label then `List.Item activated: {label}` else "List.Item activated")
	end
end

-- These stories are about `List.Root`: dividers, containment and composing rows. Per-row capabilities live in the
-- List.Item story; here the rows are simple, representative content.

local DIVIDER_OPTIONS = {
	None = false :: boolean | { isInset: boolean },
	Inset = { isInset = true } :: boolean | { isInset: boolean },
	Full = { isInset = false } :: boolean | { isInset: boolean },
}

type ContainedOption = true | { isContained: false, hasMargin: boolean? }
local CONTAINED_OPTIONS = {
	Contained = true :: ContainedOption,
	["Full Width"] = { isContained = false :: false, hasMargin = false } :: ContainedOption,
	["Has Margin"] = { isContained = false :: false, hasMargin = true } :: ContainedOption,
}

--- A fixed set of plain chevron rows, so container props (dividers, containment) are the focus.
local function sampleItems()
	return {
		List.Item({
			title = "Phone number",
			description = "***-***-883",
			onActivated = logActivated("Phone number"),
			input = ListItemInputType.Chevron,
			LayoutOrder = 1,
		}),
		List.Item({
			title = "Language",
			description = "English",
			onActivated = logActivated("Language"),
			input = ListItemInputType.Chevron,
			LayoutOrder = 2,
		}),
		List.Item({
			title = "Email address",
			description = "rob*******@gmail.com",
			onActivated = logActivated("Email address"),
			input = ListItemInputType.Chevron,
			LayoutOrder = 3,
		}),
	}
end

local function LabeledList(props: {
	LayoutOrder: number,
	label: string,
	hasDivider: (boolean | { isInset: boolean })?,
	isContained: ContainedOption?,
})
	return VF.View({
		tag = "col gap-small size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-label-medium content-default",
				LayoutOrder = 1,
			}),
			List.Root({
				hasDivider = props.hasDivider :: any,
				isContained = props.isContained :: any,
				LayoutOrder = 2,
				children = sampleItems,
			}),
		},
	})
end

local function hasDividerControl(controls: { [string]: any }): () -> any
	return function()
		return DIVIDER_OPTIONS[controls.hasDivider()]
	end
end

local function isContainedControl(controls: { [string]: any }): () -> any
	return function()
		return CONTAINED_OPTIONS[controls.isContained()]
	end
end

local function PlaygroundStory(controls: { [string]: any })
	return List.Root({
		hasDivider = hasDividerControl(controls),
		isContained = isContainedControl(controls),
		size = controls.size,
		children = function()
			return {
				List.Item({
					leading = gameThumbnail("1818"),
					title = { title = "Media", metadata = "Metadata" },
					description = "Leading media thumbnail",
					onActivated = logActivated("Media"),
					input = ListItemInputType.Chevron,
					LayoutOrder = 1,
				}),
				List.Item({
					leading = { type = AccessoryType.Avatar, userId = 24813339 },
					title = { title = "Avatar", metadata = "Metadata" },
					description = "Leading avatar",
					onActivated = logActivated("Avatar"),
					input = ListItemInputType.Chevron,
					LayoutOrder = 2,
				}),
				List.Item({
					leading = IconName.Robux,
					title = { title = "Icon", metadata = "Metadata" },
					description = "Leading icon",
					onActivated = logActivated("Icon"),
					input = ListItemInputType.Chevron,
					LayoutOrder = 3,
				}),
				List.Item({
					title = { title = "No Leading", metadata = "Metadata" },
					description = "No leading accessory",
					onActivated = logActivated("No Leading"),
					input = ListItemInputType.Chevron,
					LayoutOrder = 4,
				}),
			}
		end,
	})
end

local function DividersStory()
	return VF.View({
		tag = "col gap-large size-full-0 auto-y",
		children = {
			LabeledList({
				LayoutOrder = 1,
				label = "None",
				hasDivider = DIVIDER_OPTIONS.None,
			}),
			LabeledList({
				LayoutOrder = 2,
				label = "Inset (default)",
				hasDivider = DIVIDER_OPTIONS.Inset,
			}),
			LabeledList({
				LayoutOrder = 3,
				label = "Full",
				hasDivider = DIVIDER_OPTIONS.Full,
			}),
		},
	})
end

local function ContainmentStory()
	return VF.View({
		tag = "col gap-large size-full-0 auto-y",
		children = {
			LabeledList({
				LayoutOrder = 1,
				label = "Contained (border)",
				isContained = CONTAINED_OPTIONS.Contained,
			}),
			LabeledList({
				LayoutOrder = 2,
				label = "Full width",
				isContained = CONTAINED_OPTIONS["Full Width"],
			}),
			LabeledList({
				LayoutOrder = 3,
				label = "Has margin",
				isContained = CONTAINED_OPTIONS["Has Margin"],
			}),
		},
	})
end

local LANGUAGES: { DropdownItem } = {
	{ id = "en", text = "English" },
	{ id = "es", text = "Spanish" },
	{ id = "fr", text = "French" },
}

--- A realistic composition: the list holds rows with varied trailing content (badge, dropdown, toggle).
local function SettingsStory(controls: { [string]: any })
	local chatEnabled = Vide.source(false)
	local languageId = Vide.source("en" :: string | number)

	local function toggleChat()
		print("List.Item toggled: Automatic chat translation")
		chatEnabled(not chatEnabled())
	end

	return List.Root({
		hasDivider = hasDividerControl(controls),
		isContained = isContainedControl(controls),
		size = controls.size,
		children = function()
			return {
				List.Item({
					title = "Phone number",
					description = "***-***-883",
					trailing = VF.View({
						tag = "auto-xy",
						children = VF.Badge({
							text = "Verified",
							icon = IconName.CircleCheck,
							variant = BadgeVariant.Primary,
						}),
					}),
					onActivated = logActivated("Phone number"),
					input = ListItemInputType.Chevron,
					LayoutOrder = 1,
				}),
				--* No LayoutOrder, as in React, so this row comes first.
				List.Item({
					title = "Language",
					trailing = VF.Dropdown.Root({
						label = "",
						value = languageId,
						items = LANGUAGES,
						onItemChanged = function(id: string | number)
							print(`Language changed: {id}`)
							languageId(id)
						end,
						width = UDim.new(0, 140),
						LayoutOrder = 2,
					}),
				}),
				List.Item({
					title = "Email address",
					description = "rob*******@gmail.com",
					onActivated = logActivated("Email address"),
					input = ListItemInputType.Chevron,
					LayoutOrder = 3,
				}),
				List.Item({
					title = "Birthday",
					description = "Sep 27, 2000",
					onActivated = logActivated("Birthday"),
					input = ListItemInputType.Chevron,
					LayoutOrder = 4,
				}),
				List.Item({
					leading = "speech-bubble-align-left",
					title = "Automatic chat translation",
					description = "Translate chat messages from others",
					onActivated = toggleChat,
					input = { type = ListItemInputType.Toggle, isChecked = chatEnabled },
					LayoutOrder = 5,
				}),
			}
		end,
	})
end

type GameState = "attention" | "loading" | "done"

local BUILD_GAMES: { { id: string, title: string, status: string, badge: string, state: GameState } } = {
	{ id = "1818", title = "Miami Run", status = "Input needed", badge = "Draft", state = "attention" },
	{ id = "2788229376", title = "Magic Quest", status = "Building...", badge = "Public", state = "loading" },
	{ id = "1281960580", title = "Surf's Up Adventure", status = "Building...", badge = "Private", state = "loading" },
	{ id = "606849621", title = "Epic Battle", status = "v03 built · 10m ago", badge = "Friends", state = "done" },
}

local function GameTrailing(props: { badge: string, state: GameState, size: () -> InputSize })
	local function iconSize(): IconSize
		return INPUT_SIZE_TO_ICON_SIZE[props.size()]
	end

	local stateIcon = if props.state == "loading"
		then VF.Loading({ size = iconSize, LayoutOrder = 2 })
		else VF.Icon({
			name = if props.state == "done" then IconName.CircleCheck else IconName.TriangleExclamation,
			size = iconSize,
			LayoutOrder = 2,
		})

	return VF.View({
		tag = "row items-center gap-small auto-xy",
		children = {
			VF.Badge({
				text = props.badge,
				variant = BadgeVariant.Neutral,
				LayoutOrder = 1,
			}),
			stateIcon,
		},
	})
end

--- Another realistic composition: tappable game rows with rich trailing content and no chevron.
local function BuildGamesStory(controls: { [string]: any })
	return List.Root({
		size = controls.size,
		hasDivider = false,
		children = function()
			local rows = {
				List.Item({
					leading = IconName.PlusLarge,
					title = "New Game",
					description = "Build a game with AI",
					onActivated = function()
						print("create new game")
					end,
					input = ListItemInputType.None,
					LayoutOrder = 1,
				}),
			}

			for index, game in BUILD_GAMES do
				table.insert(
					rows,
					List.Item({
						leading = gameThumbnail(game.id),
						title = game.title,
						description = game.status,
						trailing = GameTrailing({ badge = game.badge, state = game.state, size = controls.size }),
						onActivated = function()
							print(`open {game.title}`)
						end,
						input = ListItemInputType.None,
						LayoutOrder = index + 1,
					})
				)
			end

			return rows
		end,
	})
end

return foundation.sections({
	summary = "A vertical list container. It renders dividers between rows (`hasDivider`), an optional border "
		.. "(`isContained`), and propagates `size` to its rows.",
	controls = {
		hasDivider = UILabs.Choose(Dash.keys(DIVIDER_OPTIONS)),
		isContained = UILabs.Choose(Dash.keys(CONTAINED_OPTIONS)),
		size = UILabs.Choose(Dash.values(InputSize :: any)),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Dividers",
			summary = "`hasDivider` controls the divider between rows: none, inset (default), or full width.",
			story = DividersStory,
		},
		{
			name = "Containment",
			summary = "`isContained` wraps the list in a border; when not contained, `hasMargin` toggles horizontal padding.",
			story = ContainmentStory,
		},
		{
			name = "Settings",
			summary = "A realistic settings list — the container composes rows with varied trailing content (badge, dropdown, toggle).",
			story = SettingsStory,
		},
		{
			name = "Build games",
			summary = "Tappable game rows with rich trailing content (status badge + state icon) and no chevron, mirroring the Build game list.",
			story = BuildGamesStory,
		},
	},
})
