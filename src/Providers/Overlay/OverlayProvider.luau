local Vide = require("../../Packages/Vide")

local Constants = require("../../Constants")
local OverlayContext = require("./OverlayContext")
local StyleSheetContext = require("../Style/StyleSheetContext")
local create = require("../../Utility/create")
local getMainGui = require("../../Utility/getMainGui")
local useKeyboardAwareSize = require("./useKeyboardAwareSize")

export type OverlayProviderProps = {
	-- Overlays render into this instead of a ScreenGui the provider makes. Plugins must pass one.
	gui: GuiBase2d?,
	DisplayOrder: number?,
	children: (() -> any)?,
}

local function OverlayProvider(props: OverlayProviderProps)
	local overlay = Vide.source(props.gui)
	local screen = Vide.source(props.gui)
	--! Calling a nullable source with no arguments is ambiguous to the type checker (centau/vide#71).
	local getOverlay: () -> GuiBase2d? = overlay :: any
	local getScreen: () -> GuiBase2d? = screen :: any
	local mountRequested = Vide.source(false)
	local styleSheet = StyleSheetContext.useStyleSheet()

	--* The ScreenGui is made on first use inside the provider's scope, so it outlives the component that asked.
	Vide.effect(function()
		if props.gui ~= nil or not mountRequested() then
			return
		end
		local mainGui = getMainGui()
		if mainGui == nil then
			return
		end
		Vide.untrack(function()
			local gui = create("ScreenGui")({
				Name = "FoundationOverlay",
				Enabled = true,
				--! The largest DisplayOrder allowed; math.huge overflows.
				DisplayOrder = props.DisplayOrder or Constants.MAX_LAYOUT_ORDER - 1,
				ResetOnSpawn = false,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
				SafeAreaCompatibility = Enum.SafeAreaCompatibility.None,
				ClipToDeviceSafeArea = false,
			})
			local safeAreaSize = useKeyboardAwareSize(gui)
			local frame = create("Frame")({
				Name = "SafeAreaFrame",
				Size = safeAreaSize,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = gui,
			})
			create("StyleLink")({
				Name = "FoundationStyleLink",
				StyleSheet = styleSheet :: () -> StyleSheet,
				Parent = gui,
			})
			gui.Parent = mainGui
			overlay(frame)
			screen(gui)
			Vide.cleanup(gui)
		end)
	end)

	local value: OverlayContext.OverlayContextValue = {
		requestOverlay = function()
			if props.gui == nil and not Vide.untrack(mountRequested) then
				mountRequested(true)
			end
		end,
		instance = getOverlay,
		screen = getScreen,
	}

	return OverlayContext(value, function()
		return if props.children then props.children() else nil
	end)
end

return OverlayProvider
