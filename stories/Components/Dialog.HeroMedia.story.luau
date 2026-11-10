local DialogStoryHelpers = require("../Shared/DialogStoryHelpers")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local foundation = require("../foundation")
local VF = foundation.VF
local UILabs = foundation.UILabs
local Vide = foundation.Vide

local DialogSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/DialogSize")

type ColorStyleValue = VideFoundation.ColorStyleValue
type DialogHeroMediaOptions = DialogStoryHelpers.DialogHeroMediaOptions
type DialogSize = DialogSize.DialogSize
type Tokens = VideFoundation.Tokens

local LabeledDialogTrigger = DialogStoryHelpers.LabeledDialogTrigger
local Section = DialogStoryHelpers.Section
local heroMediaDialogChildren = DialogStoryHelpers.heroMediaDialogChildren
local makeDialogChildren = DialogStoryHelpers.makeDialogChildren

local SIZE_ORDER: { DialogSize } = DialogStoryHelpers.SIZE_ORDER
local HERO_MEDIA = DialogStoryHelpers.HERO_MEDIA
local HERO_MEDIA_TRANSPARENT = "component_assets/contactFullAvatar_small"
local HERO_MEDIA_FIXED_HEIGHT = UDim.new(0, 160)
local ASPECT_RATIOS: { { label: string, value: number } } = {
	{ label = "16:9", value = 16 / 9 },
	{ label = "4:3", value = 4 / 3 },
	{ label = "1:1", value = 1 },
	{ label = "21:9", value = 21 / 9 },
}
local ASPECT_RATIO_LABELS: { string } = {}
for index, ratio in ASPECT_RATIOS do
	ASPECT_RATIO_LABELS[index] = ratio.label
end
table.insert(ASPECT_RATIO_LABELS, "None")

local HERO_MEDIA_DEFAULT_LABEL = `Default hero image ({HERO_MEDIA})`
local HERO_MEDIA_TRANSPARENT_LABEL = `Transparent asset ({HERO_MEDIA_TRANSPARENT})`

local function aspectRatioFromLabel(label: string?): number?
	if label == nil or label == "None" then
		return nil
	end
	for _, ratio in ASPECT_RATIOS do
		if ratio.label == label then
			return ratio.value
		end
	end
	return 16 / 9
end

local function greenFill(tokens: Tokens): ColorStyleValue
	return tokens.Color.Extended.Green.Green_500 :: ColorStyleValue
end

local function blueTint(tokens: Tokens): ColorStyleValue
	return {
		Color3 = tokens.Color.Extended.Blue.Blue_500.Color3,
		Transparency = 0.4,
	}
end

local function heroMediaFromControls(controls: { [string]: any }, tokens: () -> Tokens): DialogHeroMediaOptions
	return {
		aspectRatio = aspectRatioFromLabel(controls.aspectRatio()),
		media = if controls.media() == HERO_MEDIA_TRANSPARENT_LABEL then HERO_MEDIA_TRANSPARENT else nil,
		backgroundStyle = if controls.backgroundStyle() == "green fill"
			then function()
				return greenFill(tokens())
			end
			else nil,
		mediaStyle = if controls.mediaStyle() == "blue tint"
			then function()
				return blueTint(tokens())
			end
			else nil,
		height = if controls.height() == "160px" then HERO_MEDIA_FIXED_HEIGHT else nil,
	}
end

local function Page(children: any)
	return VF.View({
		tag = "col gap-xxlarge size-full-0 auto-y padding-large bg-surface-0",
		children = children,
	})
end

local function PlaygroundStory(controls: { [string]: any })
	local tokens = VF.Hooks.useTokens()

	return DialogStoryHelpers.RootStory({
		size = controls.rootSize,
		hasBackdrop = true,
		children = function()
			--* HeroMedia leaves its aspect ratio and styles unset for "None" and "unset", and a binding can't yield
			--* nil, so the parts are built again when a control changes, while the dialog stays open.
			return foundation.rebuildOn(function()
				return `{controls.aspectRatio()}|{controls.media()}|{controls.backgroundStyle()}|{controls.mediaStyle()}|{controls.height()}`
			end, function()
				return makeDialogChildren({
					hasHeroMedia = true,
					heroMedia = Vide.untrack(function()
						return heroMediaFromControls(controls, tokens)
					end),
				})()
			end)
		end,
	})
end

local function SizingStory()
	local tokens = VF.Hooks.useTokens()

	local sizes = {}
	for index, size in SIZE_ORDER do
		sizes[index] = LabeledDialogTrigger({
			label = size,
			layoutOrder = index,
			size = size,
			children = heroMediaDialogChildren(),
		})
	end

	local ratios = {}
	for index, ratio in ASPECT_RATIOS do
		ratios[index] = LabeledDialogTrigger({
			label = ratio.label,
			layoutOrder = index,
			children = heroMediaDialogChildren({
				aspectRatio = ratio.value,
			}),
		})
	end

	return Page({
		Section({
			layoutOrder = 1,
			name = "Size",
			children = sizes,
		}),
		Section({
			layoutOrder = 2,
			name = "Aspect ratio",
			note = "aspectRatio accepts any number; values shown are representative examples, not enum values.",
			children = ratios,
		}),
		Section({
			layoutOrder = 3,
			name = "Height",
			note = "height accepts any UDim; 160px is a representative example. Default height scales with aspect ratio.",
			children = LabeledDialogTrigger({
				label = "160px",
				layoutOrder = 1,
				children = heroMediaDialogChildren({
					mediaStyle = function()
						return blueTint(tokens())
					end,
					height = HERO_MEDIA_FIXED_HEIGHT,
				}),
			}),
		}),
	})
end

local function ContentStory()
	local tokens = VF.Hooks.useTokens()

	return Page({
		Section({
			layoutOrder = 1,
			name = "Transparency",
			note = "Transparent assets reveal the Image background through alpha. backgroundStyle fills the hero area; without it, only opaque pixels render.",
			children = {
				LabeledDialogTrigger({
					label = "Without backgroundStyle",
					layoutOrder = 1,
					children = heroMediaDialogChildren({
						media = HERO_MEDIA_TRANSPARENT,
					}),
				}),
				LabeledDialogTrigger({
					label = "With backgroundStyle",
					layoutOrder = 2,
					children = heroMediaDialogChildren({
						media = HERO_MEDIA_TRANSPARENT,
						backgroundStyle = function()
							return greenFill(tokens())
						end,
					}),
				}),
			},
		}),
		Section({
			layoutOrder = 2,
			name = "Style",
			children = {
				LabeledDialogTrigger({
					label = "Without mediaStyle",
					layoutOrder = 1,
					children = heroMediaDialogChildren(),
				}),
				LabeledDialogTrigger({
					label = "With mediaStyle",
					layoutOrder = 2,
					children = heroMediaDialogChildren({
						mediaStyle = function()
							return blueTint(tokens())
						end,
					}),
				}),
			},
		}),
	})
end

return foundation.sections({
	summary = "Renders a full-width hero image above the dialog title. Corner radius and horizontal bleed follow root size via DialogProvider. Mounting HeroMedia sets hasHeroMedia on context so title padding adjusts.",
	controls = {
		rootSize = UILabs.Choose(foundation.Dash.values(DialogSize :: any)),
		aspectRatio = UILabs.Choose(ASPECT_RATIO_LABELS),
		media = UILabs.Choose({ HERO_MEDIA_DEFAULT_LABEL, HERO_MEDIA_TRANSPARENT_LABEL }),
		backgroundStyle = UILabs.Choose({ "unset", "green fill" }),
		mediaStyle = UILabs.Choose({ "unset", "blue tint" }),
		height = UILabs.Choose({ "default scale", "160px" }),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizing", story = SizingStory },
		{ name = "Content", story = ContentStory },
	},
})
