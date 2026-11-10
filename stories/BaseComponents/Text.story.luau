local foundation = require("../foundation")
local RbxDesignFoundations = require("@game/ReplicatedStorage/Packages/VideFoundation/Packages/RbxDesignFoundations")
local VF = foundation.VF
local Vide = foundation.Vide

local ControlState = VF.Enums.ControlState

local DesignTokens: any = RbxDesignFoundations.themes[RbxDesignFoundations.Theme.Default]().Dark(1)
local NominalScale: number = DesignTokens.Config.Text.NominalScale

type Typography = { FontSize: number, LineHeight: number }

type TypographyEntry = {
	tokenName: string,
	tag: string,
}

type TypographySection = {
	name: string,
	entries: { TypographyEntry },
}

local SAMPLE_TEXT = "The quick brown fox."

local TYPOGRAPHY_SECTIONS: { TypographySection } = {
	{
		name = "Body",
		entries = {
			{ tokenName = "BodySmall", tag = "text-body-small" },
			{ tokenName = "BodyMedium", tag = "text-body-medium" },
			{ tokenName = "BodyLarge", tag = "text-body-large" },
		},
	},
	{
		name = "Caption",
		entries = {
			{ tokenName = "CaptionSmall", tag = "text-caption-small" },
			{ tokenName = "CaptionMedium", tag = "text-caption-medium" },
			{ tokenName = "CaptionLarge", tag = "text-caption-large" },
		},
	},
	{
		name = "Display",
		entries = {
			{ tokenName = "DisplaySmall", tag = "text-display-small" },
			{ tokenName = "DisplayMedium", tag = "text-display-medium" },
			{ tokenName = "DisplayLarge", tag = "text-display-large" },
		},
	},
	{
		name = "Heading",
		entries = {
			{ tokenName = "HeadingSmall", tag = "text-heading-small" },
			{ tokenName = "HeadingMedium", tag = "text-heading-medium" },
			{ tokenName = "HeadingLarge", tag = "text-heading-large" },
		},
	},
	{
		name = "Label",
		entries = {
			{ tokenName = "LabelSmall", tag = "text-label-small" },
			{ tokenName = "LabelMedium", tag = "text-label-medium" },
			{ tokenName = "LabelLarge", tag = "text-label-large" },
		},
	},
	{
		name = "Title",
		entries = {
			{ tokenName = "TitleSmall", tag = "text-title-small" },
			{ tokenName = "TitleMedium", tag = "text-title-medium" },
			{ tokenName = "TitleLarge", tag = "text-title-large" },
		},
	},
}

local function formatTypographySpecs(typography: Typography): string
	local trueTextSize = typography.FontSize / NominalScale
	local trueLineHeight = typography.LineHeight * NominalScale
	local desiredLineSize = trueTextSize * trueLineHeight
	return string.format(
		"%dpx / %.1f (%dpx line)",
		math.round(trueTextSize),
		trueLineHeight,
		math.round(desiredLineSize)
	)
end

local function typographyLabel(size: string, tag: string)
	return VF.View({
		tag = "col gap-xsmall size-full-0 auto-y",
		children = {
			VF.Text({
				Text = size,
				tag = "size-full-0 auto-y text-caption-small text-wrap text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.Text({
				Text = tag,
				tag = "size-full-0 auto-y text-caption-small text-wrap text-align-x-left content-muted",
				LayoutOrder = 2,
			}),
		},
	})
end

local function TypographyRow(props: { LayoutOrder: number, size: string, tag: string, specs: () -> string })
	return VF.View({
		tag = "row gap-large size-full-0 auto-y padding-y-small",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.View({
				tag = "col size-full-0 auto-y",
				Size = UDim2.fromOffset(140, 0),
				LayoutOrder = 1,
				children = typographyLabel(props.size, props.tag),
			}),
			VF.Text({
				Text = SAMPLE_TEXT,
				tag = `size-full-0 auto-y text-wrap text-align-x-left content-default {props.tag}`,
				LayoutOrder = 2,
			}),
			VF.Text({
				Text = props.specs,
				tag = "auto-xy text-caption-small text-align-x-left content-muted",
				Size = UDim2.fromOffset(140, 0),
				LayoutOrder = 3,
			}),
		},
	})
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
				tag = "col size-full-0 auto-y",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.Text({
		Text = controls.text,
		RichText = controls.richText,
		fontStyle = function()
			return { FontSize = controls.textSize() }
		end,
		tag = "auto-xy content-default",
	})
end

local function InteractableStory()
	local guiState = Vide.source(ControlState.Initialize :: string)
	local tokens = VF.Hooks.useTokens()

	return VF.Text({
		Text = function()
			return "State: " .. guiState()
		end,
		fontStyle = { FontSize = 20 },
		backgroundStyle = function()
			return tokens().Color.Extended.Purple.Purple_500 :: any
		end,
		tag = "col align-x-center align-y-center size-2800 content-default",
		onStateChanged = function(new)
			guiState(new)
		end,
	})
end

local function TypographyStory()
	local tokens = VF.Hooks.useTokens()

	local sections = {}
	for sectionIndex, section in TYPOGRAPHY_SECTIONS do
		local rows = {}
		for rowIndex, entry in section.entries do
			rows[rowIndex] = TypographyRow({
				LayoutOrder = rowIndex,
				size = entry.tokenName:match("(%a+)$") :: string,
				tag = entry.tag,
				specs = function()
					return formatTypographySpecs((tokens().Typography :: any)[entry.tokenName])
				end,
			})
		end
		sections[sectionIndex] = Section({ LayoutOrder = sectionIndex, name = section.name, children = rows })
	end

	return VF.View({
		tag = "col gap-xlarge size-full-0 auto-y padding-y-large",
		children = {
			VF.View({
				tag = "row align-y-center gap-large size-full-0 auto-y padding-y-small",
				LayoutOrder = 1,
				children = {
					VF.View({
						Size = UDim2.fromOffset(140, 0),
						LayoutOrder = 1,
					}),
					VF.Text({
						Text = "Preview",
						tag = "size-full-0 auto-y text-caption-small text-align-x-left content-muted",
						LayoutOrder = 2,
					}),
					VF.Text({
						Text = "Token specs",
						tag = "auto-xy text-caption-small text-align-x-left content-muted",
						Size = UDim2.fromOffset(140, 0),
						LayoutOrder = 3,
					}),
				},
			}),
			VF.View({
				tag = "col gap-xlarge size-full-0 auto-y",
				LayoutOrder = 2,
				children = sections,
			}),
		},
	})
end

return foundation.sections({
	summary = "Text",
	controls = {
		text = "Hello, world!",
		textSize = 24,
		richText = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Typography",
			summary = "Matrix of every Typography token with its hard-coded style tag.",
			story = function()
				return foundation.scroll(TypographyStory())
			end,
		},
		{ name = "Interactable", story = InteractableStory },
	},
})
