local Avatar = require("../Avatar")
local AvatarGroupType = require("../../Enums/AvatarGroupType")
local InputSize = require("../../Enums/InputSize")
local InternalAvatarGroup = require("../InternalAvatarGroup")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local Types = require("../Types")
local UserPresence = require("../../Enums/UserPresence")
local Value = require("../../Utility/Value")
local getAvatarSize = require("../Avatar/getAvatarSize")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

type AvatarGroupType = AvatarGroupType.AvatarGroupType
type InputSize = InputSize.InputSize
type UserPresence = UserPresence.UserPresence
type Value<T> = Types.Value<T>

export type AvatarGroupItem = {
	userId: Value<number>,
	userPresence: UserPresence?,
}

export type AvatarGroupProps = {
	type: Value<AvatarGroupType>?,
	max: Value<number>?,
	size: Value<InputSize>?,
	backplateStyle: Types.ColorStyle?,
	avatars: Value<{ AvatarGroupItem | Value<number> }>,
} & Types.CommonProps

local defaultProps = {
	type = AvatarGroupType.Spread,
	max = math.huge,
	size = InputSize.Medium,
	testId = "--foundation-avatar-group",
}

--- A row of Avatars, spread or stacked, with an overflow count after `max`.
local function AvatarGroup(avatarGroupProps: AvatarGroupProps): GuiObject
	local props = withDefaults(avatarGroupProps, defaultProps)
	local tokens = useTokens()
	local isIconSize = PresentationContext.usePresentationContext().isIconSize

	local function size(): InputSize
		return Value.read(props.size)
	end

	return InternalAvatarGroup(withCommonProps(props, {
		type = props.type,
		max = props.max,
		resolvedSize = function()
			return getAvatarSize(tokens(), size() :: any, isIconSize)
		end,
		isEllipsedOverflow = function()
			local current = size()
			return current == InputSize.XSmall or (isIconSize and current == InputSize.Small)
		end,
		gap = function()
			local current = size()
			if Value.read(props.type) == AvatarGroupType.Spread then
				return tokens().Size.Size_200
			elseif isIconSize then
				return if current == InputSize.Large or current == InputSize.Medium
					then -tokens().Size.Size_50
					else -tokens().Size.Size_0
			end
			return if current == InputSize.XSmall then -tokens().Size.Size_50 else -tokens().Size.Size_100
		end,
		backplateStyle = function()
			return Value.read(props.backplateStyle) or tokens().Color.Surface.Surface_0 :: any
		end,
		avatars = props.avatars,
		renderAvatar = function(avatarData, layoutProps)
			local function item(): AvatarGroupItem?
				local data = avatarData()
				return if typeof(data) == "table" then data :: AvatarGroupItem else nil
			end
			return Avatar({
				userId = function()
					local data = item()
					return Value.read(if data then data.userId else avatarData() :: Value<number>)
				end,
				backgroundStyle = layoutProps.backgroundStyle,
				backplateStyle = layoutProps.backplateStyle,
				size = size :: any,
				userPresence = function()
					local data = item()
					return if data then data.userPresence else nil
				end :: any,
				LayoutOrder = layoutProps.LayoutOrder,
				Position = layoutProps.Position,
				ZIndex = layoutProps.ZIndex,
				testId = layoutProps.testId,
			})
		end,
	}) :: any)
end

return AvatarGroup
