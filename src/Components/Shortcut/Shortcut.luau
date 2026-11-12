local Vide = require("../../Packages/Vide")

local Text = require("../Text")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local View = require("../View")

local InputPlatform = require("../../Enums/InputPlatform")
local InputSize = require("../../Enums/InputSize")
local Placement = require("../../Enums/Placement")
local ShortcutSeparator = require("../../Enums/ShortcutSeparator")
local ShortcutVariant = require("../../Enums/ShortcutVariant")

local named = require("../../Utility/named")
local rebuildOn = require("../../Utility/rebuildOn")
local useInputPlatform = require("../../Utility/useInputPlatform")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")
local withDefaults = require("../../Utility/withDefaults")

local KeyCap = require("./KeyCap")
local Separator = require("./Separator")
local keyDisplay = require("./keyDisplay")
local useShortcutVariants = require("./useShortcutVariants")

type InputPlatform = InputPlatform.InputPlatform
type Placement = Placement.Placement
type ShortcutSeparator = ShortcutSeparator.ShortcutSeparator
type ShortcutVariant = ShortcutVariant.ShortcutVariant
type ShortcutVariantProps = useShortcutVariants.ShortcutVariantProps
type Value<T> = Types.Value<T>

export type ShortcutSize = useShortcutVariants.ShortcutSize

export type ShortcutKey = { keyCode: Enum.KeyCode, separator: nil } | { keyCode: nil, separator: ShortcutSeparator }

export type ShortcutProps = {
	-- The keys in order, and the grammar between them
	shortcut: Value<{ ShortcutKey }>,
	-- A label naming what the binding does, drawn beside the caps
	keybinding: Value<string?>?,
	-- Whether the shortcut is start-aligned or end-aligned
	placement: Value<Placement>?,
	-- Matches the size of the row hosting it
	size: Value<ShortcutSize>?,
	-- Standard caps sit on a shift; Contrast caps sit on the system contrast
	variant: Value<ShortcutVariant>?,
} & Types.CommonProps

type KeysState = {
	shortcut: { ShortcutKey },
	platform: InputPlatform,
	variantProps: ShortcutVariantProps,
}

local defaultProps = {
	size = InputSize.XSmall,
	placement = Placement.Start :: Placement,
	variant = ShortcutVariant.Standard,
	testId = "--foundation-shortcut",
}

--- A keyboard or gamepad shortcut drawn as a row of key caps, with an optional label. It does not bind the keys.
local function Shortcut(shortcutProps: ShortcutProps): GuiObject
	local props = withDefaults(shortcutProps, defaultProps)
	local tokens = useTokens()
	local testId = props.testId
	--* Detected once for the whole row, so every cap agrees on the glyph set.
	local platform = useInputPlatform()

	local variantProps = Vide.derive(function()
		return useShortcutVariants(tokens(), Value.read(props.size), Value.read(props.variant))
	end)

	local function isEnd(): boolean
		return Value.read(props.placement) == Placement.End
	end

	local keysState = Vide.derive(function(): KeysState
		return {
			shortcut = Value.read(props.shortcut :: Value<{ ShortcutKey }>),
			platform = platform(),
			variantProps = variantProps(),
		}
	end)

	--* The caps are built again when the keys, the platform or the variant change, as React re-renders them.
	local function buildKeys(state: KeysState): GuiObject
		local items: { GuiObject } = {}
		-- Count keys and separators separately so --key-2 stays the second key.
		local keyCount, separatorCount = 0, 0

		for index, entry in state.shortcut do
			if entry.separator ~= nil then
				separatorCount += 1
				local separator = Separator({
					separator = entry.separator,
					variantProps = state.variantProps,
					LayoutOrder = index,
					testId = `{testId}--separator-{separatorCount}`,
				})
				separator.Name = `Separator{separatorCount}`
				table.insert(items, separator)
			elseif entry.keyCode ~= nil and not keyDisplay.isNonDisplayable(entry.keyCode) then
				keyCount += 1
				local cap = KeyCap({
					keyCode = entry.keyCode,
					platform = state.platform,
					variantProps = state.variantProps,
					LayoutOrder = index,
					testId = `{testId}--key-{keyCount}`,
				})
				if cap then
					cap.Name = `Key{keyCount}`
					table.insert(items, cap)
				end
			end
		end

		return View({
			tag = state.variantProps.keys.tag,
			LayoutOrder = function()
				return if isEnd() then 2 else 1
			end,
			testId = `{testId}--keys`,
			children = items,
		})
	end

	local keybinding = Vide.show(function()
		local text: string? = Value.read(props.keybinding)
		return if text ~= nil and text ~= "" then text else nil
	end, function(text: () -> string)
		local label = Text({
			Text = text,
			tag = function()
				return variantProps().keybinding.tag
			end,
			LayoutOrder = function()
				return if isEnd() then 1 else 2
			end,
			testId = `{testId}--keybinding`,
		})
		label.Name = "Keybinding"
		return label
	end)

	--* Nested so the cap gap stays independent of the label.
	return View(withCommonProps(props, {
		tag = function()
			return variantProps().container.tag
		end,
		layout = {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = function()
				return UDim.new(0, variantProps().container.gap)
			end,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		children = {
			named("Keys", rebuildOn(keysState, buildKeys)),
			keybinding,
		},
	}) :: any)
end

return Shortcut
