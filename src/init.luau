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
export type Tokens = Tokens.Tokens
export type TokenOverrides = Tokens.TokenOverrides

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
	ResponsiveProvider = require("@self/Providers/Responsive/ResponsiveProvider"),
	BackgroundStyleContext = require("@self/Providers/Style/BackgroundStyleContext"),

	-- Hooks: call them while a component is being created, under FoundationProvider.
	Hooks = {
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
		BaseMenu = BaseMenu,
		AlertActions = require("@self/Components/AlertActions"),
		CloseAffordance = require("@self/Components/CloseAffordance"),
		HintText = require("@self/Components/HintText"),
		InputField = require("@self/Components/InputField"),
		InternalInputGroup = require("@self/Components/InternalInputGroup"),
		Interactable = require("@self/Components/Interactable"),
	},
}
