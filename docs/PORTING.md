# Porting Foundation to Vide

The source is Roblox's Foundation 1.109.0, shipped with Studio at
`%LOCALAPPDATA%/Roblox Studio/ExtraContent/LuaPackages/Packages/_Index/Foundation/Foundation` (called `$F` below).
A port is done when it looks and behaves like the React original: the comparator in `harness/Compare.luau` reports
`MATCH` against Roblox's own React component in Studio.

Reference ports to copy patterns from: `Components/View`, `Text`, `Image`, `Icon`, `Button` (variants, Motion, reactive
props, `show`/`switch`), `Interactable/withInteractable`.

## Layout

- `src/` mirrors Foundation: `Components/<Name>/`, `Providers/`, `Utility/`, `StyleSheet/`, `Enums/`, `Generated/`.
  Keep Foundation's file names, with `.luau`, so both can be read side by side.
- Every component folder has `init.luau` re-exporting the component and its exported types. `node tools/gen-inits.mjs`
  writes missing ones.
- Tests, stories and `.md` docs are not copied.
- `src/Packages/` holds dependencies: `Vide`, `Ripple`, `VideRipple` (Wally re-exports) and Roblox's data packages
  (`BuilderIcons`, `FoundationImages`, `FoundationCloudAssets`, `RbxDesignFoundations`), unchanged.
- React, ReactOtter, Otter, Motion, ReactUtils, ReactIs, Dash, Signal, Lumberyak, SafeFlags are not dependencies.
  `Utility/Dash` and `Utility/Motion` replace Dash and Motion/Otter/ReactOtter with the same API.

## Requires

- Relative string requires only: `require("./Sibling")`, `require("../../Utility/withDefaults")`. In
  `Foo/init.luau`, `./` means Foo's siblings and `@self/` means Foo's children.
- Never `script:FindFirstAncestor(...)`: Wally renames the root, and the analyzer loses types.
- `node tools/port.mjs <path under $F>[=<dest under src>] ...` copies a file and rewrites its instance requires,
  including `Packages.Dash` → `Utility/Dash` and `Packages.Motion|Otter|ReactOtter` → `Utility/Motion`. It prints the
  leftovers (React, ReactUtils, Flags, Signal...) that need hand work. Pure modules (enums, data, math, variant tables)
  usually need nothing else.

## Flags

Each FFlag is resolved to its live value (`docs/flags.md`; a flag missing there is false), the dead branch is
deleted, and nothing reads a `Flags` module. Compound flags resolve through their parts, as in `$F/Utility/Flags.lua`.
Notable live values: ThemeName, StyleRulePseudoName, StyleSheetRefCounting, DisableTokenScaling (console uses desktop
sizes), TokenOverrides, the *Beta* updates for Checkbox/Radio/Toggle/Avatar/Tooltip/Dialog/NumberInput/
OptionSelectorGroup/DateTimePicker are on; UsePath2DSpinner, ViewMemoizationChanges, BadgeBetaUpdate3,
ProgressBarBetaUpdate, SliderBeta2, SegmentedControlBeta, BaseMenuContentSizing, PopoverContentAnchorFix,
StatusIndicatorVariantExperiment2, UnifiedScrimScrolling are off.

## Components in Vide

A component is a function called once. It returns its root instance (or, for a component React renders as a
fragment, an array).

| React | Vide |
|---|---|
| `Bindable<T>` and every data prop | `Value<T>` (`T \| () -> T`), read with `Value.read` inside a reactive scope |
| `useState`, `useBinding` | `Vide.source` |
| `useMemo` | `Vide.derive`, or a plain function when cheap |
| `useEffect`, `useLayoutEffect` | `Vide.effect`, with `Vide.cleanup` for teardown |
| `useCallback`, `useRef` | a plain function, a local variable |
| `joinBindings`, `binding:map`, `mapBindable` | a function reading the inputs |
| `useContext` | the hook (`useTokens()`...), called while the component is being created |
| conditional element on a reactive condition | `Vide.show` / `Vide.switch` |
| list from reactive data | `Vide.indexes` / `Vide.values`, `LayoutOrder` from the key |
| `ref` / `forwardRef` | the returned instance; imperative handles become callback props |
| `[React.Tag]` / `useStyleTags` | `tags(...)` action (`Utility/tags`), accepts several values and sources |
| `[React.Event.X]` / `[React.Change.P]` | `X = fn` / `Vide.changed("P", fn)` or a `GetPropertyChangedSignal` + `cleanup` |
| `React.Fragment` | an array |
| `ReactOtter.useAnimatedBinding`, `Otter.ease/spring/instant` | `Motion.useAnimatedBinding`, `Motion.ease/spring/instant` |
| `Motion.useMotion`, `createState`, `transition` | the same names on `Utility/Motion` |
| `ReactUtils.useClock` + map | `Utility/useRotation` or a Heartbeat-driven source |

### Props

- **Every data prop is `Value<T>`.** Callbacks and children are plain. `withDefaults` makes a source prop fall back to
  its default whenever it reads nil, as React applies defaults each render.
- **Static props must produce exactly React's instance tree.** A reactive prop that adds or removes an element uses
  `show`/`switch` (Button's icon, text, spinner). Table props (`stroke`, `layout`, `flexItem`, `sizeConstraint`) may be
  a source of a table or nil; `GuiObjectChildren` shows the component only while it exists.
- A binding that can yield nil must not be a plain `create` property (Vide errors on nil). Use
  `Value.bindProperty(name, source)`, which resets the property to its engine default on nil so style rules apply,
  as React does.
- Hooks (`useTokens`, `usePresentationContext`, `useCursor`, `useOverlay`, `useElevation`...) run during creation,
  never inside effects or callbacks. `useTokens()`, `useTextSizeOffset()`, `usePreferences()`, `useOverlay()` return
  sources.

### Instance names

Children get the name of the React key they render under (`IconWrapper`, `Text`, `Loading`...), set with
`instance.Name = "..."` or `Name = "..."` in `create`. `GuiObjectChildren` already names `CornerRadius`, `Padding`,
`Stroke`, `ListLayout`, `FlexItem`, `SizeConstraint`, `Scale`, `AspectRatio`. The comparator checks names below the
root.

### Building instances

- `Utility/create` (never `Vide.create`): typed, and with Vide's defaults off, because Foundation's style rules must win
  over code-set properties.
- Foundation base components (`View`, `Text`, `Image`) cover most needs, exactly as in React. For engine instances use
  `create` plus `tags(...)` for Foundation tags.
- `withCommonProps(props, target)` forwards the common props to another Foundation component (prop level).
  `withGuiObjectProps` turns props into instance properties; components built on View/Text/Image never need it.

## Traps found so far

- Vide runs effects twice in Studio (strict mode): effects must be idempotent. Wrap `animate`/`setGoal`/side effects
  in `Vide.untrack` inside effects so only the intended inputs are tracked.
- Calling a nullable source with no arguments is ambiguous to the type checker (centau/vide#71): read it through a
  getter typed once, `local get: () -> T? = source :: any`.
- `Value.read` is typed with a type function; generic helpers like `Value.map` sometimes fail inference. Write the
  branch out: `if type(v) == "function" then ... else ... end`.
- Indexing token tables or enum tables with a computed key needs `(tokens :: any)[key]`.
- React passes some numbers through `Vector2` (float32) before a `UDim` truncates them. Match it (Text's line height).
- Ripple completion callbacks run deferred one frame (`createMotor`), to avoid Ripple's scheduler crash when a
  callback destroys another animation.
- `SafeFlags` in Studio's plugin context returns true for every flag, so the reference harness patches it with live
  values (`tools/gen-reference.mjs`).

## Checking a port

1. `tools/analyze.sh` prints nothing (strict, new solver). Pass a path to check one file.
2. In Studio (place `VideFoundationDev.rbxl`, Rojo connected), run the comparator from `execute_luau` in Edit mode:

   ```luau
   local Compare = require(game.ReplicatedStorage.Harness.Compare:Clone())
   return Compare.run({
   	id = "Divider",                 -- unique per caller, so runs don't clobber each other
   	vide = function(VF, Vide) return VF.Divider({ orientation = "Vertical" }) end,
   	react = function(F, React) return React.createElement(F.Divider, { orientation = "Vertical" }) end,
   	-- frames = 30, ignore = { Prop = true }, before = function() set sources end, keep = true,
   })
   ```

   `VF` is the package root, so export the component in `src/init.luau` first (or require its module from the cloned
   package inside `vide`). Cover the variants, sizes and states, and for reactive props, start from one value and
   switch in `before` to the value React renders.
3. A difference mid-animation (a transparency sampled while tweening) is acceptable; anything else is fixed or written
   down with its reason.

## Comments

English and few. Foundation's comments are dropped unless they explain a trap, a measured number or an upstream
workaround. Prop descriptions on exported prop types stay. Tags: `--*` key reason, `--! ` trap, `--?` unverified,
`--TODO` pending, `---` documents exported functions and types.
