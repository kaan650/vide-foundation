local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local ColorNamespace = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ColorNamespace")
local FillBehavior = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/FillBehavior")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local PresentationContext =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Providers/Style/PresentationContext")

type ColorStyleValue = VideFoundation.ColorStyleValue
type ColorNamespace = ColorNamespace.ColorNamespace
type InputSize = InputSize.InputSize

local IconName = VF.Enums.IconName

type IconButtonVariant = "Standard" | "Emphasis" | "SoftEmphasis" | "Utility" | "OverMedia" | "Alert"

local SUPPORTED_VARIANTS: { IconButtonVariant } = {
	ButtonVariant.Utility,
	ButtonVariant.Standard,
	ButtonVariant.Emphasis,
	ButtonVariant.SoftEmphasis,
	ButtonVariant.OverMedia,
	ButtonVariant.Alert,
}

local SIZES: { InputSize } = { InputSize.Large, InputSize.Medium, InputSize.Small, InputSize.XSmall }

local function noop() end

local function overMediaGradient(tokens: () -> any)
	return foundation.create("UIGradient")({
		Name = "Gradient",
		Color = function()
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, tokens().Color.Extended.Green.Green_500.Color3),
				ColorSequenceKeypoint.new(1, tokens().Color.Extended.Blue.Blue_500.Color3),
			})
		end,
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local tokens = VF.Hooks.useTokens()

	local function isOverMedia(): boolean
		return controls.buttonVariant() == ButtonVariant.OverMedia
	end

	return VF.View({
		tag = "row align-y-center gap-medium size-0 auto-xy padding-medium radius-medium",
		backgroundStyle = function(): ColorStyleValue
			if isOverMedia() then
				return tokens().Color.Extended.White.White_100 :: ColorStyleValue
			end
			return (tokens() :: any)[controls.colorNamespace()].Surface.Surface_100
		end,
		children = {
			Vide.show(isOverMedia, function()
				return overMediaGradient(tokens)
			end),
			--* PresentationContext holds a plain value, so a new namespace builds the button again.
			foundation.rebuildOn(controls.colorNamespace, function(colorNamespace: ColorNamespace)
				return PresentationContext.context(
						{ isIconSize = false, colorNamespace = colorNamespace },
						function()
							return VF.IconButton({
								icon = function()
									return { name = controls.name(), variant = controls.variant() }
								end,
								variant = controls.buttonVariant,
								onActivated = function()
									print(`{colorNamespace} {controls.buttonVariant()} IconButton activated`)
								end,
								isDisabled = controls.isDisabled,
								size = controls.size,
								isCircular = controls.isCircular,
								fillBehavior = foundation.orNil(controls.fillBehavior),
							})
						end
					) :: any
			end),
		},
	})
end

local VARIANT_PRESENTATION: PresentationContext.PresentationContextValue = {
	isIconSize = false,
	colorNamespace = ColorNamespace.Color,
}

local function VariantStory(variant: IconButtonVariant)
	local tokens = VF.Hooks.useTokens()
	local isOverMedia = variant == ButtonVariant.OverMedia

	local buttons = PresentationContext.context(VARIANT_PRESENTATION, function()
		local buttons = {}
		for index, size in SIZES do
			buttons[index] = VF.IconButton({
				icon = IconName.PlaySmall,
				variant = variant,
				onActivated = function()
					print(`{variant} IconButton ({size}) activated`)
				end,
				size = size,
				LayoutOrder = index,
			})
		end
		return buttons
	end)

	return VF.View({
		tag = "row align-y-center gap-medium size-0 auto-xy padding-medium radius-medium",
		backgroundStyle = if isOverMedia
			then function(): ColorStyleValue
				return tokens().Color.Extended.White.White_100 :: ColorStyleValue
			end
			else nil,
		children = {
			if isOverMedia then overMediaGradient(tokens) else nil,
			buttons,
		},
	})
end

local function LabeledRow(props: { label: string, LayoutOrder: number, rowTag: string, rowSize: UDim2?, button: any })
	return VF.View({
		LayoutOrder = props.LayoutOrder,
		tag = "col gap-xxsmall auto-xy",
		children = {
			VF.Text({
				Text = props.label,
				tag = "auto-xy text-body-small",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = props.rowTag,
				Size = props.rowSize,
				LayoutOrder = 2,
				children = props.button,
			}),
		},
	})
end

local function WidthStory()
	return VF.View({
		tag = "col gap-large size-full-0 auto-xy padding-large radius-medium",
		children = {
			LabeledRow({
				label = "Default (fixed square)",
				LayoutOrder = 1,
				rowTag = "row gap-medium auto-xy",
				button = VF.IconButton({
					icon = IconName.PlaySmall,
					variant = ButtonVariant.Emphasis,
					onActivated = noop,
					size = InputSize.Medium,
				}),
			}),
			LabeledRow({
				label = "Fixed width (0, 200px)",
				LayoutOrder = 2,
				rowTag = "row gap-medium auto-xy",
				button = VF.IconButton({
					icon = IconName.PlaySmall,
					variant = ButtonVariant.Emphasis,
					onActivated = noop,
					size = InputSize.Medium,
					width = UDim.new(0, 200),
				}),
			}),
			LabeledRow({
				label = "fillBehavior.Fill takes precedence over width=200px",
				LayoutOrder = 4,
				rowTag = "row size-full-0 auto-xy",
				rowSize = UDim2.new(1, 0, 0, 60),
				button = VF.IconButton({
					icon = IconName.PlaySmall,
					variant = ButtonVariant.Emphasis,
					onActivated = noop,
					size = InputSize.Medium,
					width = UDim.new(0, 200),
					fillBehavior = FillBehavior.Fill,
				}),
			}),
		},
	})
end

local function FillBehaviorStory()
	local function iconButton(fillBehavior: FillBehavior.FillBehavior?, layoutOrder: number)
		return VF.IconButton({
			icon = IconName.PlaySmall,
			variant = ButtonVariant.Emphasis,
			onActivated = noop,
			size = InputSize.Medium,
			fillBehavior = fillBehavior,
			LayoutOrder = layoutOrder,
		})
	end

	return VF.View({
		tag = "row gap-medium size-full-0 auto-y padding-medium radius-medium",
		children = {
			iconButton(nil, 1),
			iconButton(FillBehavior.Fit, 2),
			iconButton(FillBehavior.Fill, 3),
		},
	})
end

local sections: { foundation.Section } = { { name = "Playground", story = PlaygroundStory } }
for _, variant in SUPPORTED_VARIANTS do
	table.insert(sections, {
		name = variant,
		story = function()
			return VariantStory(variant)
		end,
	})
end
table.insert(sections, {
	name = "Width",
	summary = "Width, fillBehavior, and precedence. Default uses the fixed square size from the variant system. Width (scale or offset) overrides. fillBehavior.Fill takes precedence over width.",
	story = WidthStory,
})
table.insert(sections, {
	name = "FillBehavior",
	summary = "The same icon button rendered with each fillBehavior",
	story = FillBehaviorStory,
})

return foundation.sections({
	summary = "IconButton",
	controls = {
		name = UILabs.Choose({
			"play-small",
			"play-large",
			"play-xlarge",
			"robux",
			"heart",
			"glasses",
		}),
		variant = UILabs.Choose(Dash.values(VF.Enums.IconVariant :: any)),
		buttonVariant = UILabs.Choose(SUPPORTED_VARIANTS),
		size = UILabs.Choose(SIZES),
		isDisabled = false,
		isCircular = false,
		colorNamespace = UILabs.Choose(Dash.values(ColorNamespace :: any)),
		fillBehavior = UILabs.Choose({ foundation.NONE, FillBehavior.Fit, FillBehavior.Fill }),
	},
	sections = sections,
})
