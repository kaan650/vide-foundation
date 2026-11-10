local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Dash = foundation.Dash
local UILabs = foundation.UILabs

local Accessory = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Chip/Accessory")
local AvatarGroupType = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/AvatarGroupType")
local BackgroundStyleContext =
	require("@game/ReplicatedStorage/Packages/VideFoundation/Providers/Style/BackgroundStyleContext")
local ChipSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ChipSize")
local ChipVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ChipVariant")

type Accessory = Accessory.Accessory
type AvatarGroupConfig = Accessory.AvatarGroupConfig
type ChipSize = ChipSize.ChipSize
type ChipVariant = ChipVariant.ChipVariant
type ColorStyleValue = VideFoundation.ColorStyleValue

local IconName = VF.Enums.IconName

--* The order React renders its `Dash.map` over the enums in.
local SIZES: { ChipSize } = { ChipSize.Small, ChipSize.Medium, ChipSize.Large }
local VARIANTS: { ChipVariant } = { ChipVariant.Standard, ChipVariant.Utility }

local function activated(label: string)
	return function()
		print(`Chip: "{label}" activated`)
	end
end

local AVATAR_ACCESSORY: AvatarGroupConfig = {
	type = "AvatarGroup",
	props = {
		avatars = { 24813339 },
		type = AvatarGroupType.Stacked,
		max = 1,
	},
}

local CIRCULAR_ACCESSORY = {
	iconName = IconName.CircleX,
	isCircular = true,
} :: Accessory

local AVATAR_GROUP_ACCESSORY: Accessory = {
	type = "AvatarGroup",
	props = {
		avatars = {
			24813339,
			24813338,
			24813337,
			24813336,
		},
		type = AvatarGroupType.Stacked,
		max = 3,
	},
}

type AccessoryOption = {
	caption: string,
	text: string,
	value: (string | Accessory)?,
}

local ACCESSORY_OPTIONS: { AccessoryOption } = {
	{
		caption = "None",
		text = "None",
	},
	{
		caption = "Icon",
		text = "Icon",
		value = IconName.DiamondSimplified,
	},
	{
		caption = "AvatarAccessory",
		text = "Avatar",
		value = AVATAR_ACCESSORY,
	},
	{
		caption = "CircularAccessory",
		text = "Circular",
		value = CIRCULAR_ACCESSORY,
	},
}

local function Group(props: { caption: string, contentTag: string, LayoutOrder: number?, children: any })
	return VF.View({
		tag = "col gap-medium auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.caption,
				tag = "auto-xy text-body-small content-default",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = props.contentTag,
				LayoutOrder = 2,
				children = props.children,
			}),
		},
	})
end

local function Row(groups: { any })
	return VF.View({
		tag = "row gap-xxlarge auto-xy",
		children = groups,
	})
end

--- An accessory control, with "" standing for no accessory.
local function accessoryControl(control: () -> string | Accessory): () -> (string | Accessory)?
	return function()
		local value = control()
		return if value ~= "" then value else nil
	end
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.Chip({
		text = controls.text,
		onActivated = activated("Playground"),
		leading = accessoryControl(controls.leading),
		trailing = accessoryControl(controls.trailing),
		isChecked = controls.isChecked,
		isDisabled = controls.isDisabled,
		size = controls.size,
		variant = controls.variant,
	})
end

local function SizesStory()
	local groups = {}
	for index, size in SIZES do
		groups[index] = Group({
			caption = size,
			contentTag = "row gap-small auto-xy",
			LayoutOrder = index,
			children = {
				VF.Chip({
					text = "Chip",
					onActivated = activated("Plain"),
					size = size,
					LayoutOrder = 1,
				}),
				VF.Chip({
					text = "Chip",
					onActivated = activated("LeadingIcon"),
					size = size,
					leading = IconName.DiamondSimplified,
					LayoutOrder = 2,
				}),
				VF.Chip({
					text = "Chip",
					onActivated = activated("TrailingIcon"),
					size = size,
					trailing = IconName.ChevronSmallDown,
					LayoutOrder = 3,
				}),
				VF.Chip({
					text = "Chip",
					onActivated = activated("AvatarAndClose"),
					size = size,
					leading = AVATAR_ACCESSORY,
					trailing = CIRCULAR_ACCESSORY,
					LayoutOrder = 4,
				}),
			},
		})
	end

	return VF.View({
		tag = "col gap-xxlarge auto-xy",
		children = groups,
	})
end

local function VariantsStory()
	local groups = {}
	for index, variant in VARIANTS do
		groups[index] = Group({
			caption = variant,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = VF.Chip({
				text = variant,
				onActivated = activated(variant),
				variant = variant,
			}),
		})
	end
	return Row(groups)
end

local function IsCheckedStory()
	local groups = {}
	for index, option in
		{
			{ caption = "False", text = "Unchecked", isChecked = false },
			{ caption = "True", text = "Checked", isChecked = true },
		}
	do
		groups[index] = Group({
			caption = option.caption,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = VF.Chip({
				text = option.text,
				onActivated = activated(option.text),
				isChecked = option.isChecked,
			}),
		})
	end
	return Row(groups)
end

local function IsDisabledStory()
	local groups = {}
	for index, option in
		{
			{ caption = "False", text = "Enabled", isDisabled = false },
			{ caption = "True", text = "Disabled", isDisabled = true },
		}
	do
		groups[index] = Group({
			caption = option.caption,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = VF.Chip({
				text = option.text,
				onActivated = activated(option.text),
				isDisabled = option.isDisabled,
			}),
		})
	end
	return Row(groups)
end

local function AccessoryStory(slot: "leading" | "trailing")
	local groups = {}
	for index, option in ACCESSORY_OPTIONS do
		groups[index] = Group({
			caption = option.caption,
			contentTag = "auto-xy",
			LayoutOrder = index,
			children = VF.Chip({
				text = option.text,
				onActivated = activated(option.text),
				leading = if slot == "leading" then option.value else nil,
				trailing = if slot == "trailing" then option.value else nil,
			}),
		})
	end
	return Row(groups)
end

local function AvatarGroupChip(controls: { [string]: any }, label: string)
	return VF.Chip({
		text = controls.text,
		onActivated = activated(label),
		leading = AVATAR_GROUP_ACCESSORY,
		isChecked = controls.isChecked,
		isDisabled = controls.isDisabled,
		size = controls.size,
		variant = controls.variant,
	})
end

local function AvatarGroupOnCustomBackgroundStory(controls: { [string]: any })
	local tokens = VF.Hooks.useTokens()

	return VF.View({
		tag = "auto-xy padding-large bg-surface-300",
		children = BackgroundStyleContext.context(function(): ColorStyleValue
			return tokens().Color.Surface.Surface_300 :: ColorStyleValue
		end, function()
			return AvatarGroupChip(controls, "AvatarGroup on custom background")
		end),
	})
end

return foundation.sections({
	summary = "Chip",
	controls = {
		leading = UILabs.Choose({
			IconName.ThreeBarsHorizontalNarrowing,
			IconName.Robux,
			IconName.ChevronSmallRight,
			CIRCULAR_ACCESSORY,
			"",
		} :: { string | Accessory }),
		trailing = UILabs.Choose({
			IconName.ChevronLargeDown,
			IconName.CircleX,
			IconName.PlusSmall,
			IconName.X,
			CIRCULAR_ACCESSORY,
			"",
		} :: { string | Accessory }),
		size = UILabs.Choose(Dash.values(ChipSize :: any)),
		variant = UILabs.Choose(Dash.values(ChipVariant :: any)),
		text = "Filter",
		isChecked = false,
		isDisabled = false,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Sizes", story = SizesStory },
		{ name = "Variants", story = VariantsStory },
		{ name = "IsChecked", story = IsCheckedStory },
		{ name = "IsDisabled", story = IsDisabledStory },
		{
			name = "Leading",
			story = function()
				return AccessoryStory("leading")
			end,
		},
		{
			name = "Trailing",
			story = function()
				return AccessoryStory("trailing")
			end,
		},
		{
			name = "AvatarGroup",
			story = function(controls)
				return AvatarGroupChip(controls, "AvatarGroup")
			end,
		},
		{ name = "AvatarGroup on custom background", story = AvatarGroupOnCustomBackgroundStory },
	},
})
