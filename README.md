# VideFoundation

Roblox's Foundation design system — the components the Roblox app and Studio are built with — for
[Vide](https://github.com/centau/vide).

It is a port of Foundation 1.109.0 from React Luau. Each component was rendered next to Roblox's own React
Foundation in Studio and compared property by property (class, name, tags, styled colors, fonts, sizes and
positions) until both trees matched, for its variants, sizes, states and prop changes. Animations run on
[Ripple](https://github.com/littensy/ripple) with Foundation's exact easing curves.

## Install

With [Wally](https://wally.run):

```toml
[dependencies]
VideFoundation = "kaan650/vide-foundation@0.1.0"
```

It depends on Vide 0.4 and Ripple 0.10.

## Use

```luau
local Vide = require(ReplicatedStorage.Packages.Vide)
local Foundation = require(ReplicatedStorage.Packages.VideFoundation)

local Button = Foundation.Button
local View = Foundation.View
local Text = Foundation.Text

local count = Vide.source(0)
local loading = Vide.source(false)

Vide.mount(function()
	return Foundation.FoundationProvider({
		colorMode = "Dark",
		-- Build the UI inside the provider, so components find the styles and contexts.
		children = function()
			return View({
				tag = "size-full bg-surface-100 padding-xlarge col gap-large",
				children = {
					Text({
						Text = function()
							return `Clicked {count()} times`
						end,
						tag = "auto-xy text-heading-large content-emphasis",
						LayoutOrder = 1,
					}),
					Button({
						text = "Click",
						variant = "Emphasis",
						isLoading = loading,
						onActivated = function()
							count(count() + 1)
						end,
						LayoutOrder = 2,
					}),
				},
			})
		end,
	})
end, playerGui.ScreenGui)
```

- **Every data prop takes a value or a source.** Pass a source (or any function reading sources) and the component
  follows it: `isDisabled = disabled`, `text = function() return ... end`. Callbacks and children are plain.
- **Style with Foundation's tags.** `tag = "bg-surface-100 radius-medium padding-large"` works on `View`, `Text` and
  `Image`. For your own instances use the `tags` action: `create "Frame" { Foundation.tags("bg-surface-200") }`.
  The tags come from Foundation's tokens, so they follow the theme.
- **Theme at runtime.** `colorMode`, `themeName` and `tokenOverrides` on `FoundationProvider` take sources; switching
  them restyles everything already on screen.
- **Hooks** (`Foundation.Hooks.useTokens()`, `useOverlay()`...) run while a component is being created, under the
  provider. Most return sources.
- Containers that provide a context (`Popover.Root`, `List.Root`, `RadioGroup`, `Accordion.Root`...) take
  `children` as a builder function, like the provider.

`docs/DEVIATIONS.md` lists every place where the API or behavior differs from React Foundation, and why.

## Components

Accordion, Alert, Avatar, AvatarGroup, AvatarIcon, AvatarIconGroup, Badge, Button, ButtonGroup, Checkbox,
CheckboxGroup, Chip (Pill), ChipGroup, Coachmark, ColorPicker, DateTimePicker, Dialog, Divider, Dropdown,
EducationalTooltip, Empty, FeedbackAlert, Grid, HeaderBar, Icon, IconButton, Image, InputChip, InputLabel, KeyLabel,
Knob, List, Loading, Menu, NumberInput, OptionSelectorGroup, Pagination, Popover, Progress, RadioGroup, Rating,
ScrollView, SearchInput, SegmentedControl, Sheet, Skeleton, Slider, Snackbar, StatusBadge, StatusIndicator, Stepper,
SystemBanner, Tabs, Text, TextArea, TextInput, Toast, Toggle, ToggleGroup, Tooltip, View.

Enums are under `Foundation.Enums`, hooks under `Foundation.Hooks`, and `BaseMenu` and `Interactable` under
`Foundation.UNSTABLE`, as in Foundation.

## Development

- `rokit install`, `wally install`, then `rojo serve dev.project.json` and open a place with the Rojo plugin.
- `tools/analyze.sh` runs luau-lsp in strict mode with the new type solver; it prints nothing when clean.
- `node tools/gen-reference.mjs` loads Roblox's React Foundation from your Studio install into the dev place, and
  `harness/Compare.luau` renders a Vide component next to the React one and diffs them. `docs/PORTING.md` explains
  the porting rules and how to run a comparison.
- `docs/flags.md` lists Foundation's feature flags and the live value each one is fixed to.

## Credits

Foundation, its design tokens, Builder Icons and images are made by Roblox. This package ports Foundation's
components to Vide and ships Roblox's token, icon and image data unchanged in `src/Packages`.
