local foundation = require("../foundation")
local MatrixGrid = require("../Shared/MatrixGrid")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local AlertSeverity = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/AlertSeverity")
local AlertVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/AlertVariant")
local Breakpoint = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/Breakpoint")
local BreakpointConfig = require("@game/ReplicatedStorage/Packages/VideFoundation/Utility/Responsive/BreakpointConfig")
local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")

type AlertSeverity = AlertSeverity.AlertSeverity
type AlertVariant = AlertVariant.AlertVariant
type AlertAction = {
	text: string,
	onActivated: () -> (),
}
type AlertActions = {
	primary: AlertAction,
	secondary: AlertAction?,
}?

local VARIANT_ORDER: { AlertVariant } = {
	AlertVariant.Feedback,
	AlertVariant.System,
}

local SEVERITY_ORDER: { AlertSeverity } = {
	AlertSeverity.Info,
	AlertSeverity.Warning,
	AlertSeverity.Success,
	AlertSeverity.Error,
}

local INLINE_WIDTH = 480
local STACKED_WIDTH = BreakpointConfig.widths[Breakpoint.XSmall]
local DEFAULT_TEXT = "Alert text"
local LONG_TEXT =
	"Your session is about to expire. You have been inactive for a while, so please save any in-progress work and sign in again to continue."
local LONG_LINK_TEXT = "Read the full maintenance schedule and what it means for your experiences"

type ActionLabels = {
	primary: string,
	secondary: string,
}

local DEFAULT_ACTION_LABELS = { primary = "Primary", secondary = "Secondary" }
local LONG_ACTION_LABELS = { primary = "Save and continue editing", secondary = "Discard all my changes" }

local HAS_ACTIONS_OPTIONS = { "None", "Link", "One action", "Two actions" }

local function noop() end

local LINK: AlertAction = { text = "Link text", onActivated = noop }

local function buildActions(count: number, labels: ActionLabels?): AlertActions
	if count < 1 then
		return nil
	end
	local actionLabels = labels or DEFAULT_ACTION_LABELS
	return {
		primary = { text = actionLabels.primary, onActivated = noop },
		secondary = if count >= 2 then { text = actionLabels.secondary, onActivated = noop } else nil,
	}
end

local function BoundedAlert(props: { width: number?, LayoutOrder: number, children: any })
	return VF.View({
		Size = UDim2.fromOffset(props.width or INLINE_WIDTH, 0),
		tag = "auto-y",
		LayoutOrder = props.LayoutOrder,
		children = props.children,
	})
end

local function Example(props: { LayoutOrder: number, label: string, children: any })
	return VF.View({
		tag = "col gap-small size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "col size-full-0 auto-y",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local WIDTH_CASES = {
	{ width = STACKED_WIDTH, caption = `≤{STACKED_WIDTH}px — stacked` },
	{ width = INLINE_WIDTH, caption = `{INLINE_WIDTH}px (after {STACKED_WIDTH}px) — inline` },
}

local function WidthPair(props: { LayoutOrder: number, label: string?, renderAlert: () -> any })
	local cells = {}
	for index, case in WIDTH_CASES do
		cells[index] = VF.View({
			tag = "col gap-small auto-xy",
			LayoutOrder = index,
			children = {
				VF.Text({
					Text = case.caption,
					tag = "auto-xy text-caption-small text-align-x-left content-default",
					LayoutOrder = 1,
				}),
				BoundedAlert({ width = case.width, LayoutOrder = 2, children = props.renderAlert() }),
			},
		})
	end

	local pair = VF.View({
		tag = "row wrap align-y-top gap-xlarge auto-xy",
		LayoutOrder = if props.label then 2 else props.LayoutOrder,
		children = cells,
	})

	if props.label == nil then
		return pair
	end
	return Example({ LayoutOrder = props.LayoutOrder, label = props.label, children = pair })
end

local function Section(props: { LayoutOrder: number, name: string, children: any })
	return VF.View({
		tag = "col gap-medium size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.name,
				tag = "auto-xy text-label-medium content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "col gap-large size-full-0 auto-y",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.View({
		tag = "col size-full-0 auto-y padding-large bg-surface-0",
		--* onClose is a plain callback, so toggling isDismissable builds the alert again.
		children = foundation.rebuildOn(controls.isDismissable, function(isDismissable: boolean)
			return VF.Alert({
				variant = controls.variant,
				severity = controls.severity,
				text = controls.text,
				link = function(): AlertAction?
					return if controls.hasActions() == "Link" then LINK else nil
				end,
				actions = function(): AlertActions
					local hasActions = controls.hasActions()
					if hasActions == "One action" then
						return buildActions(1)
					elseif hasActions == "Two actions" then
						return buildActions(2)
					end
					return nil
				end,
				onClose = if isDismissable then noop else nil,
				LayoutOrder = 1,
			})
		end),
	})
end

local function matrixStory<T>(values: { T }, alertFor: (value: T) -> any)
	local rows = {}
	for index, value in values do
		rows[index] = {
			label = MatrixGrid.matrixLabel(tostring(value)),
			cells = { BoundedAlert({ LayoutOrder = 1, children = alertFor(value) }) },
		}
	end
	return VF.View({
		tag = "col auto-xy padding-large bg-surface-0",
		children = MatrixGrid.MatrixGrid({
			labelColumnWidth = 80,
			showHeader = false,
			columnHeaders = { "Alert" },
			cellColumnWidth = INLINE_WIDTH,
			headerTextAlign = "left",
			cellAlign = "left",
			rowGap = "xxlarge",
			rows = rows,
		}),
	})
end

local function VariantsStory()
	return matrixStory(VARIANT_ORDER, function(variant)
		return VF.Alert({ variant = variant, text = DEFAULT_TEXT })
	end)
end

local function SeverityStory()
	return matrixStory(SEVERITY_ORDER, function(severity)
		return VF.Alert({ severity = severity, text = DEFAULT_TEXT })
	end)
end

local function CustomIconStory()
	local IconName = VF.Enums.IconName
	local IconVariant = VF.Enums.IconVariant
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = {
			Example({
				LayoutOrder = 1,
				label = "Info with a custom glyph, as a table with a variant",
				children = BoundedAlert({
					LayoutOrder = 1,
					children = VF.Alert({
						severity = AlertSeverity.Info,
						icon = { name = IconName.CircleQuestion, variant = IconVariant.Filled },
						text = "Studio now suggests edits as you type.",
					}),
				}),
			}),
			Example({
				LayoutOrder = 2,
				label = "Info with a custom glyph, as a name",
				children = BoundedAlert({
					LayoutOrder = 1,
					children = VF.Alert({
						severity = AlertSeverity.Info,
						icon = IconName.Robux,
						text = "Your payout is on its way.",
					}),
				}),
			}),
			Example({
				LayoutOrder = 3,
				label = "Other severities ignore icon",
				children = BoundedAlert({
					LayoutOrder = 1,
					children = VF.Alert({
						severity = AlertSeverity.Warning,
						icon = IconName.CircleQuestion,
						text = DEFAULT_TEXT,
					}),
				}),
			}),
		},
	})
end

local function RichTextStory()
	local text =
		`Your <b>session</b> is about to expire. Save any <font color="#FF8A00">in-progress</font> work and sign in again to continue.`
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = WidthPair({
			LayoutOrder = 1,
			label = "richText interprets markup in text",
			renderAlert = function()
				return VF.Alert({ text = text, richText = true, link = LINK, onClose = noop })
			end,
		}),
	})
end

local function SizingStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "Width",
			children = {
				Example({
					LayoutOrder = 1,
					label = "Unconstrained — the alert fills its parent",
					children = VF.Alert({
						text = DEFAULT_TEXT,
						link = LINK,
						LayoutOrder = 1,
					}),
				}),
				Example({
					LayoutOrder = 2,
					label = `Constrained by the parent to {STACKED_WIDTH}px — the link stacks under the message`,
					children = BoundedAlert({
						width = STACKED_WIDTH,
						LayoutOrder = 1,
						children = VF.Alert({ text = DEFAULT_TEXT, link = LINK }),
					}),
				}),
				Example({
					LayoutOrder = 3,
					label = `Constrained by the parent to {INLINE_WIDTH}px (after {STACKED_WIDTH}px)`,
					children = BoundedAlert({
						LayoutOrder = 1,
						children = VF.Alert({ text = DEFAULT_TEXT, link = LINK }),
					}),
				}),
			},
		}),
	})
end

local function ControlledExample(props: {
	LayoutOrder: number,
	label: string,
	text: string,
	dismissedBy: "Close" | "Primary action",
})
	local isVisible = Vide.source(true)

	local function dismiss()
		isVisible(false)
	end

	return Example({
		LayoutOrder = props.LayoutOrder,
		label = props.label,
		children = foundation.rebuildOn(isVisible, function(visible: boolean)
			if not visible then
				return VF.Button({
					text = "Show alert",
					variant = ButtonVariant.Standard,
					onActivated = function()
						isVisible(true)
					end,
					LayoutOrder = 1,
				})
			end
			local alert = if props.dismissedBy == "Close"
				then VF.Alert({ text = props.text, onClose = dismiss })
				else VF.Alert({
					text = props.text,
					actions = { primary = { text = "Primary", onActivated = dismiss } },
				})
			return BoundedAlert({ LayoutOrder = 1, children = alert })
		end),
	})
end

local function ControlledStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = {
			ControlledExample({
				LayoutOrder = 1,
				label = "Dismissed by the close affordance",
				text = "Dismiss this alert with its close button.",
				dismissedBy = "Close",
			}),
			ControlledExample({
				LayoutOrder = 2,
				label = "Dismissed by the primary action, with no close affordance",
				text = "Trigger the action to dismiss this alert.",
				dismissedBy = "Primary action",
			}),
		},
	})
end

type TrailingConfig = {
	label: string,
	hasLink: boolean,
	actionCount: number,
}

local TRAILING_CONFIGS: { TrailingConfig } = {
	{ label = "Link + close", hasLink = true, actionCount = 0 },
	{ label = "Primary + close", hasLink = false, actionCount = 1 },
	{ label = "Primary + secondary + close", hasLink = false, actionCount = 2 },
}

local function buildWrappingExamples(): { any }
	local children = {}
	for index, config in TRAILING_CONFIGS do
		children[index] = WidthPair({
			LayoutOrder = index,
			label = config.label,
			renderAlert = function()
				return if config.hasLink
					then VF.Alert({
						text = LONG_TEXT,
						link = { text = LONG_LINK_TEXT, onActivated = noop },
						onClose = noop,
					})
					else VF.Alert({
						text = LONG_TEXT,
						actions = buildActions(config.actionCount, LONG_ACTION_LABELS),
						onClose = noop,
					})
			end,
		})
	end
	return children
end

local function ContentStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "With link",
				children = WidthPair({
					LayoutOrder = 1,
					renderAlert = function()
						return VF.Alert({ text = DEFAULT_TEXT, link = LINK })
					end,
				}),
			}),
			Section({
				LayoutOrder = 2,
				name = "With actions",
				children = {
					WidthPair({
						LayoutOrder = 1,
						label = "One action",
						renderAlert = function()
							return VF.Alert({ text = DEFAULT_TEXT, actions = buildActions(1) })
						end,
					}),
					WidthPair({
						LayoutOrder = 2,
						label = "Two actions",
						renderAlert = function()
							return VF.Alert({ text = DEFAULT_TEXT, actions = buildActions(2) })
						end,
					}),
				},
			}),
			Section({ LayoutOrder = 3, name = "Wrapping", children = buildWrappingExamples() }),
		},
	})
end

return foundation.sections({
	summary = "Alert is an inline (Feedback) or system-level (System) message that surfaces severity-styled information with an optional link and up to two actions. Standard and Emphasis fall back to Feedback.",
	controls = {
		variant = UILabs.Choose(VARIANT_ORDER),
		severity = UILabs.Choose(SEVERITY_ORDER),
		text = DEFAULT_TEXT,
		hasActions = UILabs.Choose(HAS_ACTIONS_OPTIONS),
		isDismissable = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Variants", story = VariantsStory },
		{ name = "Severity", story = SeverityStory },
		{ name = "Custom icon", story = CustomIconStory },
		{ name = "Rich text", story = RichTextStory },
		{ name = "Sizing", story = SizingStory },
		{
			name = "Controlled component",
			summary = "Dismissal and actions are consumer-owned; wire them to observe the effect.",
			story = ControlledStory,
		},
		{
			name = "Content",
			story = function()
				return foundation.scroll(ContentStory())
			end,
		},
	},
})
