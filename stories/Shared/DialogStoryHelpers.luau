local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide

local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local DialogActions = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Dialog/Actions")
local DialogSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/DialogSize")
local InputSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/InputSize")
local OnCloseCallbackReason = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/OnCloseCallbackReason")
local Orientation = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/Orientation")

type ColorStyle = VideFoundation.ColorStyle
type DialogAction = DialogActions.DialogAction
type DialogSize = DialogSize.DialogSize
type OnCloseCallbackReason = OnCloseCallbackReason.OnCloseCallbackReason
type Orientation = Orientation.Orientation
type Value<T> = VideFoundation.Value<T>

--- Builds a dialog's parts. Call it inside `Dialog.Root`'s `children`.
export type DialogChildren = () -> any

export type DialogHeroMediaOptions = {
	media: string?,
	aspectRatio: number?,
	mediaStyle: ColorStyle?,
	backgroundStyle: ColorStyle?,
	height: UDim?,
}

export type DialogChildrenOptions = {
	title: Value<string>?,
	hasTitle: boolean?,
	content: Value<string>?,
	contentSelectable: boolean?,
	-- Builds what goes inside Dialog.Content instead of the default Dialog.Text.
	contentChildren: (() -> any)?,
	hasHeroMedia: boolean?,
	heroMedia: DialogHeroMediaOptions?,
	hasActions: boolean?,
	actions: { DialogAction }?,
	actionsOrientation: Value<Orientation>?,
	actionsLabel: Value<string?>?,
}

local SIZE_ORDER: { DialogSize } = {
	DialogSize.Small,
	DialogSize.Medium,
	DialogSize.Large,
}

local DEFAULT_SIZE: DialogSize = DialogSize.Medium
--* Dialog.HeroMedia's `media` is a string (it also takes image-set names), so the asset is passed as its URI.
local HERO_MEDIA = Content.fromAssetId(103403748802347).Uri :: string
local DEFAULT_HERO_MEDIA_ASPECT_RATIO = 16 / 9
local SHORT_CONTENT = "Dialog.Text content goes here."

local DEFAULT_ACTIONS: { DialogAction } = {
	{
		text = "Cancel",
		variant = ButtonVariant.Standard,
		onActivated = function() end,
	},
	{
		text = "Confirm",
		variant = ButtonVariant.Emphasis,
		onActivated = function() end,
	},
}

--- A List.Root of `itemCount` plain items, for scrolling dialog content.
local function dialogStoryList(itemCount: number, layoutOrder: number?)
	return VF.List.Root({
		LayoutOrder = layoutOrder,
		isContained = {
			isContained = false :: false,
			hasMargin = false,
		},
		hasDivider = {
			hasDivider = true :: true,
			isInset = false,
		},
		size = InputSize.Small,
		children = function()
			local items = {}
			for index = 1, itemCount do
				items[index] = VF.List.Item({
					title = `Item {index}`,
					onActivated = function() end,
					LayoutOrder = index,
				})
			end
			return items
		end,
	})
end

--- The parts of a story dialog: optional hero media, a title, Dialog.Content and optional actions.
local function makeDialogChildren(options: DialogChildrenOptions?): DialogChildren
	local config: DialogChildrenOptions = options or {}

	return function()
		local heroMedia = config.heroMedia
		local contentChildren = config.contentChildren

		return {
			if config.hasHeroMedia
				then VF.Dialog.HeroMedia({
					media = (heroMedia and heroMedia.media) or HERO_MEDIA,
					aspectRatio = if heroMedia then heroMedia.aspectRatio else DEFAULT_HERO_MEDIA_ASPECT_RATIO,
					mediaStyle = if heroMedia then heroMedia.mediaStyle else nil,
					backgroundStyle = if heroMedia then heroMedia.backgroundStyle else nil,
					height = if heroMedia then heroMedia.height else nil,
				})
				else nil,
			if config.hasTitle ~= false then VF.Dialog.Title({ text = config.title or "Dialog title" }) else nil,
			VF.Dialog.Content({
				LayoutOrder = 2,
				Selectable = config.contentSelectable,
				children = if contentChildren
					then contentChildren()
					else VF.Dialog.Text({
						Text = config.content or SHORT_CONTENT,
						LayoutOrder = 1,
					}),
			}),
			if config.hasActions
				then VF.Dialog.Actions({
					LayoutOrder = 3,
					orientation = config.actionsOrientation,
					label = config.actionsLabel,
					actions = config.actions or DEFAULT_ACTIONS,
				})
				else nil,
		}
	end
end

local function minimalDialogChildren(title: Value<string>?, content: Value<string>?): DialogChildren
	return makeDialogChildren({
		title = title,
		content = content,
	})
end

local function listDialogChildren(itemCount: number, contentSelectable: boolean?): DialogChildren
	return makeDialogChildren({
		contentSelectable = contentSelectable,
		contentChildren = function()
			return dialogStoryList(itemCount)
		end,
	})
end

local function heroMediaDialogChildren(heroMedia: DialogHeroMediaOptions?): DialogChildren
	local options: DialogHeroMediaOptions = if heroMedia then table.clone(heroMedia) else {}
	if options.aspectRatio == nil then
		options.aspectRatio = DEFAULT_HERO_MEDIA_ASPECT_RATIO
	end

	return makeDialogChildren({
		hasHeroMedia = true,
		heroMedia = options,
	})
end

--- A titled group of examples, with an optional note under the title.
local function Section(props: {
	layoutOrder: number,
	name: string,
	note: string?,
	contentTag: string?,
	children: any,
})
	local title = if props.note
		then VF.View({
			tag = "col gap-xsmall auto-xy",
			LayoutOrder = 1,
			children = {
				VF.Text({
					Text = props.name,
					tag = "auto-xy text-label-medium content-default",
					LayoutOrder = 1,
				}),
				VF.Text({
					Text = props.note,
					tag = "auto-xy text-body-small content-muted",
					LayoutOrder = 2,
				}),
			},
		})
		else VF.Text({
			Text = props.name,
			tag = "auto-xy text-label-medium content-default",
			LayoutOrder = 1,
		})

	return VF.View({
		tag = "col gap-medium size-full-0 auto-y",
		LayoutOrder = props.layoutOrder,
		children = {
			title,
			VF.View({
				tag = props.contentTag or "row gap-large align-y-start auto-xy wrap",
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

--- A Dialog.Root with the stories' defaults: Medium, with a backdrop, in the overlay.
local function DialogExample(props: {
	size: Value<DialogSize>?,
	hasBackdrop: Value<boolean>?,
	disablePortal: Value<boolean>?,
	onClose: ((reason: OnCloseCallbackReason?) -> ())?,
	children: DialogChildren,
})
	return VF.Dialog.Root({
		size = props.size or DEFAULT_SIZE,
		hasBackdrop = if props.hasBackdrop ~= nil then props.hasBackdrop else true,
		disablePortal = if props.disablePortal ~= nil then props.disablePortal else false,
		onClose = props.onClose,
		children = props.children,
	})
end

--- A button that opens and closes a dialog, with an optional label above it.
local function LabeledDialogTrigger(props: {
	label: string?,
	layoutOrder: number,
	buttonText: string?,
	size: DialogSize?,
	hasBackdrop: boolean?,
	children: DialogChildren,
})
	local isOpen = Vide.source(false)

	return VF.View({
		tag = "col gap-small auto-xy",
		LayoutOrder = props.layoutOrder,
		children = {
			if props.label
				then VF.Text({
					Text = props.label,
					tag = "auto-xy text-caption-small text-align-x-left content-default",
					LayoutOrder = 1,
				})
				else nil,
			VF.View({
				tag = "auto-xy",
				LayoutOrder = 2,
				children = VF.Button({
					text = function()
						return if isOpen() then "Close" else (props.buttonText or "Open")
					end,
					onActivated = function()
						isOpen(not isOpen())
					end,
					variant = function()
						return if isOpen() then ButtonVariant.Standard else ButtonVariant.Emphasis
					end,
				}),
			}),
			Vide.show(isOpen, function()
				return DialogExample({
					size = props.size,
					hasBackdrop = props.hasBackdrop,
					onClose = function()
						isOpen(false)
					end,
					children = props.children,
				})
			end),
		},
	})
end

--- The Playground of the Dialog stories: a button toggling one dialog built from the controls.
local function RootStory(props: {
	size: Value<DialogSize>?,
	hasBackdrop: Value<boolean>?,
	disablePortal: Value<boolean>?,
	children: DialogChildren?,
})
	local isOpen = Vide.source(false)

	return VF.View({
		tag = "auto-xy",
		children = {
			VF.Button({
				text = function()
					return if isOpen() then "Close Dialog" else "Open Dialog"
				end,
				onActivated = function()
					isOpen(not isOpen())
				end,
				variant = ButtonVariant.Emphasis,
			}),
			Vide.show(isOpen, function()
				return DialogExample({
					size = props.size,
					hasBackdrop = props.hasBackdrop,
					disablePortal = props.disablePortal,
					onClose = function()
						isOpen(false)
					end,
					children = props.children or minimalDialogChildren(),
				})
			end),
		},
	})
end

return {
	DEFAULT_SIZE = DEFAULT_SIZE,
	DEFAULT_ACTIONS = DEFAULT_ACTIONS,
	SIZE_ORDER = SIZE_ORDER,
	SHORT_CONTENT = SHORT_CONTENT,
	HERO_MEDIA = HERO_MEDIA,
	Section = Section,
	makeDialogChildren = makeDialogChildren,
	minimalDialogChildren = minimalDialogChildren,
	listDialogChildren = listDialogChildren,
	heroMediaDialogChildren = heroMediaDialogChildren,
	dialogStoryList = dialogStoryList,
	DialogExample = DialogExample,
	LabeledDialogTrigger = LabeledDialogTrigger,
	RootStory = RootStory,
}
