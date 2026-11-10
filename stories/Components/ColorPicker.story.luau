local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local UILabs = foundation.UILabs

local ButtonVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ButtonVariant")
local ColorInputMode = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ColorInputMode")
local PopoverSide = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/PopoverSide")
local Types = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/Types")
local colorUtils = require("@game/ReplicatedStorage/Packages/VideFoundation/Components/ColorPicker/colorUtils")

type ColorInputMode = ColorInputMode.ColorInputMode
type ColorStyleValue = VideFoundation.ColorStyleValue
type FontStyle = VideFoundation.FontStyle
type PartialColorHSV = Types.PartialColorHSV

local CHECKERBOARD_IMAGE = "component_assets/checkerboard_12"

local function typography(tokens: () -> any, name: string): () -> FontStyle
	return function()
		return tokens().Typography[name]
	end
end

local function toByte(channel: number): number
	return math.floor(channel * 255)
end

local function toHex(color: Color3): string
	return string.format("#%02X%02X%02X", toByte(color.R), toByte(color.G), toByte(color.B))
end

--- A swatch over a checkerboard, so a transparent color shows as one.
local function Swatch(props: {
	size: number,
	radiusTag: string,
	color: () -> Color3,
	transparency: () -> number,
	LayoutOrder: number?,
})
	local tokens = VF.Hooks.useTokens()
	return VF.View({
		Size = UDim2.fromOffset(props.size, props.size),
		tag = props.radiusTag,
		stroke = {
			Color = function()
				return tokens().Color.System.Neutral.Color3 :: Color3
			end,
			Transparency = function()
				return tokens().Color.System.Neutral.Transparency :: number
			end,
			Thickness = 1,
		},
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Image({
				Image = CHECKERBOARD_IMAGE,
				ScaleType = Enum.ScaleType.Tile,
				TileSize = UDim2.fromOffset(12, 12),
				tag = `size-full {props.radiusTag}`,
				ZIndex = 1,
			}),
			VF.View({
				tag = `size-full {props.radiusTag}`,
				backgroundStyle = function(): ColorStyleValue
					return { Color3 = props.color(), Transparency = props.transparency() }
				end,
				ZIndex = 2,
			}),
		},
	})
end

local function ColorPreview(
	props: {
		color: () -> Color3,
		-- nil hides the alpha in the swatch and in the labels.
		alpha: (() -> number?)?,
		showAlpha: (() -> boolean) | boolean,
		LayoutOrder: number?,
	}
)
	local tokens = VF.Hooks.useTokens()
	local readAlpha: () -> number? = props.alpha or function()
		return nil
	end

	local function showAlpha(): boolean
		local show = props.showAlpha
		return if type(show) == "function" then show() else show
	end

	local function caption(text: () -> string, layoutOrder: number)
		return VF.Text({
			Text = text,
			fontStyle = typography(tokens, "CaptionLarge"),
			textStyle = function(): ColorStyleValue
				return tokens().Color.Content.Default :: ColorStyleValue
			end,
			TextXAlignment = Enum.TextXAlignment.Left,
			tag = "size-full-0 auto-y",
			LayoutOrder = layoutOrder,
		})
	end

	return VF.View({
		tag = "row gap-medium size-full-0 auto-y",
		LayoutOrder = props.LayoutOrder,
		children = {
			Swatch({
				size = 64,
				radiusTag = "radius-medium",
				color = props.color,
				transparency = function()
					local alpha = readAlpha()
					return if alpha then 1 - alpha else 0
				end,
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "col grow gap-xsmall auto-y",
				layout = {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
				},
				LayoutOrder = 2,
				children = {
					VF.Text({
						Text = function()
							return toHex(props.color())
						end,
						fontStyle = typography(tokens, "BodyLarge"),
						textStyle = function(): ColorStyleValue
							return tokens().Color.Content.Emphasis :: ColorStyleValue
						end,
						TextXAlignment = Enum.TextXAlignment.Left,
						tag = "size-full-0 auto-y",
						LayoutOrder = 1,
					}),
					Vide.show(function()
						return readAlpha() ~= nil and showAlpha()
					end, function()
						return caption(function()
							local color = props.color()
							local alpha = readAlpha() or 1
							return string.format(
								"#%02X%02X%02X%02X",
								toByte(color.R),
								toByte(color.G),
								toByte(color.B),
								toByte(alpha)
							)
						end, 2)
					end),
					caption(function()
						local color = props.color()
						return string.format("RGB(%d, %d, %d)", toByte(color.R), toByte(color.G), toByte(color.B))
					end, 3),
					Vide.show(function()
						return readAlpha() ~= nil and showAlpha()
					end, function()
						return caption(function()
							local color = props.color()
							return string.format(
								"RGBA(%d, %d, %d, %.2f)",
								toByte(color.R),
								toByte(color.G),
								toByte(color.B),
								readAlpha() or 1
							)
						end, 4)
					end),
				},
			}),
		},
	})
end

local function initialBlue(): Color3
	return Vide.untrack(VF.Hooks.useTokens()).Color.Extended.Blue.Blue_1100.Color3 :: Color3
end

local function PlaygroundStory(controls: { [string]: any })
	local selectedColor = Vide.source(initialBlue())
	local selectedAlpha = Vide.source(1)

	return VF.View({
		Size = UDim2.fromOffset(300, 340),
		tag = "col gap-medium",
		children = {
			ColorPreview({
				color = selectedColor,
				alpha = function(): number?
					return if controls.hasAlpha() then selectedAlpha() else nil
				end,
				showAlpha = controls.hasAlpha,
				LayoutOrder = 1,
			}),
			--* initialMode and initialAlpha are only read on mount, so a change to either builds the picker again.
			foundation.rebuildOn(function()
				return `{controls.initialMode()}-{controls.hasAlpha()}`
			end, function()
				local hasAlpha: boolean = controls.hasAlpha()
				return VF.ColorPicker({
					initialColor = selectedColor,
					initialAlpha = if hasAlpha then selectedAlpha else nil,
					initialMode = controls.initialMode(),
					onColorChanged = function(newColor: Color3)
						selectedColor(newColor)
					end,
					onAlphaChanged = if hasAlpha
						then function(newAlpha: number)
							selectedAlpha(newAlpha)
						end
						else nil,
					LayoutOrder = 2,
				})
			end),
		},
	})
end

local function WithPreviewStory()
	local selectedColor = Vide.source(initialBlue())
	local selectedAlpha = Vide.source(1)

	return VF.View({
		Size = UDim2.fromOffset(300, 300),
		tag = "col gap-medium",
		children = {
			ColorPreview({
				color = selectedColor,
				alpha = selectedAlpha,
				showAlpha = true,
				LayoutOrder = 1,
			}),
			VF.ColorPicker({
				initialColor = selectedColor,
				initialAlpha = selectedAlpha,
				onColorChanged = function(newColor: Color3)
					selectedColor(newColor)
				end,
				onAlphaChanged = function(newAlpha: number)
					selectedAlpha(newAlpha)
				end,
				onDragStarted = function()
					print("Drag started!")
				end,
				onDragEnded = function()
					print("Drag ended!")
				end,
				LayoutOrder = 2,
			}),
		},
	})
end

local function WithoutAlphaStory()
	local selectedColor = Vide.source(initialBlue())

	return VF.View({
		Size = UDim2.fromOffset(300, 300),
		tag = "col gap-medium",
		children = {
			ColorPreview({
				color = selectedColor,
				showAlpha = false,
				LayoutOrder = 1,
			}),
			VF.ColorPicker({
				initialColor = selectedColor,
				onColorChanged = function(newColor: Color3)
					selectedColor(newColor)
				end,
				LayoutOrder = 2,
			}),
		},
	})
end

local function PopoverButton(props: { text: string, onActivated: () -> (), LayoutOrder: number })
	local tokens = VF.Hooks.useTokens()
	return VF.UNSTABLE.Interactable({
		onActivated = props.onActivated,
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = props.LayoutOrder,
		VF.View({
			tag = "auto-xy padding-small radius-small",
			backgroundStyle = function(): ColorStyleValue
				return tokens().Color.Surface.Surface_100 :: ColorStyleValue
			end,
			stroke = {
				Color = function()
					return tokens().Color.System.Neutral.Color3 :: Color3
				end,
				Transparency = function()
					return tokens().Color.System.Neutral.Transparency :: number
				end,
				Thickness = 1,
			},
			children = VF.Text({
				Text = props.text,
				fontStyle = typography(tokens, "BodyMedium"),
				textStyle = function(): ColorStyleValue
					return tokens().Color.Content.Default :: ColorStyleValue
				end,
				tag = "auto-xy",
			}),
		}),
	} :: any)
end

local function WithPopoverStory()
	local tokens = VF.Hooks.useTokens()
	local selectedColor = Vide.source(initialBlue())
	local selectedAlpha = Vide.source(1)
	local isPopoverOpen = Vide.source(false)
	local originalColor = initialBlue()
	local originalAlpha = 1

	return VF.View({
		Size = UDim2.fromOffset(600, 400),
		tag = "row align-x-center align-y-center",
		children = VF.Popover.Root({
			isOpen = isPopoverOpen,
			children = function()
				return {
					VF.Popover.Anchor({
						children = VF.View({
							tag = "row align-y-center gap-medium auto-xy",
							children = VF.UNSTABLE.Interactable({
								onActivated = function()
									if not isPopoverOpen() then
										originalColor = selectedColor()
										originalAlpha = selectedAlpha()
									end
									isPopoverOpen(not isPopoverOpen())
								end,
								Size = UDim2.new(0, 0, 0, 0),
								AutomaticSize = Enum.AutomaticSize.XY,
								VF.View({
									tag = "row align-y-center gap-small auto-xy padding-small stroke-neutral radius-small",
									backgroundStyle = function(): ColorStyleValue
										return tokens().Color.Surface.Surface_100 :: ColorStyleValue
									end,
									children = {
										Swatch({
											size = 24,
											radiusTag = "radius-small",
											color = selectedColor,
											transparency = function()
												return 1 - selectedAlpha()
											end,
											LayoutOrder = 1,
										}),
										VF.Text({
											Text = function()
												return toHex(selectedColor())
											end,
											fontStyle = typography(tokens, "BodyMedium"),
											textStyle = function(): ColorStyleValue
												return tokens().Color.Content.Default :: ColorStyleValue
											end,
											tag = "auto-xy",
											LayoutOrder = 2,
										}),
									},
								}),
							} :: any),
						}),
					}),
					VF.Popover.Content({
						side = PopoverSide.Right,
						hasArrow = true,
						onPressedOutside = function()
							isPopoverOpen(false)
						end,
						children = function()
							return VF.View({
								tag = "col gap-medium padding-medium",
								Size = UDim2.fromOffset(300, 300),
								children = {
									VF.ColorPicker({
										initialColor = selectedColor,
										initialAlpha = selectedAlpha,
										onColorChanged = function(newColor: Color3)
											selectedColor(newColor)
										end,
										onAlphaChanged = function(newAlpha: number)
											selectedAlpha(newAlpha)
										end,
										LayoutOrder = 1,
									}),
									VF.View({
										tag = "row align-x-right gap-small size-full-0 auto-y margin-top-medium",
										LayoutOrder = 2,
										children = {
											PopoverButton({
												text = "Cancel",
												onActivated = function()
													selectedColor(originalColor)
													selectedAlpha(originalAlpha)
													isPopoverOpen(false)
												end,
												LayoutOrder = 1,
											}),
											PopoverButton({
												text = "Done",
												onActivated = function()
													isPopoverOpen(false)
												end,
												LayoutOrder = 2,
											}),
										},
									}),
								},
							})
						end,
					}),
				}
			end,
		}),
	})
end

local function PropertiesPanelSpecStory()
	local tokens = VF.Hooks.useTokens()
	local selectedColor = Vide.source(initialBlue())
	local selectedAlpha = Vide.source(1)

	return VF.View({
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromOffset(208, 0),
		children = {
			foundation.create("UIStroke")({
				Name = "Stroke",
				Color = function()
					return tokens().Color.System.Contrast.Color3 :: Color3
				end,
				Thickness = 1,
				Transparency = 0,
			}),
			VF.ColorPicker({
				initialColor = selectedColor,
				initialAlpha = selectedAlpha,
				initialMode = ColorInputMode.Hex,
				onColorChanged = function(newColor: Color3)
					selectedColor(newColor)
				end,
				onAlphaChanged = function(newAlpha: number)
					selectedAlpha(newAlpha)
				end,
			}),
		},
	})
end

local BRICK_MODES: { ColorInputMode } = { ColorInputMode.Brick }

local function BrickColorOnlyStory()
	local tokens = VF.Hooks.useTokens()
	local selectedColor = Vide.source(BrickColor.new("Bright red").Color)
	local pickerSize = Vide.source(Vector2.zero)

	return VF.View({
		tag = "col gap-small",
		children = {
			VF.Text({
				Text = function()
					local size = pickerSize()
					return `Actual size: {math.round(size.X)}×{math.round(size.Y)}`
				end,
				tag = "text-caption-small content-muted",
				LayoutOrder = 1,
			}),
			VF.View({
				tag = "auto-xy",
				LayoutOrder = 2,
				onAbsoluteSizeChanged = function(frame: GuiObject)
					pickerSize(frame.AbsoluteSize)
				end,
				stroke = {
					Color = function()
						return tokens().Color.System.Contrast.Color3 :: Color3
					end,
					Thickness = 1,
					Transparency = 0,
				},
				children = VF.ColorPicker({
					initialColor = selectedColor,
					availableModes = BRICK_MODES,
					initialMode = ColorInputMode.Brick,
					onColorChanged = function(newColor: Color3, _brickColor: BrickColor?)
						selectedColor(newColor)
					end,
				}),
			}),
		},
	})
end

local function PartialHSVStory()
	local tokens = VF.Hooks.useTokens()
	local selectedColor = Vide.source({ H = 15 } :: Color3 | PartialColorHSV)

	local function hasFullColor(): boolean
		return not colorUtils.isPartialHSV(selectedColor())
	end

	local function colorForSwatch(): Color3
		local color = selectedColor()
		if typeof(color) == "Color3" then
			return color
		end
		return tokens().Color.Extended.Magenta.Magenta_700.Color3 :: Color3
	end

	return VF.View({
		Size = UDim2.fromOffset(300, 400),
		tag = "col gap-medium",
		children = {
			VF.Text({
				Text = "When only hue is set, S and V show as empty. The submit button stays disabled until a full color is selected.",
				fontStyle = typography(tokens, "CaptionLarge"),
				textStyle = function(): ColorStyleValue
					return tokens().Color.Content.Default :: ColorStyleValue
				end,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				tag = "size-full-0 auto-y",
				LayoutOrder = 1,
			}),
			ColorPreview({
				color = colorForSwatch,
				showAlpha = false,
				LayoutOrder = 2,
			}),
			VF.ColorPicker({
				initialColor = selectedColor,
				initialMode = ColorInputMode.HSV,
				onColorChanged = function(newColor: Color3)
					selectedColor(newColor)
				end,
				LayoutOrder = 3,
			}),
			VF.Button({
				text = "Submit",
				variant = ButtonVariant.Emphasis,
				isDisabled = function()
					return not hasFullColor()
				end,
				onActivated = function()
					print("Submit color:", selectedColor())
				end,
				LayoutOrder = 4,
			}),
		},
	})
end

return foundation.sections({
	summary = "ColorPicker",
	controls = {
		initialMode = UILabs.Choose(foundation.Dash.values(ColorInputMode :: any)),
		hasAlpha = true,
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "With Preview", story = WithPreviewStory },
		{ name = "Without Alpha", story = WithoutAlphaStory },
		{ name = "With Popover", story = WithPopoverStory },
		{ name = "Properties Panel Spec", story = PropertiesPanelSpecStory },
		{ name = "BrickColor Only", story = BrickColorOnlyStory },
		{ name = "Partial HSV (H only)", story = PartialHSVStory },
	},
})
