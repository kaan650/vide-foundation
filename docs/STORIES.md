# Porting Foundation's stories

Foundation ships 131 stories for 72 components next to its source, in `$F/Components/<Name>/*.story.lua`
(`$F` = `%LOCALAPPDATA%/Roblox Studio/ExtraContent/LuaPackages/Packages/_Index/Foundation/Foundation`), plus shared
helpers in `$F/Utility/Stories/Shared` and token/image galleries in `$F/Utility/Stories/Elements`. They show every
variant, size and state the way Roblox's designers lay them out. Each one becomes a UI Labs story for Vide.

## Format

- One Foundation story module (`return { summary, stories = { { name, story }, ... }, controls }`) becomes one UI Labs
  module built with `foundation.sections` from `stories/foundation.luau`:

  ```luau
  local foundation = require("../foundation")
  local VF = foundation.VF

  return foundation.sections({
  	summary = "Badge is a non-interactive visual cue ...",   -- Foundation's summary, unchanged
  	controls = { text = "Label", variant = foundation.UILabs.Choose({ ... }) },
  	sections = {
  		{ name = "Playground", story = function(controls) return VF.Badge({ text = controls.text, ... }) end },
  		{ name = "Variants", story = function() return ... end },
  	},
  })
  ```

  A `section` control picks the sub-story; the theme and color-mode controls come for free.
- Controls: a Foundation array control (`variant = Dash.values(BadgeVariant)`) becomes `UILabs.Choose(list)`;
  strings, numbers, booleans and Color3 stay plain. Inside `story(controls)`, each control is a Vide source: pass it
  straight into props (every data prop accepts a source).
- Files go to `stories/<Storybook>/<Same name>.story.luau`, mirroring Foundation's storybooks: `Components` (most),
  `BaseComponents` (View, Text, Image, Interactable), `Elements` (Tokens, TokenOverrides, Images). Skip `Planned`,
  `Internal`, `Flags`, `DeprecatedComponents` and the stories of internal parts that are not exported (InternalInput,
  InternalTextInput, CircularProgressBar...) unless they are the only place a public behavior is shown.
- Shared helpers (`MatrixGrid`, `StoryIcons`, `InputGroupStory`, ...) are ported once into `stories/Shared/` with the
  same names and used the same way.
- Requires: relative (`"../foundation"`, `"../Shared/MatrixGrid"`) or `@game/...`. UI Labs' loader rejects other
  aliases.
- Content is Foundation's: same sections, texts, icons, sample user ids, layout. Port React patterns as in
  `docs/PORTING.md` (state → `Vide.source`, lists → plain loops for static data). Interactive stories (a Dialog
  opened by a button, a controlled TextInput) keep their state in sources inside the section function.
- Comments: English and few, as in `docs/PORTING.md`.

## Checking a story

Mount each story in Studio (place `VideFoundationDev.rbxl`, Rojo connected) through MCP `execute_luau` in Edit mode,
the way UI Labs does: require the module, create a Vide source per control (`control.ControlValue` for UI Labs
controls, the value itself otherwise), `Vide.mount(function() return story.story({ controls = sources }) end, frame)`
into a Frame under a ScreenGui in StarterGui. Then:

1. Switch `section` through every name and flip the other controls once; nothing may error (wrap in `pcall`, and
   watch `LogService.MessageOut` for errors and warnings other than Foundation's own `[VideFoundation]` warnings).
2. Do it with `Vide.strict = true` too (UI Labs runs strict; MCP runs non-strict by default). Set it on the Vide you
   required before mounting and restore it after.
3. Screenshot (`screen_capture`) the Playground and one matrix section of each story and look at it: it should look
   like Foundation's story (no overlapping, nothing missing, readable in Dark and Light).
4. Clean up every ScreenGui and destroy every mount.
