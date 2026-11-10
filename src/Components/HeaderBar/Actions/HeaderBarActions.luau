local Vide = require("../../../Packages/Vide")

local BuilderIcons = require("../../../Packages/BuilderIcons")
local HeaderBarSlot = require("../../../Enums/HeaderBarSlot")
local IconButton = require("../../IconButton")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local constants = require("../constants")
local named = require("../../../Utility/named")
local useHeaderBarContext = require("../useHeaderBarContext")
local useTokens = require("../../../Providers/Style/useTokens")

type Value<T> = Types.Value<T>

export type HeaderBarAction = {
	id: Types.ItemId,
	icon: string | {
		name: string,
		variant: BuilderIcons.IconVariant?,
	},
	onActivated: () -> (),
}

export type HeaderBarActionsProps = {
	actions: Value<{ HeaderBarAction }>,
}

--- A row of IconButtons. In the Leading or Trailing slot it goes first or last and pulls into the bar's padding.
local function HeaderBarActions(props: HeaderBarActionsProps): GuiObject
	local headerBarContext = useHeaderBarContext()
	local tokens = useTokens()
	local testId = headerBarContext.testId

	local layoutOrder: number? = nil
	local padding: Types.PaddingTable? = nil
	if headerBarContext.slot == HeaderBarSlot.Leading then
		layoutOrder = constants.LEADING_ACTIONS_LAYOUT_ORDER
		padding = {
			left = function()
				return UDim.new(0, -tokens().Size.Size_200)
			end,
		} :: Types.PaddingTable
	elseif headerBarContext.slot == HeaderBarSlot.Trailing then
		layoutOrder = constants.TRAILING_ACTIONS_LAYOUT_ORDER
		padding = {
			right = function()
				return UDim.new(0, -tokens().Size.Size_200)
			end,
		} :: Types.PaddingTable
	end

	local function actions(): { HeaderBarAction }
		return Value.read(props.actions)
	end
	local actionsById = Vide.derive(function()
		local byId: { [string]: HeaderBarAction } = {}
		for _, action in actions() do
			byId[tostring(action.id)] = action
		end
		return byId
	end)

	return View({
		tag = "row align-y-center shrink gap-small auto-xy",
		padding = padding,
		LayoutOrder = layoutOrder,
		testId = `{testId}--actions`,
		children = Vide.indexes(actionsById, function(action: () -> HeaderBarAction, id: string)
			return named(
				id,
				IconButton({
					icon = function()
						return action().icon
					end,
					onActivated = function()
						Vide.untrack(action).onActivated()
					end,
					LayoutOrder = function()
						for index, current in actions() do
							if tostring(current.id) == id then
								return index
							end
						end
						return 0
					end,
					testId = `{testId}--actions--{id}`,
				})
			)
		end),
	})
end

return HeaderBarActions
