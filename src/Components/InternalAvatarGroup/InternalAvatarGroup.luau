local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")

local ColorNamespace = require("../../Enums/ColorNamespace")
local Icon = require("../Icon")
local IconSize = require("../../Enums/IconSize")
local PresentationContext = require("../../Providers/Style/PresentationContext")
local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")
local getBindableValue = require("../../Utility/getBindableValue")
local useCumulativeBackground = require("../../Utility/useCumulativeBackground")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local AvatarGroupType = require("../../Enums/AvatarGroupType")
type AvatarGroupType = AvatarGroupType.AvatarGroupType
local UserPresence = require("../../Enums/UserPresence")
type UserPresence = UserPresence.UserPresence

type ColorStyle = Types.ColorStyle
type ColorStyleValue = Types.ColorStyleValue
type Value<T> = Types.Value<T>

type AvatarTable = { userId: Value<number>, userPresence: UserPresence? }
export type AvatarData = AvatarTable | Value<number>

export type LayoutProps = {
	-- The avatar's key in the group; the group names the rendered instance after it.
	key: string,
	LayoutOrder: () -> number,
	Position: () -> UDim2,
	ZIndex: () -> number,
	testId: string,
	backgroundStyle: () -> ColorStyleValue,
	backplateStyle: () -> ColorStyleValue,
}

--- Renders one avatar of the group. The data is a source, because the group keeps an avatar while its key stays
--- and passes it the item's current data.
export type AvatarGroupRender = (avatarData: () -> AvatarData, layoutProps: LayoutProps) -> GuiObject

export type InternalAvatarGroupProps = {
	type: Value<AvatarGroupType>?,
	-- Avatars after `max` collapse into one overflow count.
	max: Value<number>?,
	resolvedSize: Value<number>,
	gap: Value<number>,
	isEllipsedOverflow: Value<boolean>?,
	backplateStyle: ColorStyle?,
	avatars: Value<{ AvatarData }>,
	renderAvatar: AvatarGroupRender,
} & Types.CommonProps

local defaultProps = {
	type = AvatarGroupType.Spread,
	isEllipsedOverflow = false,
	max = math.huge,
	testId = "--foundation-avatar-group",
}

local OVERFLOW_KEY = "overflow"

type Entry = {
	key: string,
	data: AvatarData,
	index: number,
}

type GroupLayout = {
	keys: { string },
	entries: { [string]: Entry },
	total: number,
	overflowCount: number,
}

local function getStableId(avatarData: AvatarData): string
	local userId: Value<number> = if type(avatarData) == "table" then (avatarData :: AvatarTable).userId else avatarData
	return tostring(getBindableValue(userId))
end

local function getGroupLayout(avatars: { AvatarData }, max: number): GroupLayout
	local layout: GroupLayout = { keys = {}, entries = {}, total = #avatars, overflowCount = 0 }
	for index, avatarData in avatars do
		if index > max then
			table.insert(layout.keys, OVERFLOW_KEY)
			layout.entries[OVERFLOW_KEY] = { key = OVERFLOW_KEY, data = avatarData, index = index }
			layout.overflowCount = #avatars - max
			break
		end
		local stableId = getStableId(avatarData)
		--* Vide needs unique values where React would only warn about a duplicate key.
		local unique = stableId
		local copy = 1
		while layout.entries[unique] do
			copy += 1
			unique = `{stableId}#{copy}`
		end
		table.insert(layout.keys, unique)
		layout.entries[unique] = { key = stableId, data = avatarData, index = index }
	end
	return layout
end

type AvatarOverflowProps = {
	count: () -> number,
	isEllipsed: () -> boolean,
	Size: () -> UDim2,
	LayoutOrder: () -> number,
	Position: () -> UDim2,
	ZIndex: () -> number,
	backgroundStyle: ColorStyle,
	backplateStyle: ColorStyle,
	testId: string,
}

local function AvatarOverflow(props: AvatarOverflowProps): GuiObject
	local tokens = useTokens()
	local presentationContext = PresentationContext.usePresentationContext()
	local backgroundStyle = useCumulativeBackground(props.backplateStyle, props.backgroundStyle)

	local function contentStyle(): ColorStyleValue
		return (tokens() :: any)[presentationContext.colorNamespace or ColorNamespace.Color].Content.Emphasis
	end

	local content = Vide.switch(props.isEllipsed)({
		[true] = function()
			local icon = Icon({
				name = BuilderIcons.Icon.ThreeDotsHorizontal,
				size = IconSize.XSmall,
				style = contentStyle,
				testId = `{props.testId}--ellipses`,
			})
			icon.Name = "Children"
			return icon
		end,
		[false] = function()
			local label = Text({
				Text = function()
					return `+{props.count()}`
				end,
				tag = "auto-xy text-align-x-center text-caption-medium",
				textStyle = contentStyle,
				testId = `{props.testId}--text`,
			})
			label.Name = "Children"
			return label
		end,
	})

	return View({
		Size = props.Size,
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		ZIndex = props.ZIndex,
		backgroundStyle = backgroundStyle,
		tag = "row align-x-center align-y-center radius-circle",
		testId = props.testId,
		children = content,
	})
end

--- Lays avatars out in a row, spread or stacked by `gap`, with an overflow count after `max`.
local function InternalAvatarGroup(internalAvatarGroupProps: InternalAvatarGroupProps): GuiObject
	local props = withDefaults(internalAvatarGroupProps, defaultProps)
	local tokens = useTokens()
	local presentationContext = PresentationContext.usePresentationContext()

	local function backgroundStyle(): ColorStyleValue
		return (tokens() :: any)[presentationContext.colorNamespace or ColorNamespace.Color].Shift.Shift_300
	end
	local function backplateStyle(): ColorStyleValue
		return Value.read(props.backplateStyle) or tokens().Color.Surface.Surface_0 :: ColorStyleValue
	end
	local function size(): number
		return Value.read(props.resolvedSize)
	end

	local groupLayout = Vide.derive(function()
		return getGroupLayout(Value.read(props.avatars), Value.read(props.max))
	end)

	local children = Vide.values(function()
		return groupLayout().keys
	end, function(uniqueKey: string)
		--! Effects can run once after the key is gone, before values() removes the item, so it keeps its last entry.
		local last = Vide.untrack(groupLayout).entries[uniqueKey]
		local function entry(): Entry
			local current = groupLayout().entries[uniqueKey]
			if current then
				last = current
			end
			return last
		end
		local function layoutOrder(): number
			return entry().index
		end
		local function position(): UDim2
			return UDim2.fromOffset((size() + Value.read(props.gap)) * (entry().index - 1), 0)
		end
		local function zIndex(): number
			return groupLayout().total - (entry().index - 1)
		end

		if uniqueKey == OVERFLOW_KEY then
			local overflow = AvatarOverflow({
				count = function()
					return groupLayout().overflowCount
				end,
				isEllipsed = function()
					return Value.read(props.isEllipsedOverflow) == true
				end,
				Size = function()
					return UDim2.fromOffset(size(), size())
				end,
				LayoutOrder = layoutOrder,
				Position = position,
				ZIndex = zIndex,
				backgroundStyle = backgroundStyle,
				backplateStyle = backplateStyle,
				testId = `{props.testId}--avatar-overflow`,
			})
			overflow.Name = OVERFLOW_KEY
			return overflow
		end

		local key = last.key
		local avatar = props.renderAvatar(function()
			return entry().data
		end, {
			key = key,
			LayoutOrder = layoutOrder,
			Position = position,
			ZIndex = zIndex,
			testId = `{props.testId}--avatar-{key}`,
			backgroundStyle = backgroundStyle,
			backplateStyle = backplateStyle,
		})
		avatar.Name = key
		return avatar
	end)

	return View(withCommonProps(props, {
		tag = "auto-xy",
		children = children,
	}) :: any)
end

return InternalAvatarGroup
