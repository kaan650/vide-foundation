local CursorProvider = require("../Cursor/CursorProvider")
local ElevationProvider = require("../Elevation/ElevationProvider").ElevationProvider
local OverlayProvider = require("../Overlay/OverlayProvider")
local PluginProvider = require("../Plugin/PluginProvider")
local PreferencesProvider = require("../Preferences/PreferencesProvider")
local ResponsiveContext = require("../Responsive/ResponsiveContext")
local ResponsiveProvider = require("../Responsive/ResponsiveProvider")
local StyleProvider = require("../Style/StyleProvider")
local Types = require("../../Components/Types")
local Value = require("../../Utility/Value")

type OverlayConfig = Types.OverlayConfig
type StyleProps = StyleProvider.StyleProviderProps
type Preferences = PreferencesProvider.PreferencesProps
type ResponsiveConfig = ResponsiveContext.ResponsiveConfig
type Value<T> = Types.Value<T>

export type FoundationProviderProps = {
	-- Plugins must pass an overlay instance, since they can't use PlayerGui.
	overlayGui: (OverlayConfig | GuiBase2d)?,
	preferences: Value<Preferences?>?,
	responsiveConfig: Value<ResponsiveConfig?>?,
	plugin: Plugin?,
} & StyleProps

--- Sets up styles, overlays, cursors and the other contexts Foundation components read. Mount it at the root of a
--- ScreenGui (or story) and build the UI in `children`, which runs inside the providers. It returns a StyleLink that
--- styles its parent's subtree, so mount it directly under the ScreenGui.
local function FoundationProvider(props: FoundationProviderProps)
	local overlayGui = props.overlayGui
	local overlayConfig: OverlayConfig? = if typeof(overlayGui) == "table" then overlayGui :: OverlayConfig else nil
	local overlayInstance: GuiBase2d? = if typeof(overlayGui) == "Instance" then overlayGui :: GuiBase2d else nil

	--TODO: StudioWidgets and StudioPanels providers for elevated (internal) plugins.
	return PluginProvider({
		plugin = props.plugin,
		children = function()
			return ElevationProvider({
				children = function()
					return PreferencesProvider({
						preferences = props.preferences,
						children = function()
							return StyleProvider({
								themeName = props.themeName,
								colorMode = props.colorMode,
								theme = props.theme,
								device = props.device,
								scale = function()
									local preferences: Preferences? = Value.read(props.preferences)
									return if preferences then preferences.scale else nil
								end,
								tokenOverrides = props.tokenOverrides,
								children = function()
									return ResponsiveProvider({
										config = props.responsiveConfig,
										children = function()
											return OverlayProvider({
												gui = overlayInstance,
												DisplayOrder = if overlayConfig
													then overlayConfig.DisplayOrder
													else nil,
												children = function()
													return CursorProvider({
														children = props.children,
													})
												end,
											})
										end,
									})
								end,
							})
						end,
					})
				end,
			})
		end,
	})
end

return FoundationProvider
