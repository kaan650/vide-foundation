# VideFoundation

Roblox's Foundation design system for [Vide](https://github.com/centau/vide), ported from React Foundation 1.109.

## Install

```toml
[dependencies]
VideFoundation = "kaan650/vide-foundation@0.1.1"
```

## Usage

```luau
local Vide = require(ReplicatedStorage.Packages.Vide)
local Foundation = require(ReplicatedStorage.Packages.VideFoundation)

local count = Vide.source(0)

Vide.mount(function()
	return Foundation.FoundationProvider({
		colorMode = "Dark",
		children = function()
			return Foundation.View({
				tag = "size-full bg-surface-100 padding-xlarge col gap-large",
				children = {
					Foundation.Text({
						Text = function()
							return `Clicked {count()} times`
						end,
						tag = "auto-xy text-heading-large content-emphasis",
						LayoutOrder = 1,
					}),
					Foundation.Button({
						text = "Click",
						variant = "Emphasis",
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

- Props take a value or a source: `isDisabled = disabled`, `text = function() return ... end`.
- Style with Foundation's tags, `tag = "bg-surface-100 radius-medium"`. On your own instances, use
  `Foundation.tags("bg-surface-100")`.
- Components that provide a context (`FoundationProvider`, `Popover.Root`, `List.Root`...) take `children` as a
  function.
- Refs are callback props: `ref`, `textBoxRef`, `inputRef`.

To see every component, run `wally install` and `rojo serve dev.project.json`, then open the VideFoundation
storybook in [UI Labs](https://ui-labs.luau.page/).

Foundation, its design tokens, Builder Icons and images are made by Roblox.
