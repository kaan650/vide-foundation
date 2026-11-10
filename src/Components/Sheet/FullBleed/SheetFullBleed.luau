local Vide = require("../../../Packages/Vide")

local Constants = require("../../../Constants")
local Image = require("../../Image")
local SheetContext = require("../SheetContext")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local create = require("../../../Utility/create")
local withDefaults = require("../../../Utility/withDefaults")

type Value<T> = Types.Value<T>
type AspectRatio = Types.AspectRatio
type ColorStyle = Types.ColorStyle

export type SheetFullBleedProps = {
	media: Value<string>,
	mediaStyle: ColorStyle?,
	backgroundStyle: ColorStyle?,
	height: Value<UDim>?,
	aspectRatio: AspectRatio?,
	-- Keeps the media in the content flow at a fixed size; otherwise it sits behind the content and shrinks as the
	-- content scrolls.
	sticky: boolean?,
	-- Receives the media container.
	ref: ((instance: GuiObject) -> ())?,
	children: Types.Children?,
}

local defaultProps = {
	height = UDim.new(1, 0),
	sticky = false,
}

--- Media across the top of the sheet, edge to edge. Not sticky, it returns a Folder that takes it out of the
--- content's layout; the content leaves a spacer of its height.
local function SheetFullBleed(fullBleedProps: SheetFullBleedProps): Instance
	local props = withDefaults(fullBleedProps, defaultProps)
	local sheet = SheetContext()
	local testId = sheet.testId
	assert(testId, "SheetFullBleed must be used within a Sheet")
	local sticky = props.sticky == true

	sheet.setHasFullBleed(true)
	Vide.cleanup(function()
		sheet.setHasFullBleed(false)
	end)

	Vide.effect(function()
		assert(
			not (sticky and sheet.hasHeader()),
			"Sheet.FullBleed with sticky=true is unsupported when used with Sheet.Header"
		)
	end)

	Vide.cleanup(function()
		sheet.setFullBleedHeight(0)
	end)

	local function imageSize(): UDim2
		local height: UDim = Value.read(props.height)
		return UDim2.new(1, 0, height.Scale, height.Offset)
	end

	local image = Image({
		Image = props.media,
		imageStyle = props.mediaStyle,
		backgroundStyle = props.backgroundStyle,
		aspectRatio = props.aspectRatio,
		tag = function()
			return if sheet.hasRadius() then "radius-top-large" else nil
		end,
		--* Only the shrinking (non-sticky) media is tracked; the content's spacer follows its height.
		onAbsoluteSizeChanged = if not sticky
			then function(rbx: GuiObject)
				sheet.setFullBleedHeight(rbx.AbsoluteSize.Y)
			end
			else nil,
		Size = imageSize,
		ZIndex = 0,
	})
	image.Name = "Image"

	local content: GuiObject? = nil
	if props.children then
		content = View({
			aspectRatio = props.aspectRatio,
			Size = imageSize,
			ZIndex = 2,
			children = props.children,
		})
		content.Name = "Content"
	end

	local fullBleedContent: { GuiObject? } = { image, content }

	local container = View({
		Size = if sticky
			then imageSize
			else function()
				local height = sheet.fullBleedHeight()
				if height == 0 then
					--! Without this the images never get their height set (an engine bug, per Foundation).
					return UDim2.fromScale(1, 1)
				end
				return UDim2.new(1, 0, 0, math.max(0, height - sheet.innerScrollY()))
			end,
		aspectRatio = if sticky then props.aspectRatio else nil,
		LayoutOrder = if sticky then Constants.MIN_LAYOUT_ORDER else nil,
		ClipsDescendants = true,
		ZIndex = 2,
		testId = `{testId}--full-bleed`,
		children = if not sticky and props.aspectRatio
			then (function()
				--* The wrapper shrinks as the content scrolls; this tall view keeps the aspect ratio from shrinking
				--* the media with it.
				local tall = View({
					Size = UDim2.new(1, 0, 0, 9999),
					aspectRatio = props.aspectRatio,
					children = fullBleedContent,
				})
				tall.Name = "Children"
				return tall
			end)()
			else fullBleedContent,
	})
	if props.ref then
		props.ref(container)
	end

	if sticky then
		return container
	end

	container.Name = "FullBleed"
	return create("Folder")({
		Name = "FullBleed",
		container,
	})
end

return SheetFullBleed
