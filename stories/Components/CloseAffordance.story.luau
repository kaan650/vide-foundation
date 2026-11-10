local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local CloseAffordanceVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/CloseAffordanceVariant")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")

type ColorStyleValue = VideFoundation.ColorStyleValue
type CloseAffordanceSize = typeof(InputSize.Medium) | typeof(InputSize.Small) | typeof(InputSize.XSmall)
type CloseAffordanceVariant = CloseAffordanceVariant.CloseAffordanceVariant

local CloseAffordance = VF.UNSTABLE.CloseAffordance

local SIZES: { CloseAffordanceSize } = { InputSize.Medium, InputSize.Small, InputSize.XSmall }

local function activated(label: string)
	return function()
		print(`CloseAffordance: "{label}" activated`)
	end
end

local function Label(props: { text: string, LayoutOrder: number })
	return VF.Text({
		Text = props.text,
		tag = "auto-xy padding-bottom-xsmall text-label-small content-muted",
		LayoutOrder = props.LayoutOrder,
	})
end

local function Section(props: { label: string, LayoutOrder: number, children: any })
	return VF.View({
		tag = "col align-y-center gap-xsmall auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			Label({ text = props.label, LayoutOrder = 1 }),
			VF.View({
				tag = "row align-y-center gap-small auto-xy",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function MediaBackground(children: any)
	local tokens = VF.Hooks.useTokens()
	return VF.View({
		tag = "row align-y-center gap-medium size-0 auto-xy padding-large radius-medium",
		backgroundStyle = function(): ColorStyleValue
			return tokens().Color.Extended.White.White_100 :: ColorStyleValue
		end,
		children = children,
	})
end

--- One CloseAffordance per size, with the given props.
local function eachSize(props: {
	variant: CloseAffordanceVariant,
	label: string,
	isCircular: boolean?,
	hasPadding: boolean?,
	isDisabled: boolean?,
})
	return Dash.map(SIZES, function(size: CloseAffordanceSize)
		return CloseAffordance({
			size = size,
			variant = props.variant,
			isCircular = props.isCircular,
			hasPadding = props.hasPadding,
			isDisabled = props.isDisabled,
			onActivated = activated(`{props.label} {size}`),
		})
	end)
end

local function PlaygroundStory(controls: { [string]: any })
	local tokens = VF.Hooks.useTokens()

	return VF.View({
		tag = "row align-x-center align-y-center size-0 auto-xy padding-xlarge radius-medium",
		backgroundStyle = function(): ColorStyleValue
			return if controls.variant() == CloseAffordanceVariant.OverMedia
				then tokens().Color.Extended.White.White_100 :: ColorStyleValue
				else nil :: any
		end,
		children = CloseAffordance({
			size = controls.size,
			variant = controls.variant,
			isCircular = controls.isCircular,
			hasPadding = controls.hasPadding,
			isDisabled = controls.isDisabled,
			onActivated = function()
				print(`CloseAffordance activated: {controls.variant()} {controls.size()}`)
			end,
		}),
	})
end

local function OverMediaStory()
	return VF.View({
		tag = "col gap-large auto-xy",
		children = {
			Section({
				label = "hasPadding = true",
				LayoutOrder = 1,
				children = MediaBackground(eachSize({
					variant = CloseAffordanceVariant.OverMedia,
					label = "OverMedia padded",
					hasPadding = true,
				})),
			}),
			Section({
				label = "hasPadding = false",
				LayoutOrder = 2,
				children = MediaBackground(eachSize({
					variant = CloseAffordanceVariant.OverMedia,
					label = "OverMedia tight",
					hasPadding = false,
				})),
			}),
		},
	})
end

local function UtilityStory()
	return VF.View({
		tag = "col gap-large auto-xy",
		children = {
			Section({
				label = "isCircular = false",
				LayoutOrder = 1,
				children = eachSize({
					variant = CloseAffordanceVariant.Utility,
					label = "Utility rounded",
					isCircular = false,
					hasPadding = true,
				}),
			}),
			Section({
				label = "isCircular = true",
				LayoutOrder = 2,
				children = eachSize({
					variant = CloseAffordanceVariant.Utility,
					label = "Utility circular",
					isCircular = true,
					hasPadding = true,
				}),
			}),
			Section({
				label = "hasPadding = false, isCircular = false",
				LayoutOrder = 3,
				children = eachSize({
					variant = CloseAffordanceVariant.Utility,
					label = "Utility tight rounded",
					isCircular = false,
					hasPadding = false,
				}),
			}),
			Section({
				label = "hasPadding = false, isCircular = true",
				LayoutOrder = 4,
				children = eachSize({
					variant = CloseAffordanceVariant.Utility,
					label = "Utility tight circular",
					isCircular = true,
					hasPadding = false,
				}),
			}),
		},
	})
end

local function DisabledStory()
	return VF.View({
		tag = "col gap-large auto-xy",
		children = {
			Section({
				label = "OverMedia",
				LayoutOrder = 1,
				children = MediaBackground(eachSize({
					variant = CloseAffordanceVariant.OverMedia,
					label = "OverMedia disabled",
					isDisabled = true,
				})),
			}),
			Section({
				label = "Utility",
				LayoutOrder = 2,
				children = eachSize({
					variant = CloseAffordanceVariant.Utility,
					label = "Utility disabled",
					isDisabled = true,
				}),
			}),
		},
	})
end

return foundation.sections({
	summary = "CloseAffordance",
	controls = {
		variant = UILabs.Choose(Dash.values(CloseAffordanceVariant :: any)),
		size = UILabs.Choose(SIZES),
		isCircular = true,
		hasPadding = true,
		isDisabled = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "OverMedia", story = OverMediaStory },
		{ name = "Utility", story = UtilityStory },
		{ name = "Disabled", story = DisabledStory },
	},
})
