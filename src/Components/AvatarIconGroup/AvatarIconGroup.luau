local AvatarGroupType = require("../../Enums/AvatarGroupType")
local AvatarIcon = require("../AvatarIcon")
local AvatarIconSize = require("../../Enums/AvatarIconSize")
local InternalAvatarGroup = require("../InternalAvatarGroup")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local useAvatarIconVariants = require("../AvatarIcon/useAvatarIconVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type AvatarGroupType = AvatarGroupType.AvatarGroupType
type AvatarIconSize = AvatarIconSize.AvatarIconSize
type Value<T> = Types.Value<T>

export type AvatarIconGroupProps = {
	type: Value<AvatarGroupType>?,
	max: Value<number>?,
	size: Value<AvatarIconSize>?,
	backplateStyle: Types.ColorStyle?,
	avatars: Value<{ Value<number> }>,
} & Types.CommonProps

local defaultProps = {
	type = AvatarGroupType.Spread,
	max = math.huge,
	size = AvatarIconSize.Medium,
	testId = "--foundation-avatar-icon-group",
}

--- A row of AvatarIcons, spread or stacked, with an ellipsis after `max`.
local function AvatarIconGroup(avatarIconGroupProps: AvatarIconGroupProps): GuiObject
	local props = withDefaults(avatarIconGroupProps, defaultProps)
	local tokens = useTokens()

	local function size(): AvatarIconSize
		return Value.read(props.size)
	end

	return InternalAvatarGroup(withCommonProps(props, {
		type = props.type,
		max = props.max,
		resolvedSize = function()
			return useAvatarIconVariants(tokens(), size()).container.size
		end,
		gap = function()
			if Value.read(props.type) == AvatarGroupType.Spread then
				return tokens().Size.Size_200
			end
			local current = size()
			return if current == AvatarIconSize.Large or current == AvatarIconSize.Medium
				then -tokens().Size.Size_50
				else -tokens().Size.Size_0
		end,
		isEllipsedOverflow = true,
		backplateStyle = props.backplateStyle,
		avatars = props.avatars,
		renderAvatar = function(avatarData, layoutProps)
			return AvatarIcon({
				userId = function()
					return Value.read(avatarData() :: Value<number>)
				end,
				backgroundStyle = layoutProps.backgroundStyle,
				backplateStyle = layoutProps.backplateStyle,
				size = size,
				LayoutOrder = layoutProps.LayoutOrder,
				Position = layoutProps.Position,
				ZIndex = layoutProps.ZIndex,
				testId = layoutProps.testId,
			})
		end,
	}) :: any)
end

return AvatarIconGroup
