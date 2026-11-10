local Vide = require("../../../Packages/Vide")

local Skeleton = require("../../Skeleton")
local Text = require("../../Text")
local Types = require("../../Types")
local Value = require("../../../Utility/Value")
local View = require("../../View")
local useTextSizeOffset = require("../../../Providers/Style/useTextSizeOffset")
local useTile = require("../useTile")
local useTokens = require("../../../Providers/Style/useTokens")
local withDefaults = require("../../../Utility/withDefaults")

type ColorStyle = Types.ColorStyle
type FontStyle = Types.FontStyle
type Value<T> = Types.Value<T>

export type TileTypography = {
	text: string?,
	-- Shows one line of shimmer instead of the text.
	isLoading: boolean?,
	fontStyle: FontStyle?,
	colorStyle: ColorStyle?,
	numLines: number?,
}

export type TileHeaderProps = {
	title: Value<string | TileTypography>,
	subtitle: Value<(string | TileTypography)?>?,
	TextXAlignment: Value<Enum.TextXAlignment>?,
}

local defaultProps = {
	TextXAlignment = Enum.TextXAlignment.Left,
}

type TypographyDefaults = {
	fontStyle: () -> FontStyle,
	colorStyle: () -> Types.ColorStyleValue,
	numLines: () -> number,
	LayoutOrder: number,
	testId: string,
}

--- The tile's title and subtitle, each a fixed number of lines tall.
local function TileHeader(tileHeaderProps: TileHeaderProps): GuiObject
	local props = withDefaults(tileHeaderProps, defaultProps)
	local tokens = useTokens()
	local textSizeOffset = useTextSizeOffset()
	local tileContext = useTile()

	local function subtitle(): (string | TileTypography)?
		return Value.read(props.subtitle)
	end

	local function typography(value: () -> (string | TileTypography), defaults: TypographyDefaults): any
		local function config(): TileTypography?
			local current = value()
			return if typeof(current) == "table" then current else nil
		end
		local function fontStyle(): FontStyle
			local custom = config()
			local font = table.clone(if custom and custom.fontStyle then custom.fontStyle else defaults.fontStyle())
			--* Foundation forces LineHeight 1 on tile text: the token's line height looks wrong with this font.
			font.LineHeight = 1
			return font
		end
		local function lines(): number
			local custom = config()
			return if custom and custom.numLines then custom.numLines else defaults.numLines()
		end

		return Vide.switch(function()
			local custom = config()
			return custom ~= nil and custom.isLoading == true
		end)({
			[true] = function()
				local skeleton = Skeleton({
					Size = function()
						return UDim2.new(1 / defaults.LayoutOrder, 0, 0, defaults.fontStyle().FontSize or 0)
					end,
					LayoutOrder = defaults.LayoutOrder,
				})
				skeleton.Name = if defaults.LayoutOrder == 1 then "Title" else "Subtitle"
				return skeleton
			end,
			[false] = function()
				local text = Text({
					fontStyle = fontStyle,
					textStyle = function(): Types.ColorStyleValue
						local custom = config()
						return Value.read(if custom and custom.colorStyle then custom.colorStyle else nil)
							or defaults.colorStyle()
					end,
					Text = function()
						local current = value()
						return if typeof(current) == "string" then current else current.text or ""
					end,
					TextXAlignment = props.TextXAlignment,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextWrapped = function()
						return lines() > 1
					end,
					Size = function()
						local font = fontStyle()
						local height = lines() * ((font.FontSize or 0) + textSizeOffset()) * (font.LineHeight or 1)
						return UDim2.new(1, 0, 0, height)
					end,
					LayoutOrder = defaults.LayoutOrder,
					testId = defaults.testId,
				})
				text.Name = if defaults.LayoutOrder == 1 then "Title" else "Subtitle"
				return text
			end,
		})
	end

	local title = typography(function()
		return Value.read(props.title)
	end, {
		fontStyle = function()
			return tokens().Typography.TitleLarge :: any
		end,
		colorStyle = function()
			return tokens().Color.Content.Emphasis :: any
		end,
		numLines = function()
			return if subtitle() == nil then 2 else 1
		end,
		LayoutOrder = 1,
		testId = `{tileContext.testId}--header-title`,
	})

	local subtitleText = Vide.show(subtitle, function(current: () -> string | TileTypography)
		return typography(current, {
			fontStyle = function()
				return tokens().Typography.CaptionLarge :: any
			end,
			colorStyle = function()
				return tokens().Color.Content.Default :: any
			end,
			numLines = function()
				return 1
			end,
			LayoutOrder = 2,
			testId = `{tileContext.testId}--header-subtitle`,
		})
	end)

	return View({
		flexItem = {
			FlexMode = Enum.UIFlexMode.Shrink,
		},
		layout = {
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		tag = "gap-xxsmall size-full-0 auto-y",
		testId = `{tileContext.testId}--header`,
		children = { title, subtitleText },
	})
end

return TileHeader
