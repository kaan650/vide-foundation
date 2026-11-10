# Differences from React Foundation

Every component is checked against Roblox's own React Foundation 1.109.0 in Studio (`harness/Compare.luau`) and
matches it for the cases listed in the commit history. This file lists what is intentionally different or not
covered.

## API shape (Vide instead of React)

- Every data prop accepts a plain value or a source. A component is created once; sources keep it up to date.
- Providers and container components that set a context take `children` as a builder, `() -> any`, so the content
  is created inside the context: `FoundationProvider`, `Popover.Root`/`Popover.Content`, `Accordion.Root`,
  `Tile.Root`, `HeaderBar` slots, `CheckboxGroup`, `RadioGroup`, `ToggleGroup`, `Grid.Debug`, `Coachmark` media.
- Refs and imperative handles are callback props (`textBoxRef`, `inputRef`, `scrollingFrameRef`, Popover's `ref`).
- When a source changes a component's root class (a disabled control fading into a CanvasGroup, a label gaining a
  handler), React remounts it. The Vide component then returns a source of its current instance instead of an
  instance: CloseAffordance, IconButton, InputLabel, Chip, InputChip, InternalInput and the inputs on it (Checkbox,
  Toggle, RadioGroup items), InternalTextInput's container, NumberInput's field. With plain props they return an
  instance. Slider instead keeps a CanvasGroup root while `isDisabled` is a source.
- Props that only exist behind flags that are off live are not ported: Slider `orientation`, SegmentedControl
  `variant`/`fillBehavior`, Progress bar labels, NumberInput Stacked/Split controls.

## Not ported

- The elevated-plugin path of Popover (`ContentPlugin`, `PopoverArrow`, `PopoverShadow`) and the StudioPanels and
  StudioWidgets providers. Foundation only uses them in Roblox's internal plugins, where
  `plugin:GetPluginComponent("Panels")` works; elsewhere popovers use the overlay, as here.
- `ObjectViewport`, which only Foundation's stories use.
- Deprecated enum aliases `CheckboxSize` and `ToggleSize`.

## Not verified with real input

Studio's Edit mode cannot hover, press, drag or switch input type, so these paths are line-by-line ports checked by
reading, not by the comparator: hover and press state layers, Popover click-outside, Slider and NumberInput drag and
scrub, gamepad navigation in menus, OverflowScrollContainer scrim clicks, touch-only TextBox behavior.

## Known small differences

- Loading's spinner starts its rotation at creation; React starts it after mount, so the angle is offset by a few
  frames.
- TextArea's invisible bounds checker can hold the new text one update earlier than React when `isDisabled` and
  `text` change in separate writes.
