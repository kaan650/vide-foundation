local foundation = require("../foundation")
local MatrixGrid = require("../Shared/MatrixGrid")
local StoryIcons = require("../Shared/StoryIcons")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local ColorNamespace = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ColorNamespace")
local FillBehavior = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/FillBehavior")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local PresentationContext =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Providers/Style/PresentationContext")

type ColorStyleValue = VideFoundation.ColorStyleValue
type InputSize = InputSize.InputSize
type SupportedButtonVariant = ButtonVariant.SupportedButtonVariant
type FillBehavior = FillBehavior.FillBehavior

local IconName = VF.Enums.IconName

local BUTTON_VARIANTS: { SupportedButtonVariant } = {
	ButtonVariant.Standard,
	ButtonVariant.Emphasis,
	ButtonVariant.SoftEmphasis,
	ButtonVariant.Utility,
	ButtonVariant.Link,
	ButtonVariant.Alert,
}

local SIZE_ORDER: { InputSize } = {
	InputSize.XSmall,
	InputSize.Small,
	InputSize.Medium,
	InputSize.Large,
}

local STORY_BUTTON_WIDTH = 140
local LAYOUT_COLUMN_WIDTH = 280
local INFO_COLUMN_WIDTH = 260
local LONG_TEXT_CONTAINER_WIDTH = 200
local LONG_BUTTON_TEXT =
	"This is a very long button label that should truncate with an ellipsis when it exceeds the container width"
local INPUT_DELAY_SECONDS = 3

local defaultButtonProps: {
	text: string,
	variant: SupportedButtonVariant,
	size: InputSize,
	icon: string,
} = {
	text = "Button",
	variant = ButtonVariant.Emphasis,
	size = InputSize.Medium,
	icon = IconName.PlaySmall,
}

local PLAYGROUND_VARIANT_OPTIONS: { SupportedButtonVariant } = {
	ButtonVariant.Emphasis,
	ButtonVariant.Standard,
	ButtonVariant.SoftEmphasis,
	ButtonVariant.Utility,
	ButtonVariant.Link,
	ButtonVariant.Alert,
}

local PLAYGROUND_SIZE_OPTIONS: { InputSize } = {
	InputSize.Medium,
	InputSize.XSmall,
	InputSize.Small,
	InputSize.Large,
}

local function noop() end

type StoryButtonProps = {
	text: string?,
	icon: string?,
	variant: SupportedButtonVariant?,
	size: InputSize?,
	isDisabled: boolean?,
	isLoading: boolean?,
	fillBehavior: FillBehavior?,
	width: UDim?,
	inputDelay: number?,
	hug: boolean?,
	useDefaults: boolean?,
	textOnly: boolean?,
}

local function StoryButton(props: StoryButtonProps)
	local text = props.text
	local icon = props.icon
	local variant = props.variant
	local size = props.size

	if props.useDefaults then
		text = text or defaultButtonProps.text
		if not props.textOnly then
			icon = icon or defaultButtonProps.icon
		end
		variant = variant or defaultButtonProps.variant
		size = size or defaultButtonProps.size
	end

	local fillBehavior: FillBehavior? = props.fillBehavior
	if fillBehavior == nil and not props.hug and props.width == nil then
		fillBehavior = FillBehavior.Fill
	end

	local button = VF.Button({
		text = text,
		icon = icon,
		variant = (variant or defaultButtonProps.variant) :: SupportedButtonVariant,
		size = (size or defaultButtonProps.size) :: InputSize,
		isDisabled = props.isDisabled,
		isLoading = props.isLoading,
		fillBehavior = fillBehavior,
		width = props.width,
		inputDelay = props.inputDelay or 0,
		onActivated = noop,
	})

	if props.hug then
		return VF.View({
			tag = "auto-xy",
			children = button,
		})
	end

	local width = props.width
	local containerWidth = if width and width.Offset > 0 then width.Offset else STORY_BUTTON_WIDTH

	return VF.View({
		tag = "size-full-0 auto-y",
		Size = UDim2.fromOffset(containerWidth, 0),
		children = button,
	})
end

local function Section(props: { LayoutOrder: number, name: string, contentTag: string?, children: any })
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
				tag = props.contentTag or "row gap-large auto-xy wrap",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function LabeledButton(props: {
	label: string,
	LayoutOrder: number,
	text: string?,
	icon: string?,
	variant: SupportedButtonVariant?,
	size: InputSize?,
	isLoading: boolean?,
	hug: boolean?,
})
	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "auto-xy",
				LayoutOrder = 2,
				children = StoryButton({
					text = props.text,
					icon = props.icon,
					variant = props.variant or defaultButtonProps.variant,
					size = props.size or defaultButtonProps.size,
					isLoading = props.isLoading,
					hug = if props.hug ~= nil then props.hug else props.text == nil and props.icon ~= nil,
				}),
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.View({
		tag = "row align-y-center gap-medium size-0 auto-xy padding-medium",
		children = VF.Button({
			icon = function()
				return StoryIcons.parseIconControl(controls.icon())
			end,
			text = controls.text,
			variant = controls.variant,
			isLoading = controls.isLoading,
			isDisabled = controls.isDisabled,
			size = controls.size,
			fillBehavior = foundation.orNil(controls.fillBehavior),
			width = function()
				return UDim.new(0, controls.width())
			end,
			inputDelay = controls.inputDelay,
			onActivated = function()
				print(`{controls.variant()} Button activated`)
			end,
		}),
	})
end

local function VariantsStory()
	local buttons = {}
	for index, variant in BUTTON_VARIANTS do
		buttons[index] = LabeledButton({
			label = variant,
			LayoutOrder = index,
			variant = variant,
			text = defaultButtonProps.text,
			icon = defaultButtonProps.icon,
			size = defaultButtonProps.size,
			hug = true,
		})
	end
	return VF.View({
		tag = "row wrap gap-large auto-xy padding-y-large bg-surface-0",
		children = buttons,
	})
end

local function StatesStory()
	local loadingButtons = {}
	for index, size in SIZE_ORDER do
		loadingButtons[index] = LabeledButton({
			label = size,
			LayoutOrder = index,
			size = size,
			text = defaultButtonProps.text,
			variant = defaultButtonProps.variant,
			isLoading = true,
			hug = true,
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Disabled",
				contentTag = "auto-xy",
				children = StoryButton({
					useDefaults = true,
					textOnly = true,
					isDisabled = true,
					hug = true,
				}),
			}),
			Section({
				LayoutOrder = 2,
				name = "Loading",
				children = VF.View({
					tag = "row wrap gap-large auto-xy",
					LayoutOrder = 1,
					children = loadingButtons,
				}),
			}),
		},
	})
end

local function ControlledRegularButtonExample()
	local clickCount = Vide.source(0)

	return VF.Button({
		text = function()
			return `Clicked {clickCount()} time(s)`
		end,
		variant = defaultButtonProps.variant,
		size = defaultButtonProps.size,
		onActivated = function()
			clickCount(clickCount() + 1)
		end,
	})
end

local function ControlledInputDelayExample()
	local delayKey = Vide.source(0)

	--* A new key builds a new button, which starts its input delay again.
	return foundation.rebuildOn(delayKey, function()
		return VF.Button({
			text = "Click to see input delay",
			variant = defaultButtonProps.variant,
			size = defaultButtonProps.size,
			inputDelay = INPUT_DELAY_SECONDS,
			onActivated = function()
				delayKey(delayKey() + 1)
			end,
		})
	end)
end

local function ControlledStory()
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Regular button",
				contentTag = "auto-xy",
				children = ControlledRegularButtonExample(),
			}),
			Section({
				LayoutOrder = 2,
				name = "Input delay",
				contentTag = "auto-xy",
				children = ControlledInputDelayExample(),
			}),
		},
	})
end

local function FillBehaviorExample(props: { label: string, LayoutOrder: number, fillBehavior: FillBehavior? })
	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		Size = UDim2.fromOffset(LAYOUT_COLUMN_WIDTH, 0),
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "row gap-medium size-full-0 auto-xy padding-large radius-medium bg-surface-100",
				Size = UDim2.fromOffset(LAYOUT_COLUMN_WIDTH, 0),
				LayoutOrder = 2,
				children = VF.Button({
					text = defaultButtonProps.text,
					variant = ButtonVariant.Emphasis,
					size = defaultButtonProps.size,
					fillBehavior = props.fillBehavior,
					onActivated = noop,
					LayoutOrder = 1,
				}),
			}),
		},
	})
end

local function SizingStory()
	local sizes = {}
	for index, size in SIZE_ORDER do
		sizes[index] = LabeledButton({
			label = size,
			LayoutOrder = index,
			size = size,
			text = defaultButtonProps.text,
			variant = ButtonVariant.Emphasis,
			hug = true,
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Size",
				contentTag = "row gap-large auto-xy wrap",
				children = sizes,
			}),
			Section({
				LayoutOrder = 2,
				name = "Fill behavior",
				contentTag = "row gap-xxlarge auto-xy wrap",
				children = {
					FillBehaviorExample({
						label = "fillBehavior = Fit",
						LayoutOrder = 1,
						fillBehavior = FillBehavior.Fit,
					}),
					FillBehaviorExample({
						label = "fillBehavior = Fill",
						LayoutOrder = 2,
						fillBehavior = FillBehavior.Fill,
					}),
				},
			}),
		},
	})
end

local function LongTextExample(props: {
	label: string,
	LayoutOrder: number,
	variant: SupportedButtonVariant,
	icon: string?,
})
	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "row size-full-0 auto-y padding-large radius-medium bg-surface-100",
				Size = UDim2.fromOffset(LONG_TEXT_CONTAINER_WIDTH, 0),
				LayoutOrder = 2,
				children = VF.Button({
					text = LONG_BUTTON_TEXT,
					icon = props.icon,
					variant = props.variant,
					size = defaultButtonProps.size,
					fillBehavior = FillBehavior.Fill,
					onActivated = noop,
					LayoutOrder = 1,
				}),
			}),
		},
	})
end

local function ContentStory()
	local iconButtons = {}
	for index, size in SIZE_ORDER do
		iconButtons[index] = LabeledButton({
			label = size,
			LayoutOrder = index,
			size = size,
			text = defaultButtonProps.text,
			icon = defaultButtonProps.icon,
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = {
			Section({
				LayoutOrder = 1,
				name = "Icon",
				children = VF.View({
					tag = "row wrap gap-large auto-xy",
					LayoutOrder = 1,
					children = iconButtons,
				}),
			}),
			Section({
				LayoutOrder = 2,
				name = "Icon by type",
				contentTag = "auto-xy",
				children = MatrixGrid.MatrixGrid({
					labelColumnWidth = INFO_COLUMN_WIDTH,
					showHeader = false,
					columnHeaders = { "Button" },
					headerTextAlign = "left",
					cellAlign = "left",
					rowGap = "xxlarge",
					rows = StoryIcons.buildIconTypeMatrixRows(function(iconExample)
						return {
							StoryButton({
								text = defaultButtonProps.text,
								icon = iconExample.name,
								variant = defaultButtonProps.variant,
								size = defaultButtonProps.size,
								hug = true,
							}),
						}
					end),
				}),
			}),
			Section({
				LayoutOrder = 3,
				name = "End-aligned icon",
				contentTag = "col gap-medium align-x-left auto-xy",
				children = {
					VF.Text({
						Text = "End-aligned placement is automatic for ArrowUpRightFromSquare (see endAlignedIcons).",
						tag = "auto-xy text-body-small text-align-x-left content-default",
						LayoutOrder = 1,
					}),
					VF.View({
						tag = "auto-xy",
						LayoutOrder = 2,
						children = StoryButton({
							text = "Open link",
							icon = IconName.ArrowUpRightFromSquare,
							variant = ButtonVariant.Link,
							size = defaultButtonProps.size,
							hug = true,
						}),
					}),
				},
			}),
			Section({
				LayoutOrder = 4,
				name = "Long text",
				children = VF.View({
					tag = "row wrap gap-large auto-xy",
					LayoutOrder = 1,
					children = {
						LongTextExample({
							label = ButtonVariant.Emphasis,
							LayoutOrder = 1,
							variant = ButtonVariant.Emphasis,
							icon = defaultButtonProps.icon,
						}),
						LongTextExample({
							label = ButtonVariant.Link,
							LayoutOrder = 2,
							variant = ButtonVariant.Link,
							icon = IconName.ArrowUpRightFromSquare,
						}),
					},
				}),
			}),
		},
	})
end

local INVERSE_PRESENTATION: PresentationContext.PresentationContextValue = {
	isIconSize = false,
	colorNamespace = ColorNamespace.Inverse,
}

local function InverseSurfaceButtonExample(
	props: { label: string, LayoutOrder: number, variant: SupportedButtonVariant }
)
	local tokens = VF.Hooks.useTokens()

	return VF.View({
		tag = "col align-x-left gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-caption-small text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "row align-y-center auto-xy padding-medium radius-medium",
				backgroundStyle = function(): ColorStyleValue
					return tokens().Inverse.Surface.Surface_100 :: ColorStyleValue
				end,
				LayoutOrder = 2,
				children = PresentationContext.context(INVERSE_PRESENTATION, function()
					return StoryButton({
						useDefaults = true,
						textOnly = true,
						variant = props.variant,
						hug = true,
					})
				end),
			}),
		},
	})
end

local function InContextStory()
	local examples = {}
	for index, variant in BUTTON_VARIANTS do
		examples[index] = InverseSurfaceButtonExample({
			label = variant,
			LayoutOrder = index,
			variant = variant,
		})
	end

	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-y-large bg-surface-0",
		children = Section({
			LayoutOrder = 1,
			name = "On inverse surface",
			contentTag = "col gap-medium align-x-left auto-xy",
			children = VF.View({
				tag = "row wrap gap-large auto-xy",
				LayoutOrder = 1,
				children = examples,
			}),
		}),
	})
end

return foundation.sections({
	summary = "Buttons communicate calls to action and allow users to interact with the interface. Button labels clearly express the action that will occur when clicked.",
	controls = {
		icon = UILabs.Choose(StoryIcons.buildIconControlOptions({ additional = { IconName.ArrowUpRightFromSquare } })),
		text = defaultButtonProps.text,
		variant = UILabs.Choose(PLAYGROUND_VARIANT_OPTIONS),
		size = UILabs.Choose(PLAYGROUND_SIZE_OPTIONS),
		isDisabled = false,
		isLoading = false,
		fillBehavior = UILabs.Choose({ foundation.NONE, FillBehavior.Fit, FillBehavior.Fill }),
		width = 0,
		inputDelay = 0,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Variants", story = VariantsStory },
		{ name = "Sizing", story = SizingStory },
		{ name = "States", story = StatesStory },
		{ name = "Controlled component", story = ControlledStory },
		{
			name = "Content",
			story = function()
				return foundation.scroll(ContentStory())
			end,
		},
		{
			name = "In context",
			summary = "Button reads colorNamespace from PresentationContext, not from props.",
			story = InContextStory,
		},
	},
})
