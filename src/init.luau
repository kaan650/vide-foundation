local BuilderIcons = require("@self/Packages/BuilderIcons")
local StyleSheetRegistry = require("@self/StyleSheet/StyleSheetRegistry")
local Tokens = require("@self/Providers/Style/Tokens")
local TextArea = require("@self/Components/TextArea")
export type TextAreaProps = TextArea.TextAreaProps

local TextInput = require("@self/Components/TextInput")
export type TextInputProps = TextInput.TextInputProps
export type TextInputTrailingIcon = TextInput.TextInputTrailingIcon

local Toast = require("@self/Components/Toast")
export type ToastProps = Toast.ToastProps

local Toggle = require("@self/Components/Toggle")
export type ToggleProps = Toggle.ToggleProps

local ToggleGroup = require("@self/Components/ToggleGroup")
export type ToggleGroupProps = ToggleGroup.ToggleGroupProps

local Tooltip = require("@self/Components/Tooltip")
export type TooltipProps = Tooltip.TooltipProps

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
export type ActionProps = Types.ActionProps
export type AspectRatio = Types.AspectRatio
export type TextInputRef = Types.TextInputRef
export type Tokens = Tokens.Tokens
export type TokenOverrides = Tokens.TokenOverrides

-- Enum types, as Foundation exports them
local AccessoryType = require("@self/Enums/AccessoryType")
export type AccessoryType = AccessoryType.AccessoryType
local AlertSeverity = require("@self/Enums/AlertSeverity")
export type AlertSeverity = AlertSeverity.AlertSeverity
local AlertVariant = require("@self/Enums/AlertVariant")
export type AlertVariant = AlertVariant.AlertVariant
local AvatarGroupType = require("@self/Enums/AvatarGroupType")
export type AvatarGroupType = AvatarGroupType.AvatarGroupType
local AvatarIconSize = require("@self/Enums/AvatarIconSize")
export type AvatarIconSize = AvatarIconSize.AvatarIconSize
local AvatarSize = require("@self/Enums/AvatarSize")
export type AvatarSize = AvatarSize.AvatarSize
local BadgeShape = require("@self/Enums/BadgeShape")
export type BadgeShape = BadgeShape.BadgeShape
local BadgeSize = require("@self/Enums/BadgeSize")
export type BadgeSize = BadgeSize.BadgeSize
local BadgeVariant = require("@self/Enums/BadgeVariant")
export type BadgeVariant = BadgeVariant.BadgeVariant
local Breakpoint = require("@self/Enums/Breakpoint")
export type Breakpoint = Breakpoint.Breakpoint
local ButtonVariant = require("@self/Enums/ButtonVariant")
export type ButtonVariant = ButtonVariant.ButtonVariant
local ChipGroupVariant = require("@self/Enums/ChipGroupVariant")
export type ChipGroupVariant = ChipGroupVariant.ChipGroupVariant
local ChipSize = require("@self/Enums/ChipSize")
export type ChipSize = ChipSize.ChipSize
local ChipVariant = require("@self/Enums/ChipVariant")
export type ChipVariant = ChipVariant.ChipVariant
local ColorMode = require("@self/Enums/ColorMode")
export type ColorMode = ColorMode.ColorMode
local ControlState = require("@self/Enums/ControlState")
export type ControlState = ControlState.ControlState
local CursorType = require("@self/Enums/CursorType")
export type CursorType = CursorType.CursorType
local DateTimePickerVariant = require("@self/Enums/DateTimePickerVariant")
export type DateTimePickerVariant = DateTimePickerVariant.DateTimePickerVariant
local Device = require("@self/Enums/Device")
export type Device = Device.Device
local DialogSize = require("@self/Enums/DialogSize")
export type DialogSize = DialogSize.DialogSize
local DividerVariant = require("@self/Enums/DividerVariant")
export type DividerVariant = DividerVariant.DividerVariant
local FillBehavior = require("@self/Enums/FillBehavior")
export type FillBehavior = FillBehavior.FillBehavior
local FontName = require("@self/Enums/FontName")
export type FontName = FontName.FontName
local IconPosition = require("@self/Enums/IconPosition")
export type IconPosition = IconPosition.IconPosition
local IconSize = require("@self/Enums/IconSize")
export type IconSize = IconSize.IconSize
local InputFocusBehavior = require("@self/Enums/InputFocusBehavior")
export type InputFocusBehavior = InputFocusBehavior.InputFocusBehavior
local InputLabelSize = require("@self/Enums/InputLabelSize")
export type InputLabelSize = InputLabelSize.InputLabelSize
local InputPlacement = require("@self/Enums/InputPlacement")
export type InputPlacement = InputPlacement.InputPlacement
local InputSize = require("@self/Enums/InputSize")
export type InputSize = InputSize.InputSize
local InputVariant = require("@self/Enums/InputVariant")
export type InputVariant = InputVariant.InputVariant
local ListItemInputType = require("@self/Enums/ListItemInputType")
export type ListItemInputType = ListItemInputType.ListItemInputType
local NumberInputControlsVariant = require("@self/Enums/NumberInputControlsVariant")
export type NumberInputControlsVariant = NumberInputControlsVariant.NumberInputControlsVariant
local ScrubBehavior = require("@self/Enums/ScrubBehavior")
export type ScrubBehavior = ScrubBehavior.ScrubBehavior
local OnChangeCallbackReason = require("@self/Enums/OnChangeCallbackReason")
export type OnChangeCallbackReason = OnChangeCallbackReason.OnChangeCallbackReason
local OnCloseCallbackReason = require("@self/Enums/OnCloseCallbackReason")
export type OnCloseCallbackReason = OnCloseCallbackReason.OnCloseCallbackReason
local OptionSelectorGroupSize = require("@self/Enums/OptionSelectorGroupSize")
export type OptionSelectorGroupSize = OptionSelectorGroupSize.OptionSelectorGroupSize
local Orientation = require("@self/Enums/Orientation")
export type Orientation = Orientation.Orientation
local PaginationSize = require("@self/Enums/PaginationSize")
export type PaginationSize = PaginationSize.PaginationSize
local PaginationVariant = require("@self/Enums/PaginationVariant")
export type PaginationVariant = PaginationVariant.PaginationVariant
local PopoverAlign = require("@self/Enums/PopoverAlign")
export type PopoverAlign = PopoverAlign.PopoverAlign
local PopoverSide = require("@self/Enums/PopoverSide")
export type PopoverSide = PopoverSide.PopoverSide
local ProgressShape = require("@self/Enums/ProgressShape")
export type ProgressShape = ProgressShape.ProgressShape
local ProgressSize = require("@self/Enums/ProgressSize")
export type ProgressSize = ProgressSize.ProgressSize
local RatingValue = require("@self/Enums/RatingValue")
export type RatingValue = RatingValue.RatingValue
local Radius = require("@self/Enums/Radius")
export type Radius = Radius.Radius
local SearchInputShape = require("@self/Enums/SearchInputShape")
export type SearchInputShape = SearchInputShape.SearchInputShape
local SegmentedControlVariant = require("@self/Enums/SegmentedControlVariant")
export type SegmentedControlVariant = SegmentedControlVariant.SegmentedControlVariant
local SliderVariant = require("@self/Enums/SliderVariant")
export type SliderVariant = SliderVariant.SliderVariant
local StateLayerAffordance = require("@self/Enums/StateLayerAffordance")
export type StateLayerAffordance = StateLayerAffordance.StateLayerAffordance
local StateLayerMode = require("@self/Enums/StateLayerMode")
export type StateLayerMode = StateLayerMode.StateLayerMode
local StatusBadgeShape = require("@self/Enums/StatusBadgeShape")
export type StatusBadgeShape = StatusBadgeShape.StatusBadgeShape
local StatusBadgeSize = require("@self/Enums/StatusBadgeSize")
export type StatusBadgeSize = StatusBadgeSize.StatusBadgeSize
local StatusBadgeVariant = require("@self/Enums/StatusBadgeVariant")
export type StatusBadgeVariant = StatusBadgeVariant.StatusBadgeVariant
local StatusIndicatorShape = require("@self/Enums/StatusIndicatorShape")
export type StatusIndicatorShape = StatusIndicatorShape.StatusIndicatorShape
local StatusIndicatorSize = require("@self/Enums/StatusIndicatorSize")
export type StatusIndicatorSize = StatusIndicatorSize.StatusIndicatorSize
local StatusIndicatorVariant = require("@self/Enums/StatusIndicatorVariant")
export type StatusIndicatorVariant = StatusIndicatorVariant.StatusIndicatorVariant
local Theme = require("@self/Enums/Theme")
export type Theme = Theme.Theme
local ThemeName = require("@self/Enums/ThemeName")
export type ThemeName = ThemeName.ThemeName
local ThumbnailSize = require("@self/Enums/ThumbnailSize")
export type ThumbnailSize = ThumbnailSize.ThumbnailSize
local ThumbnailType = require("@self/Enums/ThumbnailType")
export type ThumbnailType = ThumbnailType.ThumbnailType
local UserPresence = require("@self/Enums/UserPresence")
export type UserPresence = UserPresence.UserPresence
local Visibility = require("@self/Enums/Visibility")
export type Visibility = Visibility.Visibility
export type IconName = BuilderIcons.Icon
export type IconVariant = BuilderIcons.IconVariant

local AlertActions = require("@self/Components/AlertActions")
export type AlertAction = AlertActions.AlertAction

local PreferencesProvider = require("@self/Providers/Preferences/PreferencesProvider")
export type Preferences = PreferencesProvider.PreferencesProps
export type PreferencesProviderProps = PreferencesProvider.PreferencesProviderProps

local ResponsiveProvider = require("@self/Providers/Responsive/ResponsiveProvider")
export type ResponsiveProviderProps = ResponsiveProvider.ResponsiveProviderProps

local View = require("@self/Components/View")
export type ViewProps = View.ViewProps

local Accordion = require("@self/Components/Accordion")
export type AccordionProps = Accordion.AccordionProps
export type AccordionItemProps = Accordion.AccordionItemProps

local Alert = require("@self/Components/Alert")
export type AlertProps = Alert.AlertProps

local Avatar = require("@self/Components/Avatar")
export type AvatarProps = Avatar.AvatarProps

local AvatarGroup = require("@self/Components/AvatarGroup")
export type AvatarGroupProps = AvatarGroup.AvatarGroupProps
export type AvatarGroupItem = AvatarGroup.AvatarGroupItem

local AvatarIcon = require("@self/Components/AvatarIcon")
export type AvatarIconProps = AvatarIcon.AvatarIconProps

local AvatarIconGroup = require("@self/Components/AvatarIconGroup")
export type AvatarIconGroupProps = AvatarIconGroup.AvatarIconGroupProps

local Badge = require("@self/Components/Badge")
export type BadgeProps = Badge.BadgeProps
export type BadgeIcon = Badge.BadgeIcon

local BaseMenu = require("@self/Components/BaseMenu")
export type BaseMenuProps<Item = BaseMenuItem> = BaseMenu.BaseMenuProps<Item>
export type BaseMenuItem = BaseMenu.BaseMenuItem
export type BaseMenuItems<Item = BaseMenuItem> = BaseMenu.BaseMenuItems<Item>
export type BaseMenuItemGroup<Item = BaseMenuItem> = BaseMenu.BaseMenuItemGroup<Item>

local Button = require("@self/Components/Button")
export type ButtonProps = Button.ButtonProps

local ButtonGroup = require("@self/Components/ButtonGroup")
export type ButtonGroupProps = ButtonGroup.ButtonGroupProps
export type ButtonGroupItem = ButtonGroup.ButtonGroupItem
export type ButtonGroupSize = ButtonGroup.ButtonGroupSize

local Checkbox = require("@self/Components/Checkbox")
export type CheckboxProps = Checkbox.CheckboxProps

local CheckboxGroup = require("@self/Components/CheckboxGroup")
export type CheckboxGroupProps = CheckboxGroup.CheckboxGroupProps

local Chip = require("@self/Components/Chip")
export type ChipProps = Chip.ChipProps

local ChipGroup = require("@self/Components/ChipGroup")
export type ChipGroupProps = ChipGroup.ChipGroupProps
export type ChipGroupItem = ChipGroup.ChipGroupItem

local Coachmark = require("@self/Components/Coachmark")
export type CoachmarkProps = Coachmark.CoachmarkProps
export type CoachmarkSteps = Coachmark.CoachmarkSteps

local ColorPicker = require("@self/Components/ColorPicker")
export type ColorPickerProps = ColorPicker.ColorPickerProps

local DateTimePicker = require("@self/Components/DateTimePicker")
export type DateTimePickerProps = DateTimePicker.DateTimePickerProps

local Dialog = require("@self/Components/Dialog")
export type DialogProps = Dialog.DialogProps
export type DialogActionsProps = Dialog.DialogActionsProps
export type DialogContentProps = Dialog.DialogContentProps
export type DialogTextProps = Dialog.DialogTextProps
export type DialogHeroMediaProps = Dialog.DialogHeroMediaProps
export type DialogTitleProps = Dialog.DialogTitleProps

local Divider = require("@self/Components/Divider")
export type DividerProps = Divider.DividerProps

local Dropdown = require("@self/Components/Dropdown")
export type DropdownProps = Dropdown.DropdownProps
export type DropdownItem = Dropdown.DropdownItem
export type DropdownItems = Dropdown.DropdownItems

local EducationalTooltip = require("@self/Components/EducationalTooltip")
export type EducationalTooltipProps = EducationalTooltip.EducationalTooltipProps

local Empty = require("@self/Components/Empty")
export type EmptyProps = Empty.EmptyProps

local FeedbackAlert = require("@self/Components/FeedbackAlert")
export type FeedbackAlertProps = FeedbackAlert.FeedbackAlertProps

local Grid = require("@self/Components/Grid")
export type GridProps = Grid.GridProps
export type GridCellProps = Grid.GridCellProps
export type GridDebugProps = Grid.GridDebugProps

local HeaderBar = require("@self/Components/HeaderBar")
export type HeaderBarAction = HeaderBar.HeaderBarAction
export type HeaderBarActionsProps = HeaderBar.HeaderBarActionsProps
export type HeaderBarContentProps = HeaderBar.HeaderBarContentProps
export type HeaderBarLeadingProps = HeaderBar.HeaderBarLeadingProps
export type HeaderBarProps = HeaderBar.HeaderBarProps
export type HeaderBarTrailingProps = HeaderBar.HeaderBarTrailingProps

local Icon = require("@self/Components/Icon")
export type IconProps = Icon.IconProps

local IconButton = require("@self/Components/IconButton")
export type IconButtonProps = IconButton.IconButtonProps

local Image = require("@self/Components/Image")
export type ImageProps = Image.ImageProps

local InputChip = require("@self/Components/InputChip")
export type InputChipProps = InputChip.InputChipProps

local InputLabel = require("@self/Components/InputLabel")
export type InputLabelProps = InputLabel.InputLabelProps

local KeyLabel = require("@self/Components/KeyLabel")
export type KeyLabelProps = KeyLabel.KeyLabelProps

local Knob = require("@self/Components/Knob")
export type KnobProps = Knob.KnobProps

local List = require("@self/Components/List")
export type ListProps = List.ListProps
export type ListAccessoryProps = List.ListAccessoryProps
export type ListItemProps = List.ListItemProps

local Loading = require("@self/Components/Loading")
export type LoadingProps = Loading.LoadingProps

local Menu = require("@self/Components/Menu")
export type MenuProps = Menu.MenuProps
export type MenuItem = Menu.MenuItem
export type MenuItems = Menu.MenuItems

local NumberInput = require("@self/Components/NumberInput")
export type NumberInputProps = NumberInput.NumberInputProps

local OptionSelectorGroup = require("@self/Components/OptionSelectorGroup")
export type OptionSelectorGroupProps = OptionSelectorGroup.OptionSelectorGroupProps
export type OptionSelectorGroupItemProps = OptionSelectorGroup.OptionSelectorGroupItemProps

local Pagination = require("@self/Components/Pagination")
export type PaginationProps = Pagination.PaginationProps

local Popover = require("@self/Components/Popover")
export type PopoverProps = Popover.PopoverProps
export type PopoverAnchorProps = Popover.PopoverAnchorProps
export type PopoverContentProps = Popover.PopoverContentProps
export type PopoverAnchor = Types.PopoverAnchor

local Progress = require("@self/Components/Progress")
export type ProgressProps = Progress.ProgressProps

local RadioGroup = require("@self/Components/RadioGroup")
export type RadioGroupProps = RadioGroup.RadioGroupProps
export type RadioGroupItemProps = RadioGroup.RadioGroupItemProps

local Rating = require("@self/Components/Rating")
export type RatingProps = Rating.RatingProps

local ScrollView = require("@self/Components/ScrollView")
export type ScrollViewProps = ScrollView.ScrollViewProps

local SearchInput = require("@self/Components/SearchInput")
export type SearchInputProps = SearchInput.SearchInputProps

local SegmentedControl = require("@self/Components/SegmentedControl")
export type SegmentedControlProps = SegmentedControl.SegmentedControlProps

local Sheet = require("@self/Components/Sheet")
export type SheetProps = Sheet.SheetProps
export type SheetRef = Sheet.SheetRef
export type SheetActionsProps = Sheet.SheetActionsProps
export type SheetContentProps = Sheet.SheetContentProps
export type SheetFullBleedProps = Sheet.SheetFullBleedProps
export type SheetHeaderProps = Sheet.SheetHeaderProps

local Skeleton = require("@self/Components/Skeleton")
export type SkeletonProps = Skeleton.SkeletonProps

local Slider = require("@self/Components/Slider")
export type SliderProps = Slider.SliderProps

local Snackbar = require("@self/Components/Snackbar")
export type SnackbarProps = Snackbar.SnackbarProps
export type SnackbarAction = Snackbar.SnackbarAction

local StatusBadge = require("@self/Components/StatusBadge")
export type StatusBadgeProps = StatusBadge.StatusBadgeProps

local StatusIndicator = require("@self/Components/StatusIndicator")
export type StatusIndicatorProps = StatusIndicator.StatusIndicatorProps

local Stepper = require("@self/Components/Stepper")
export type StepperProps = Stepper.StepperProps
export type Step = Stepper.Step

local SystemBanner = require("@self/Components/SystemBanner")
export type SystemBannerProps = SystemBanner.SystemBannerProps

local Tabs = require("@self/Components/Tabs")
export type TabsProps = Tabs.TabsProps
export type TabItem = Tabs.TabItem

local Text = require("@self/Components/Text")
export type TextProps = Text.TextProps

local FoundationProvider = require("@self/Providers/Foundation/FoundationProvider")
export type FoundationProviderProps = FoundationProvider.FoundationProviderProps

return {
	-- Components
	Accordion = Accordion,
	Alert = Alert,
	Avatar = Avatar,
	AvatarGroup = AvatarGroup,
	AvatarIcon = AvatarIcon,
	AvatarIconGroup = AvatarIconGroup,
	Badge = Badge,
	Button = Button,
	ButtonGroup = ButtonGroup,
	Checkbox = Checkbox,
	CheckboxGroup = CheckboxGroup,
	Chip = Chip,
	ChipGroup = ChipGroup,
	Coachmark = Coachmark,
	ColorPicker = ColorPicker,
	DateTimePicker = DateTimePicker,
	Dialog = Dialog,
	Divider = Divider,
	Dropdown = Dropdown,
	EducationalTooltip = EducationalTooltip,
	Empty = Empty,
	FeedbackAlert = FeedbackAlert,
	Grid = Grid,
	HeaderBar = HeaderBar,
	Icon = Icon,
	IconButton = IconButton,
	Image = Image,
	InputChip = InputChip,
	InputLabel = InputLabel,
	KeyLabel = KeyLabel,
	Knob = Knob,
	List = List,
	Loading = Loading,
	Menu = Menu,
	NumberInput = NumberInput,
	OptionSelectorGroup = OptionSelectorGroup,
	Pagination = Pagination,
	Popover = Popover,
	Progress = Progress,
	RadioGroup = RadioGroup,
	Rating = Rating,
	ScrollView = ScrollView,
	SearchInput = SearchInput,
	SegmentedControl = SegmentedControl,
	Sheet = Sheet,
	Skeleton = Skeleton,
	Slider = Slider,
	Snackbar = Snackbar,
	StatusBadge = StatusBadge,
	StatusIndicator = StatusIndicator,
	Stepper = Stepper,
	SystemBanner = SystemBanner,
	Tabs = Tabs,
	Text = Text,
	TextArea = TextArea,
	TextInput = TextInput,
	Toast = Toast,
	Toggle = Toggle,
	ToggleGroup = ToggleGroup,
	Tooltip = Tooltip,
	View = View,

	-- Providers
	FoundationProvider = FoundationProvider,
	OverlayProvider = require("@self/Providers/Overlay/OverlayProvider"),
	ResponsiveProvider = ResponsiveProvider,
	BackgroundStyleContext = require("@self/Providers/Style/BackgroundStyleContext"),

	-- Hooks: call them while a component is being created, under FoundationProvider.
	Hooks = {
		useDialogNavigation = require("@self/Components/Dialog/useDialogNavigation"),
		useSheetNavigation = require("@self/Components/Sheet/useSheetNavigation"),
		useMeasurableRef = require("@self/Components/Popover/useMeasurableRef"),
		usePointerPosition = require("@self/Utility/usePointerPosition"),
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
		AccessoryType = AccessoryType,
		AlertSeverity = AlertSeverity,
		AlertVariant = AlertVariant,
		AvatarGroupType = AvatarGroupType,
		AvatarIconSize = AvatarIconSize,
		AvatarSize = AvatarSize,
		BadgeShape = BadgeShape,
		BadgeSize = BadgeSize,
		BadgeVariant = BadgeVariant,
		Breakpoint = Breakpoint,
		-- **DEPRECATED**: ButtonSize is deprecated. Use InputSize instead.
		ButtonSize = InputSize,
		ButtonVariant = ButtonVariant,
		-- **DEPRECATED**: CheckboxSize is deprecated. Use InputSize instead.
		CheckboxSize = InputSize,
		ControlState = ControlState,
		ChipGroupVariant = ChipGroupVariant,
		ChipSize = ChipSize,
		ChipVariant = ChipVariant,
		ColorMode = ColorMode,
		CursorType = CursorType,
		DateTimePickerVariant = DateTimePickerVariant,
		Device = Device,
		DialogSize = DialogSize,
		-- **DEPRECATED**: DividerOrientation is deprecated. Use Orientation instead.
		DividerOrientation = Orientation,
		DividerVariant = DividerVariant,
		FillBehavior = FillBehavior,
		FontName = FontName,
		IconName = BuilderIcons.Icon,
		IconPosition = IconPosition,
		IconSize = IconSize,
		IconVariant = BuilderIcons.IconVariant,
		InputFocusBehavior = InputFocusBehavior,
		InputSize = InputSize,
		InputVariant = InputVariant,
		InputPlacement = InputPlacement,
		InputLabelSize = InputLabelSize,
		ListItemInputType = ListItemInputType,
		NumberInputControlsVariant = NumberInputControlsVariant,
		ScrubBehavior = ScrubBehavior,
		OnChangeCallbackReason = OnChangeCallbackReason,
		OnCloseCallbackReason = OnCloseCallbackReason,
		OptionSelectorGroupSize = OptionSelectorGroupSize,
		Orientation = Orientation,
		PaginationSize = PaginationSize,
		PaginationVariant = PaginationVariant,
		PopoverAlign = PopoverAlign,
		PopoverSide = PopoverSide,
		ProgressShape = ProgressShape,
		ProgressSize = ProgressSize,
		RatingValue = RatingValue,
		Radius = Radius,
		SearchInputShape = SearchInputShape,
		SegmentedControlVariant = SegmentedControlVariant,
		-- **DEPRECATED**: ScrollBarVisibility is deprecated. Use Visibility instead.
		ScrollBarVisibility = Visibility,
		SliderVariant = SliderVariant,
		StateLayerAffordance = StateLayerAffordance,
		StateLayerMode = StateLayerMode,
		StatusBadgeShape = StatusBadgeShape,
		StatusBadgeSize = StatusBadgeSize,
		StatusBadgeVariant = StatusBadgeVariant,
		StatusIndicatorShape = StatusIndicatorShape,
		StatusIndicatorSize = StatusIndicatorSize,
		StatusIndicatorVariant = StatusIndicatorVariant,
		-- **DEPRECATED**: Theme is deprecated. Use ColorMode instead.
		Theme = Theme,
		ThemeName = ThemeName,
		ThumbnailType = ThumbnailType,
		ThumbnailSize = ThumbnailSize,
		-- **DEPRECATED**: ToggleSize is deprecated. Use InputSize instead.
		ToggleSize = InputSize,
		UserPresence = UserPresence,
		Visibility = Visibility,
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
		CarouselIndicator = require("@self/Components/CarouselIndicator"),
		Gradient = require("@self/Components/Gradient"),
		Tile = require("@self/Components/Tile"),
		BaseMenu = BaseMenu,
		AlertActions = AlertActions,
		CloseAffordance = require("@self/Components/CloseAffordance"),
		HintText = require("@self/Components/HintText"),
		InputField = require("@self/Components/InputField"),
		InternalInputGroup = require("@self/Components/InternalInputGroup"),
		Interactable = require("@self/Components/Interactable"),
	},
}
