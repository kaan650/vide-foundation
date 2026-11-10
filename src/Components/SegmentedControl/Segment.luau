local Vide = require("../../Packages/Vide")

local BuilderIcons = require("../../Packages/BuilderIcons")

local Icon = require("../Icon")
local InputSize = require("../../Enums/InputSize")
local Text = require("../Text")
local Types = require("../Types")
local View = require("../View")
local useSegmentedControlVariants = require("./useSegmentedControlVariants")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")

type InputSize = InputSize.InputSize

export type SegmentIcon = string | {
	name: string,
	variant: BuilderIcons.IconVariant?,
}

export type Segment = {
	id: Types.ItemId,
	-- `text` and `icon` are mutually exclusive.
	text: string?,
	icon: SegmentIcon?,
	-- Receives the segment's instance.
	ref: ((GuiObject) -> ())?,
}

type SegmentProps = {
	segment: () -> Segment,
	onActivated: (id: Types.ItemId) -> (),
	size: () -> InputSize,
	isCircular: () -> boolean?,
} & Types.CommonProps

local function Segment(props: SegmentProps): GuiObject
	local tokens = useTokens()
	local variantProps = Vide.derive(function()
		return useSegmentedControlVariants(tokens(), props.size(), props.isCircular())
	end)

	local function isIcon(): boolean
		return props.segment().icon ~= nil
	end

	local content = Vide.switch(isIcon)({
		[true] = function()
			local icon = Icon({
				name = function()
					local current = props.segment().icon
					return if type(current) == "table" then current.name else current :: string
				end,
				variant = function(): BuilderIcons.IconVariant?
					local current = props.segment().icon
					return if type(current) == "table" then current.variant else nil
				end :: any,
				size = function()
					return variantProps().icon.size
				end,
				style = function()
					return variantProps().icon.style
				end,
			})
			icon.Name = "Text"
			return icon
		end,
		[false] = function()
			local text = Text({
				tag = function()
					return variantProps().text.tag
				end,
				Text = function()
					return props.segment().text or ""
				end,
			})
			text.Name = "Text"
			return text
		end,
	})

	local view = View(withCommonProps(props, {
		tag = function()
			return variantProps().segment.tag
		end,
		onActivated = function()
			props.onActivated(Vide.untrack(props.segment).id)
		end,
		children = content,
	}) :: any)
	view.Name = "Segment"
	return view
end

return Segment
