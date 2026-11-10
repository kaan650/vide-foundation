# Porting Foundation to Vide

The source is Roblox's Foundation 1.109.0, shipped with Studio at
`%LOCALAPPDATA%/Roblox Studio/ExtraContent/LuaPackages/Packages/_Index/Foundation/Foundation`.
Every rule below exists so a ported component looks and behaves like the React original.

## Layout

- `src/` mirrors Foundation's tree: `Components/<Name>/`, `Providers/`, `Utility/`, `StyleSheet/`, `Enums/`, `Generated/`.
  Keep Foundation's file names, with `.luau`. A reader must be able to open both files side by side.
- Tests, stories and `.md` docs are not copied. Stories are rewritten for UI Labs under `stories/`.
- `src/Packages/` holds dependencies:
  - `Vide.luau`, `Ripple.luau`, `VideRipple.luau` re-export the Wally packages.
  - `BuilderIcons`, `FoundationImages`, `FoundationCloudAssets`, `RbxDesignFoundations`, `RbxDesignFoundationsV3` are
    Roblox data packages copied unchanged, except `FoundationImages/Flags.luau`.
- React, ReactOtter, Otter, Motion, ReactUtils, ReactIs, Dash, Signal and Lumberyak are not dependencies. Their uses are
  replaced as described below.

## Requires

- Relative string requires only: `require("./Sibling")`, `require("../../Utility/withDefaults")`.
- Paths follow the instance tree. In `Foo/init.luau`, `./` means Foo's siblings and `@self/` means Foo's children.
- Never `script:FindFirstAncestor(...)`: Wally renames the root to `vide-foundation`, and the analyzer loses the types.

## Flags

Foundation reads ~70 FFlags. Each is resolved at port time to its live value (`docs/flags.md`), the dead branch is
deleted, and no `Flags` module exists. A compound flag (`FoundationThemeName = FoundationStyleSheetRefCounting and ...`)
resolves through its parts.

## React to Vide

A component is a function called once. It returns its root instance.

| React | Vide |
|---|---|
| `Bindable<T>`, and any data prop React re-renders on | `Value<T>` (`T \| () -> T`), read with `read()` inside a reactive scope |
| `useState` | `source` |
| `useMemo` | `derive`, or a plain function when cheap |
| `useEffect`, `useLayoutEffect` | `effect`, with `cleanup` for teardown |
| `useCallback` | a plain function |
| `useRef` | a local variable |
| `useBinding` | `source` |
| `joinBindables`, `mapBindable`, `binding:map` | a function reading the inputs |
| `useContext`, `Context.Provider` | `vide.context`, read in the component body |
| element only rendered when a reactive condition holds | `show` / `switch` |
| list from reactive data | `indexes` / `values`, with `LayoutOrder` from the key |
| `ref`, `forwardRef` | the component returns its instance; imperative handles become callback props |
| `[React.Tag]` | `tags(...)` action from `Utility/tags`, which diffs CollectionService tags |
| `[React.Event.X]` | `X = fn` |
| `[React.Change.P]` | `Vide.changed("P", fn)` |
| `React.Fragment` | an array of instances |

- **Every data prop is `Value<T>`.** React re-renders on any prop change; Vide does not, so a static-only prop would
  freeze. Callbacks and children are plain. A prop that changes structure (an icon appearing) needs `show`.
- Reading a prop inside the component body does not subscribe. Read it inside `create` property functions,
  `derive` or `effect`.
- Construct instances with `Utility/create`, never `Vide.create`: it turns Vide's defaults off, because Foundation's
  StyleSheet rules must win over code-set properties.

## Styling

Foundation's tags and StyleSheet registry work unchanged. Components pass a tag string such as `"bg-surface-100 radius-small"`;
the `tags` action registers the tags with the provider's sheet, which creates the StyleRules on first use.

## Motion

`Utility/Motion` replaces Otter, ReactOtter and Motion on top of Ripple:
- Eases run a linear Ripple tween from 0 to 1 and map it through Otter's curve, including cubic-bezier
  `{ x1, y1, x2, y2 }` easing styles, so durations and curves match Foundation exactly.
- Springs use Ripple springs with Otter's `dampingRatio` and `frequency`; Ripple uses the same closed-form solver.

## Assets

Props that took an asset string accept `string | Content` and the component sets `ImageContent`. FoundationImages keys
(`"icons/common/robux"`) still resolve through the image set data.

## Comments

English and few (Kaan's rule). Foundation's comments are dropped unless they explain a trap, a measured number or an
upstream workaround. Prop descriptions on exported prop types stay.
