local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local ButtonVariant = VF.Enums.ButtonVariant
local InputSize = VF.Enums.InputSize
local PopoverAlign = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/PopoverAlign")
local PopoverSide = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/PopoverSide")

type PopoverAlign = PopoverAlign.PopoverAlign
type PopoverSide = PopoverSide.PopoverSide
type ButtonGroupItem = VideFoundation.ButtonGroupItem
type CoachmarkSteps = VideFoundation.CoachmarkSteps

local SAMPLE_TITLE = "Discover the new feature"
local SAMPLE_TEXT = "A system-triggered contextual surface that highlights new features or guides important tasks."

--* Bottom first so the tooltip opens directly beneath its anchor by default.
local SIDE_OPTIONS: { PopoverSide } = {
	PopoverSide.Bottom,
	PopoverSide.Top,
	PopoverSide.Left,
	PopoverSide.Right,
}

local ALIGN_OPTIONS: { PopoverAlign } = {
	PopoverAlign.Start,
	PopoverAlign.Center,
	PopoverAlign.End,
}

local function noop() end

local function generateActions(hasSecondaryButton: boolean): { ButtonGroupItem }
	local actions: { ButtonGroupItem } = {
		{
			text = "Got it",
			variant = ButtonVariant.Emphasis,
			onActivated = noop,
		},
	}

	if hasSecondaryButton then
		table.insert(actions, {
			text = "Skip",
			variant = ButtonVariant.Standard,
			onActivated = noop,
		})
	end

	return actions
end

--* An in-experience screenshot stands in for the feature the tooltip introduces. The top corners match the
--* tooltip's own radius.
local SAMPLE_MEDIA = Content.fromAssetId(88076582911570)
local MEDIA_HEIGHT = 136

local function makeMedia()
	return VF.Image({
		ImageContent = SAMPLE_MEDIA,
		ScaleType = Enum.ScaleType.Crop,
		tag = "radius-top-medium",
		Size = UDim2.new(1, 0, 0, MEDIA_HEIGHT),
	})
end

type ShowcaseProps = {
	height: number,
	LayoutOrder: number?,
	side: PopoverSide?,
	align: PopoverAlign?,
	anchorAlign: string?,
	anchorText: string?,
	title: string?,
	text: string?,
	steps: CoachmarkSteps?,
	hasClose: boolean?,
	media: (() -> any)?,
	actions: { ButtonGroupItem }?,
}

--- One open tooltip in a fixed-height block that reserves room for it, so stacked showcases do not overlap.
--- `anchorAlign` places the anchor so the popover has space to open toward its `side`.
local function Showcase(props: ShowcaseProps)
	return VF.View({
		tag = `col size-full-0 padding-large {props.anchorAlign or "align-x-left align-y-top"}`,
		Size = UDim2.new(1, 0, 0, props.height),
		LayoutOrder = props.LayoutOrder,
		children = VF.EducationalTooltip({
			isOpen = true,
			side = props.side or PopoverSide.Bottom,
			align = props.align or PopoverAlign.Start,
			title = props.title or SAMPLE_TITLE,
			text = props.text,
			steps = props.steps,
			onClose = if props.hasClose then noop else nil,
			media = props.media,
			actions = props.actions,
			children = VF.Button({
				text = props.anchorText or "Anchor",
				size = InputSize.Small,
				variant = ButtonVariant.Standard,
				onActivated = noop,
			}),
		}),
	})
end

local function PlaygroundStory(controls: { [string]: any })
	--* Open state is driven by the anchor and the close affordance, so toggling controls leaves it open.
	local isOpen = Vide.source(true)

	return VF.View({
		tag = "col align-x-left align-y-top padding-large",
		Size = UDim2.new(1, 0, 0, 320),
		--* `onClose` and `media` take plain values, so a change builds the tooltip again.
		children = foundation.rebuildOn(function()
			return `{controls.hasCloseAffordance()}/{controls.hasMedia()}`
		end, function()
			return VF.EducationalTooltip({
				title = controls.title,
				text = function(): string?
					local text = controls.text()
					return if text ~= "" then text else nil
				end,
				side = controls.side,
				align = controls.align,
				isOpen = isOpen,
				steps = function(): CoachmarkSteps?
					return if controls.showSteps() then { current = 2, total = 5 } else nil
				end,
				onClose = if controls.hasCloseAffordance()
					then function()
						isOpen(false)
					end
					else nil,
				media = if controls.hasMedia() then makeMedia else nil,
				actions = function(): { ButtonGroupItem }?
					return if controls.hasActions() then generateActions(controls.hasSecondaryButton()) else nil
				end,
				children = VF.Button({
					text = function()
						return if isOpen() then "Close tooltip" else "Open tooltip"
					end,
					size = InputSize.Medium,
					onActivated = function()
						isOpen(not isOpen())
					end,
				}),
			}) :: any
		end),
	})
end

local function ContentStory()
	return VF.View({
		tag = "col gap-large size-full-0 auto-y",
		children = {
			Showcase({
				LayoutOrder = 1,
				height = 140,
				title = "Title only",
			}),
			Showcase({
				LayoutOrder = 2,
				height = 220,
				title = "Title + body text",
				text = SAMPLE_TEXT,
			}),
			Showcase({
				LayoutOrder = 3,
				height = 240,
				title = "Step indicator",
				text = SAMPLE_TEXT,
				steps = { current = 2, total = 5 },
			}),
			Showcase({
				LayoutOrder = 4,
				height = 360,
				title = "Media",
				text = SAMPLE_TEXT,
				media = makeMedia,
			}),
			Showcase({
				LayoutOrder = 5,
				height = 240,
				title = "Primary + secondary actions",
				text = SAMPLE_TEXT,
				actions = generateActions(true),
			}),
			Showcase({
				LayoutOrder = 6,
				height = 240,
				title = "Dismissible (close affordance)",
				text = SAMPLE_TEXT,
				hasClose = true,
				actions = generateActions(false),
			}),
		},
	})
end

--- One open tooltip per side, anchored in the center of a tall block so it can open in any direction.
local function PlacementStory()
	local children = {}
	for index, side in SIDE_OPTIONS do
		children[index] = Showcase({
			LayoutOrder = index,
			height = 300,
			anchorAlign = "align-x-center align-y-center",
			anchorText = side,
			side = side,
			align = PopoverAlign.Center,
			title = `Side: {side}`,
			text = SAMPLE_TEXT,
			actions = generateActions(false),
		})
	end

	return VF.View({
		tag = "col gap-large size-full-0 auto-y",
		children = children,
	})
end

--- The same side (Bottom) with each alignment, to compare the popover's shift along its anchor.
local function AlignmentStory()
	local children = {}
	for index, align in ALIGN_OPTIONS do
		children[index] = Showcase({
			LayoutOrder = index,
			height = 220,
			anchorAlign = "align-x-center align-y-top",
			anchorText = align,
			side = PopoverSide.Bottom,
			align = align,
			title = `Align: {align}`,
			text = SAMPLE_TEXT,
		})
	end

	return VF.View({
		tag = "col gap-large size-full-0 auto-y",
		children = children,
	})
end

type StepConfig = {
	text: string,
	hasActions: boolean,
	side: PopoverSide,
	align: PopoverAlign,
}

local STEP_CONFIGS: { StepConfig } = {
	{
		text = "Step 1: side = Bottom, align = Start, primary action only.",
		hasActions = true,
		side = PopoverSide.Bottom,
		align = PopoverAlign.Start,
	},
	{
		text = "Step 2: side = Right, align = Center, no actions.",
		hasActions = false,
		side = PopoverSide.Right,
		align = PopoverAlign.Center,
	},
	{
		text = "Step 3: side = Top, align = End, primary action only.",
		hasActions = true,
		side = PopoverSide.Top,
		align = PopoverAlign.End,
	},
	{
		text = "Step 4: side = Left, align = Center, no actions.",
		hasActions = false,
		side = PopoverSide.Left,
		align = PopoverAlign.Center,
	},
}

local function MultiStepTutorialStory()
	local step = Vide.source(1)

	local function config(): StepConfig
		return STEP_CONFIGS[step()]
	end

	local function goNext()
		step(math.min(#STEP_CONFIGS, step() + 1))
	end

	return VF.View({
		tag = "col gap-large size-full-0 auto-y padding-large",
		Size = UDim2.new(1, 0, 0, 360),
		children = {
			VF.View({
				tag = "row align-y-center gap-small size-full-0 auto-y",
				LayoutOrder = 1,
				children = {
					VF.Button({
						text = "Previous",
						variant = ButtonVariant.Standard,
						isDisabled = function()
							return step() == 1
						end,
						onActivated = function()
							step(math.max(1, step() - 1))
						end,
						LayoutOrder = 1,
					}),
					VF.Button({
						text = "Next",
						variant = ButtonVariant.Standard,
						isDisabled = function()
							return step() == #STEP_CONFIGS
						end,
						onActivated = goNext,
						LayoutOrder = 2,
					}),
					VF.Text({
						tag = "auto-xy text-body-medium",
						Text = function()
							return `Step {step()} of {#STEP_CONFIGS}`
						end,
						LayoutOrder = 3,
					}),
				},
			}),
			VF.View({
				tag = "row align-x-center align-y-center size-full-0",
				Size = UDim2.new(1, 0, 0, 260),
				LayoutOrder = 2,
				children = VF.EducationalTooltip({
					title = function()
						return `Tutorial step {step()}`
					end,
					text = function()
						return config().text
					end,
					isOpen = true,
					side = function()
						return config().side
					end,
					align = function()
						return config().align
					end,
					steps = function(): CoachmarkSteps?
						return { current = step(), total = #STEP_CONFIGS }
					end,
					actions = function(): { ButtonGroupItem }?
						return if config().hasActions
							then {
								{
									text = "Next",
									variant = ButtonVariant.Emphasis,
									onActivated = goNext,
								},
							}
							else nil
					end,
					children = VF.Button({
						text = "Anchor",
						onActivated = noop,
					}),
				}),
			}),
		},
	})
end

return foundation.sections({
	summary = "System-triggered popover for highlighting features or guiding tasks.",
	controls = {
		title = SAMPLE_TITLE,
		text = SAMPLE_TEXT,
		side = UILabs.Choose(SIDE_OPTIONS),
		align = UILabs.Choose(ALIGN_OPTIONS),
		showSteps = true,
		hasCloseAffordance = true,
		hasActions = true,
		hasSecondaryButton = true,
		hasMedia = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{
			name = "Content",
			summary = "Optional content props: title, body text, step indicator, media, actions, and close affordance.",
			story = function()
				return foundation.scroll(ContentStory())
			end,
		},
		{
			name = "Placement",
			summary = "The `side` prop positions the popover relative to its anchor.",
			story = function()
				return foundation.scroll(PlacementStory())
			end,
		},
		{
			name = "Alignment",
			summary = "The `align` prop shifts the popover along the anchor's cross axis.",
			story = AlignmentStory,
		},
		{
			name = "Multi-step tutorial",
			summary = "Drives isOpen, side, align, steps, and actions from state to build a guided flow.",
			story = MultiStepTutorialStory,
		},
	},
})
