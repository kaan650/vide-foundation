local BuilderIcons = require("@self/Packages/BuilderIcons")
local StyleSheetRegistry = require("@self/StyleSheet/StyleSheetRegistry")
local Tokens = require("@self/Providers/Style/Tokens")
local Types = require("@self/Components/Types")

export type Value<T> = Types.Value<T>
export type Bindable<T> = Types.Bindable<T>
export type Children = Types.Children
export type ColorStyle = Types.ColorStyle
export type ColorStyleValue = Types.ColorStyleValue
export type CommonProps = Types.CommonProps
export type CornerRadius = Types.CornerRadius
export type FlexItem = Types.FlexItem
export type FontStyle = Types.FontStyle
export type ListLayout = Types.ListLayout
export type Padding = Types.Padding
export type Selection = Types.Selection
export type SelectionGroup = Types.SelectionGroup
export type StateChangedCallback = Types.StateChangedCallback
export type StateLayer = Types.StateLayer
export type Stroke = Types.Stroke
export type Tags = Types.Tags
export type Tokens = Tokens.Tokens
export type TokenOverrides = Tokens.TokenOverrides

local View = require("@self/Components/View")
export type ViewProps = View.ViewProps

local Button = require("@self/Components/Button")
export type ButtonProps = Button.ButtonProps

local Divider = require("@self/Components/Divider")
export type DividerProps = Divider.DividerProps

local Empty = require("@self/Components/Empty")
export type EmptyProps = Empty.EmptyProps

local Grid = require("@self/Components/Grid")
export type GridProps = Grid.GridProps
export type GridCellProps = Grid.GridCellProps
export type GridDebugProps = Grid.GridDebugProps

local Icon = require("@self/Components/Icon")
export type IconProps = Icon.IconProps

local Image = require("@self/Components/Image")
export type ImageProps = Image.ImageProps

local Loading = require("@self/Components/Loading")
export type LoadingProps = Loading.LoadingProps

local ScrollView = require("@self/Components/ScrollView")
export type ScrollViewProps = ScrollView.ScrollViewProps

local Skeleton = require("@self/Components/Skeleton")
export type SkeletonProps = Skeleton.SkeletonProps

local Text = require("@self/Components/Text")
export type TextProps = Text.TextProps

local FoundationProvider = require("@self/Providers/Foundation/FoundationProvider")
export type FoundationProviderProps = FoundationProvider.FoundationProviderProps

return {
	-- Components
	Button = Button,
	Divider = Divider,
	Empty = Empty,
	Grid = Grid,
	Icon = Icon,
	Image = Image,
	Loading = Loading,
	ScrollView = ScrollView,
	Skeleton = Skeleton,
	Text = Text,
	View = View,

	-- Providers
	FoundationProvider = FoundationProvider,
	OverlayProvider = require("@self/Providers/Overlay/OverlayProvider"),
	ResponsiveProvider = require("@self/Providers/Responsive/ResponsiveProvider"),
	BackgroundStyleContext = require("@self/Providers/Style/BackgroundStyleContext"),

	-- Hooks: call them while a component is being created, under FoundationProvider.
	Hooks = {
		useBreakpoint = require("@self/Providers/Responsive/Hooks/useBreakpoint"),
		usePulseBinding = require("@self/Utility/usePulseBinding"),
		useCursor = require("@self/Providers/Cursor/useCursor"),
		useOverlay = require("@self/Providers/Overlay/useOverlay"),
		usePreferences = require("@self/Providers/Preferences/usePreferences"),
		useResponsive = require("@self/Providers/Responsive/useResponsive"),
		useStyleSheet = require("@self/Providers/Style/StyleSheetContext").useStyleSheet,
		useTextSizeOffset = require("@self/Providers/Style/useTextSizeOffset"),
		useTokens = require("@self/Providers/Style/useTokens"),
	},

	-- Foundation style tags for any instance, as a Vide action: `create "Frame" { tags("bg-surface-100") }`.
	tags = require("@self/Utility/tags"),

	Enums = {
		AccessoryType = require("@self/Enums/AccessoryType"),
		AlertSeverity = require("@self/Enums/AlertSeverity"),
		AlertVariant = require("@self/Enums/AlertVariant"),
		AvatarGroupType = require("@self/Enums/AvatarGroupType"),
		AvatarIconSize = require("@self/Enums/AvatarIconSize"),
		AvatarSize = require("@self/Enums/AvatarSize"),
		BadgeShape = require("@self/Enums/BadgeShape"),
		BadgeSize = require("@self/Enums/BadgeSize"),
		BadgeVariant = require("@self/Enums/BadgeVariant"),
		Breakpoint = require("@self/Enums/Breakpoint"),
		-- **DEPRECATED**: ButtonSize is deprecated. Use InputSize instead.
		ButtonSize = require("@self/Enums/InputSize"),
		ButtonVariant = require("@self/Enums/ButtonVariant"),
		-- **DEPRECATED**: CheckboxSize is deprecated. Use InputSize instead.
		CheckboxSize = require("@self/Enums/InputSize"),
		ControlState = require("@self/Enums/ControlState"),
		ChipGroupVariant = require("@self/Enums/ChipGroupVariant"),
		ChipSize = require("@self/Enums/ChipSize"),
		ChipVariant = require("@self/Enums/ChipVariant"),
		ColorMode = require("@self/Enums/ColorMode"),
		CursorType = require("@self/Enums/CursorType"),
		DateTimePickerVariant = require("@self/Enums/DateTimePickerVariant"),
		Device = require("@self/Enums/Device"),
		DialogSize = require("@self/Enums/DialogSize"),
		-- **DEPRECATED**: DividerOrientation is deprecated. Use Orientation instead.
		DividerOrientation = require("@self/Enums/Orientation"),
		DividerVariant = require("@self/Enums/DividerVariant"),
		FillBehavior = require("@self/Enums/FillBehavior"),
		FontName = require("@self/Enums/FontName"),
		IconName = BuilderIcons.Icon,
		IconPosition = require("@self/Enums/IconPosition"),
		IconSize = require("@self/Enums/IconSize"),
		IconVariant = BuilderIcons.IconVariant,
		InputFocusBehavior = require("@self/Enums/InputFocusBehavior"),
		InputSize = require("@self/Enums/InputSize"),
		InputVariant = require("@self/Enums/InputVariant"),
		InputPlacement = require("@self/Enums/InputPlacement"),
		InputLabelSize = require("@self/Enums/InputLabelSize"),
		ListItemInputType = require("@self/Enums/ListItemInputType"),
		NumberInputControlsVariant = require("@self/Enums/NumberInputControlsVariant"),
		ScrubBehavior = require("@self/Enums/ScrubBehavior"),
		OnChangeCallbackReason = require("@self/Enums/OnChangeCallbackReason"),
		OnCloseCallbackReason = require("@self/Enums/OnCloseCallbackReason"),
		OptionSelectorGroupSize = require("@self/Enums/OptionSelectorGroupSize"),
		Orientation = require("@self/Enums/Orientation"),
		PaginationSize = require("@self/Enums/PaginationSize"),
		PaginationVariant = require("@self/Enums/PaginationVariant"),
		PopoverAlign = require("@self/Enums/PopoverAlign"),
		PopoverSide = require("@self/Enums/PopoverSide"),
		ProgressShape = require("@self/Enums/ProgressShape"),
		ProgressSize = require("@self/Enums/ProgressSize"),
		RatingValue = require("@self/Enums/RatingValue"),
		Radius = require("@self/Enums/Radius"),
		SearchInputShape = require("@self/Enums/SearchInputShape"),
		SegmentedControlVariant = require("@self/Enums/SegmentedControlVariant"),
		-- **DEPRECATED**: ScrollBarVisibility is deprecated. Use Visibility instead.
		ScrollBarVisibility = require("@self/Enums/Visibility"),
		SliderVariant = require("@self/Enums/SliderVariant"),
		StateLayerAffordance = require("@self/Enums/StateLayerAffordance"),
		StateLayerMode = require("@self/Enums/StateLayerMode"),
		StatusBadgeShape = require("@self/Enums/StatusBadgeShape"),
		StatusBadgeSize = require("@self/Enums/StatusBadgeSize"),
		StatusBadgeVariant = require("@self/Enums/StatusBadgeVariant"),
		StatusIndicatorShape = require("@self/Enums/StatusIndicatorShape"),
		StatusIndicatorSize = require("@self/Enums/StatusIndicatorSize"),
		StatusIndicatorVariant = require("@self/Enums/StatusIndicatorVariant"),
		-- **DEPRECATED**: Theme is deprecated. Use ColorMode instead.
		Theme = require("@self/Enums/Theme"),
		ThemeName = require("@self/Enums/ThemeName"),
		ThumbnailType = require("@self/Enums/ThumbnailType"),
		ThumbnailSize = require("@self/Enums/ThumbnailSize"),
		-- **DEPRECATED**: ToggleSize is deprecated. Use InputSize instead.
		ToggleSize = require("@self/Enums/InputSize"),
		UserPresence = require("@self/Enums/UserPresence"),
		Visibility = require("@self/Enums/Visibility"),
	},

	Utility = {
		getStyleSheet = StyleSheetRegistry.getStyleSheet,
		addStyleTags = StyleSheetRegistry.addStyleTags,
		releaseStyleSheet = StyleSheetRegistry.releaseStyleSheet,
		getTokens = Tokens.getTokens,
		getGridMetrics = require("@self/Utility/getGridMetrics"),
		blendColors = require("@self/Utility/blendColors"),
		withCommonProps = require("@self/Utility/withCommonProps"),
		withDefaults = require("@self/Utility/withDefaults"),
	},

	UNSTABLE = {
		Interactable = require("@self/Components/Interactable"),
	},
}
