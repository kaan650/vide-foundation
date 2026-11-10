local foundation = require("../foundation")
local FoundationCloudAssets = require("@game/ReplicatedStorage/Packages/VideFoundation/Packages/FoundationCloudAssets")
local getRbxThumb = require("@game/ReplicatedStorage/Packages/VideFoundation/Utility/getRbxThumb")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local Vide = foundation.Vide
local Dash = foundation.Dash

local AssetService = game:GetService("AssetService")

local ControlState = VF.Enums.ControlState
local ThumbnailSize = VF.Enums.ThumbnailSize
local ThumbnailType = VF.Enums.ThumbnailType

type ColorStyleValue = VideFoundation.ColorStyleValue

local RING_COLORS = {
	{ 255, 91, 184 },
	{ 84, 220, 255 },
	{ 255, 218, 92 },
}

local function drawRingFrame(image: EditableImage, center: Vector2?, progress: number?)
	local size = image.Size
	local pixelsBuffer = image:ReadPixelsBuffer(Vector2.zero, size)
	local maxRadius = if center
		then math.max(
			(center - Vector2.zero).Magnitude,
			(center - Vector2.new(size.X, 0)).Magnitude,
			(center - Vector2.new(0, size.Y)).Magnitude,
			(center - size).Magnitude
		) + (#RING_COLORS - 1) * 18 + 4
		else 0

	for y = 0, size.Y - 1 do
		for x = 0, size.X - 1 do
			local index = (y * size.X + x) * 4
			local r, g, b, a = 0, 0, 0, 0

			if center and progress then
				local distance = (Vector2.new(x, y) - center).Magnitude
				for ringIndex = 0, #RING_COLORS - 1 do
					local radius = progress * maxRadius - ringIndex * 18
					if radius >= 0 and math.abs(distance - radius) < 3 then
						local color = RING_COLORS[ringIndex + 1]
						r, g, b = color[1], color[2], color[3]
						a = 255
						break
					end
				end
			end

			buffer.writeu8(pixelsBuffer, index, r)
			buffer.writeu8(pixelsBuffer, index + 1, g)
			buffer.writeu8(pixelsBuffer, index + 2, b)
			buffer.writeu8(pixelsBuffer, index + 3, a)
		end
	end

	image:WritePixelsBuffer(Vector2.zero, size, pixelsBuffer)
end

local function createEditableImage(size: Vector2): EditableImage?
	local success, editableImage = pcall(function()
		return AssetService:CreateEditableImage({ Size = size })
	end)
	if not success or editableImage == nil then
		return nil
	end
	drawRingFrame(editableImage, nil, nil)
	return editableImage
end

local function AssetStory()
	local tokens = VF.Hooks.useTokens()

	return VF.View({
		backgroundStyle = { Transparency = 0.5 },
		tag = "col gap-large auto-xy padding-small",
		children = {
			VF.Image({
				ImageContent = Content.fromAssetId(7229442422),
				backgroundStyle = function(): ColorStyleValue
					return tokens().Color.Extended.White.White_100 :: ColorStyleValue
				end,
				tag = "size-2800",
				LayoutOrder = 1,
			}),
			VF.Image({
				Image = "component_assets/circle_22_stroke_3",
				slice = {
					center = Rect.new(11, 11, 12, 12),
				},
				backgroundStyle = function(): ColorStyleValue
					return tokens().Color.Extended.White.White_0 :: ColorStyleValue
				end,
				tag = "col align-x-center align-y-center size-2800-800",
				LayoutOrder = 2,
				children = VF.Text({
					Text = "Slice Center",
					AutomaticSize = Enum.AutomaticSize.XY,
					textStyle = function(): ColorStyleValue
						return tokens().Color.Content.Emphasis :: ColorStyleValue
					end,
				}),
			}),
		},
	})
end

local THUMBNAIL_BY_STATE: { [string]: number } = {
	[ControlState.Default] = 23155839,
	[ControlState.Hover] = 23155842,
	[ControlState.Pressed] = 23155847,
}

local function StoryGuiState()
	local guiState = Vide.source(ControlState.Initialize :: string)
	local tokens = VF.Hooks.useTokens()

	return VF.Image({
		ImageContent = function()
			local assetId = THUMBNAIL_BY_STATE[guiState()] or 23155833
			return Content.fromUri(getRbxThumb(ThumbnailType.Asset, assetId, ThumbnailSize.Large))
		end,
		backgroundStyle = function(): ColorStyleValue
			return tokens().Color.Extended.Purple.Purple_500 :: ColorStyleValue
		end,
		tag = "col align-x-center align-y-center size-2800",
		onStateChanged = function(new)
			guiState(new)
		end,
	})
end

local function ImageSliceWithChildren()
	local tokens = VF.Hooks.useTokens()

	local function speakerImage(props: {
		name: string,
		image: string,
		size: number,
		style: () -> ColorStyleValue,
		scale: number?,
		ZIndex: number,
	})
		local image = VF.Image({
			tag = "position-center-center anchor-center-center",
			Image = props.image,
			Size = UDim2.fromOffset(props.size, props.size),
			scale = props.scale,
			imageStyle = props.style,
			ZIndex = props.ZIndex,
		})
		image.Name = props.name
		return image
	end

	local function noColor(): ColorStyleValue
		return tokens().Color.None :: ColorStyleValue
	end

	return VF.Image({
		tag = "auto-xy",
		slice = {
			center = Rect.new(52, 24, 66, 32),
			scale = 1,
		},
		backgroundStyle = { Transparency = 1 },
		ImageContent = Content.fromAssetId(78323814447735),
		ScaleType = Enum.ScaleType.Slice,
		children = VF.View({
			tag = "gap-large auto-xy",
			padding = {
				top = UDim.new(0, 30),
				bottom = UDim.new(0, 40),
				left = UDim.new(0, 64),
				right = UDim.new(0, 32),
			},
			children = VF.View({
				tag = "size-1500",
				LayoutOrder = 1,
				children = {
					speakerImage({
						name = "Outer",
						image = "component_assets/circle_36",
						size = 60,
						style = noColor,
						ZIndex = 0,
					}),
					speakerImage({
						name = "Inner",
						image = "component_assets/circle_36",
						size = 60,
						scale = 1,
						style = noColor,
						ZIndex = 1,
					}),
					speakerImage({
						name = "SpeakerIcon",
						image = "icons/controls/speaker",
						size = 32,
						style = function(): ColorStyleValue
							return tokens().Color.Extended.Gray.Gray_300 :: ColorStyleValue
						end,
						ZIndex = 2,
					}),
				},
			}),
		}),
	})
end

local function LabeledImage(props: { label: string, image: string | () -> string, LayoutOrder: number })
	return VF.View({
		tag = "col gap-small auto-xy",
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Text({
				Text = props.label,
				tag = "self-center text-body-small text-align-x-center content-emphasis",
				AutomaticSize = Enum.AutomaticSize.XY,
				LayoutOrder = 1,
			}),
			VF.Image({
				Image = props.image,
				tag = "size-2800 content-emphasis",
				LayoutOrder = 2,
			}),
		},
	})
end

local function PlaygroundStory(controls: { [string]: any })
	return VF.View({
		tag = "row align-y-top gap-xlarge auto-xy",
		children = {
			LabeledImage({ label = "image", image = controls.image, LayoutOrder = 1 }),
			LabeledImage({ label = "cloudAsset", image = controls.cloudAsset, LayoutOrder = 2 }),
		},
	})
end

local function BasicImageStory()
	local function column(label: string, image: string | () -> string, layoutOrder: number)
		return VF.View({
			tag = "col gap-small auto-xy",
			LayoutOrder = layoutOrder,
			children = {
				VF.Text({
					tag = "self-center text-body-small text-align-x-center content-emphasis",
					Text = label,
					AutomaticSize = Enum.AutomaticSize.XY,
					LayoutOrder = 1,
				}),
				VF.Image({
					Image = image,
					tag = "size-2800",
					LayoutOrder = 2,
				}),
			},
		})
	end

	return VF.View({
		tag = "row gap-xlarge auto-xy",
		children = {
			column("No Image binding", "icons/graphic/success_xlarge", 1),
			column("With Image binding", Vide.source("icons/graphic/success_xlarge"), 2),
		},
	})
end

local function InteractiveEditableImageStory()
	local editableImage = createEditableImage(Vector2.new(128, 128))
	local animationId = 0

	Vide.cleanup(function()
		animationId += 1
		if editableImage then
			editableImage:Destroy()
		end
	end)

	local function onActivated(guiObject: GuiObject, inputObject: InputObject)
		local image = editableImage
		if not image then
			return
		end

		local inputPosition = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
		local relativePosition = inputPosition - guiObject.AbsolutePosition
		local absoluteSize = guiObject.AbsoluteSize
		local center = Vector2.new(
			relativePosition.X / math.max(absoluteSize.X, 1) * image.Size.X,
			relativePosition.Y / math.max(absoluteSize.Y, 1) * image.Size.Y
		)

		animationId += 1
		local currentAnimationId = animationId
		task.spawn(function()
			for frame = 0, 24 do
				if animationId ~= currentAnimationId then
					return
				end
				drawRingFrame(image, center, frame / 24)
				for _ = 0, 5 do
					task.wait()
				end
			end
		end)
	end

	return VF.View({
		tag = "col align-x-center gap-small auto-xy",
		children = {
			VF.Text({
				Text = "Click for EditableImage rings",
				tag = "auto-xy text-body-small content-emphasis",
				LayoutOrder = 1,
			}),
			if editableImage
				then VF.Image({
					ImageContent = Content.fromObject(editableImage),
					tag = "bg-surface-100",
					Size = UDim2.fromOffset(360, 360),
					ScaleType = Enum.ScaleType.Stretch,
					LayoutOrder = 2,
					onActivated = onActivated,
				})
				else VF.Text({
					Text = "EditableImage unavailable in this environment",
					tag = "size-2800-800 text-caption-small text-wrap text-align-x-center content-default",
					LayoutOrder = 2,
				}),
		},
	})
end

return foundation.sections({
	summary = "Image",
	controls = {
		image = foundation.UILabs.Choose({
			"icons/graphic/success_xlarge",
			"icons/status/oof_xlarge",
			"component_assets/circle_22_stroke_3",
		}),
		cloudAsset = foundation.UILabs.Choose(Dash.keys(FoundationCloudAssets.Assets :: any)),
	},
	sections = {
		{ name = "Playground", story = PlaygroundStory },
		{ name = "Basic Image", story = BasicImageStory },
		{ name = "Basic Asset Use", story = AssetStory },
		{ name = "GUI State Use", story = StoryGuiState },
		{ name = "Custom 9-slice Image", story = ImageSliceWithChildren },
		{ name = "Interactive EditableImage", story = InteractiveEditableImageStory },
	},
})
