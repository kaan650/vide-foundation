local Vide = require("../../Packages/Vide")

local BRICK_COLOR_PALETTES = require("./BrickColorConstants")
local Image = require("../Image")
local StateLayerAffordance = require("../../Enums/StateLayerAffordance")
local Tokens = require("../../Providers/Style/Tokens")
local Types = require("../Types")
local View = require("../View")
local useTokens = require("../../Providers/Style/useTokens")
local withCommonProps = require("../../Utility/withCommonProps")

type Tokens = Tokens.Tokens

export type BrickColorPickerProps = {
	selectedColor: (() -> Color3)?,
	onBrickColorChanged: (brickColor: BrickColor) -> (),
	onColorChanged: ((color: Color3) -> ())?,
} & Types.CommonProps

type HexagonData = {
	brickColor: BrickColor,
	x: number,
	y: number,
}

type GridBounds = {
	width: number,
	height: number,
	offset: Vector2,
}

type Grid = {
	positions: { HexagonData },
	bounds: GridBounds,
}

local HEXAGON_IMAGE = "component_assets/hexagon_24"
local MIN_GRID_RADIUS = 3
local HEXAGON_SPACING = 1

local NO_STATE_LAYER: Types.StateLayer = {
	affordance = StateLayerAffordance.None,
}

local function calculateGridRadius(colorCount: number): number
	for radius = MIN_GRID_RADIUS, 20, 2 do
		local capacity = radius * radius - math.floor(radius / 2) * (math.floor(radius / 2) + 1)
		if capacity > colorCount then
			return radius - 2
		end
	end
	return 7
end

local function getMaxPolygonsInARow(colorCount: number): number
	local radius = calculateGridRadius(colorCount)
	if radius < MIN_GRID_RADIUS then
		warn("BrickColorPicker: Calculated grid radius is too small, falling back to minimum")
		return MIN_GRID_RADIUS
	end
	return radius
end

-- Diamond-shaped hex grid of the MAIN palette; the BOTTOM palette is the separate pill row.
local function buildGrid(tokens: Tokens, colors: { BrickColor }, radius: number): Grid
	local hexagonSize = tokens.Size.Size_200
	local hexagonWidth = tokens.Size.Size_350
	local hexagonHeight = tokens.Size.Size_400

	local positions: { HexagonData } = {}
	local colorIndex = 1
	local horizontalStep = hexagonSize
	local verticalStep = math.round((hexagonSize + HEXAGON_SPACING) * 1.5)

	for row = 0, radius - 1 do
		for col = 0, (2 * radius - 1) - 1 do
			local rowFromCenter = math.abs(math.floor(radius / 2) - row)
			local colFromCenter = math.abs(math.floor((2 * radius - 1) / 2) - col)

			if (rowFromCenter + colFromCenter < radius) and (row % 2 == col % 2) and colorIndex <= #colors then
				table.insert(positions, {
					brickColor = colors[colorIndex],
					x = horizontalStep * col,
					y = verticalStep * row,
				})
				colorIndex += 1
			end
		end
	end

	local minX, maxX = math.huge, -math.huge
	local minY, maxY = math.huge, -math.huge
	for _, pos in positions do
		minX = math.min(minX, pos.x - hexagonWidth / 2)
		maxX = math.max(maxX, pos.x + hexagonWidth / 2)
		minY = math.min(minY, pos.y - hexagonHeight / 2)
		maxY = math.max(maxY, pos.y + hexagonHeight / 2)
	end

	return {
		positions = positions,
		bounds = {
			width = maxX - minX,
			height = maxY - minY,
			offset = Vector2.new(minX, minY),
		},
	}
end

type BottomRowSwatchesProps = {
	colors: { BrickColor },
	paddingHorizontal: () -> number,
	swatchWidth: () -> number,
	swatchHeight: () -> number,
	swatchCenterY: () -> number,
}

--- The evenly spaced grayscale swatches inside the bottom pill, laid out once the pill has a width.
local function BottomRowSwatches(props: BottomRowSwatchesProps): GuiObject
	local containerWidth = Vide.source(0)
	local count = #props.colors

	local function swatchX(index: number): number
		--* Integer math only: avoids sub-pixel misalignment at non-integer DPI scales.
		local paddingHorizontal = props.paddingHorizontal()
		local contentWidth = containerWidth() - 2 * paddingHorizontal
		local swatchStep = math.floor(contentWidth / count)
		local totalUsed = swatchStep * (count - 1)
		local startX = paddingHorizontal + math.floor((contentWidth - totalUsed) / 2)
		return startX + swatchStep * (index - 1)
	end

	local swatches = Vide.show(function()
		return containerWidth() > 0
	end, function()
		local children = {}
		for i, brickColor in props.colors do
			local swatch = Image({
				Size = function()
					return UDim2.fromOffset(props.swatchWidth(), props.swatchHeight())
				end,
				Position = function()
					return UDim2.fromOffset(swatchX(i), props.swatchCenterY())
				end,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = HEXAGON_IMAGE,
				imageStyle = { Color3 = brickColor.Color },
			})
			swatch.Name = `Swatch_{i}`
			table.insert(children, swatch)
		end
		return children
	end)

	local container = View({
		tag = "size-full",
		children = swatches,
	})
	local function measure()
		containerWidth(math.round(container.AbsoluteSize.X))
	end
	measure()
	Vide.cleanup(container:GetPropertyChangedSignal("AbsoluteSize"):Connect(measure))
	return container
end

--- The "Brick" mode grid: the engine's BrickColor palette as a hexagon diamond plus a grayscale pill.
local function BrickColorPicker(props: BrickColorPickerProps): GuiObject
	local tokens = useTokens()

	local allBrickColors = BRICK_COLOR_PALETTES.MAIN
	local bottomRowColors = BRICK_COLOR_PALETTES.BOTTOM
	local maxPolygonsInARow = getMaxPolygonsInARow(#allBrickColors)

	local grid = Vide.derive(function()
		return buildGrid(tokens(), allBrickColors, maxPolygonsInARow)
	end)
	local initialGrid = Vide.untrack(grid)

	-- Nearest-distance matching since hexagons aren't axis-aligned.
	local function onGridActivated(self: GuiObject, inputObject: InputObject)
		if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local current = Vide.untrack(grid)
		local hexagonSize = Vide.untrack(tokens).Size.Size_200
		local closestHexagon: HexagonData? = nil
		local minDistanceSq = math.huge
		local clickX = inputObject.Position.X - self.AbsolutePosition.X + current.bounds.offset.X
		local clickY = inputObject.Position.Y - self.AbsolutePosition.Y + current.bounds.offset.Y

		for _, hexagonData in current.positions do
			local distSq = (clickX - hexagonData.x) ^ 2 + (clickY - hexagonData.y) ^ 2
			if distSq < minDistanceSq then
				minDistanceSq = distSq
				closestHexagon = hexagonData
			end
		end

		if closestHexagon and minDistanceSq < hexagonSize * hexagonSize then
			props.onBrickColorChanged(closestHexagon.brickColor)
			if props.onColorChanged then
				props.onColorChanged(closestHexagon.brickColor.Color)
			end
		end
	end

	local function onBottomRowActivated(self: GuiObject, inputObject: InputObject)
		if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local paddingHorizontal = Vide.untrack(tokens).Size.Size_100
		local relativeX = inputObject.Position.X - self.AbsolutePosition.X
		local contentWidth = self.AbsoluteSize.X - 2 * paddingHorizontal
		local contentX = relativeX - paddingHorizontal

		if contentX >= 0 and contentX <= contentWidth then
			local idx = math.clamp(math.floor(contentX / contentWidth * #bottomRowColors) + 1, 1, #bottomRowColors)
			local brickColor = bottomRowColors[idx]
			props.onBrickColorChanged(brickColor)
			if props.onColorChanged then
				props.onColorChanged(brickColor.Color)
			end
		end
	end

	local selectedColor = props.selectedColor

	local hexagons = {}
	for index, hexagonData in initialGrid.positions do
		local color = hexagonData.brickColor.Color
		local function position(): UDim2
			local current = grid()
			local data = current.positions[index]
			return UDim2.fromOffset(data.x - current.bounds.offset.X, data.y - current.bounds.offset.Y)
		end

		if selectedColor then
			table.insert(
				hexagons,
				Vide.show(function()
					return selectedColor() == color
				end, function()
					local outline = Image({
						Size = function()
							local size = tokens().Size
							return UDim2.fromOffset(size.Size_350 + size.Size_200, size.Size_400 + size.Size_200)
						end,
						Position = position,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Image = HEXAGON_IMAGE,
						imageStyle = function(): Types.ColorStyleValue
							return tokens().Color.ActionEmphasis.Background :: any
						end,
						ZIndex = 1,
					})
					outline.Name = `outline_{index}`
					return outline
				end)
			)
		end

		local hexagon = Image({
			Size = function()
				local size = tokens().Size
				return UDim2.fromOffset(size.Size_350, size.Size_400)
			end,
			Position = position,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = HEXAGON_IMAGE,
			imageStyle = { Color3 = color },
			ZIndex = 2,
		})
		hexagon.Name = `hexagon_{index}`
		table.insert(hexagons, hexagon)
	end

	local colorGrid = View({
		Size = function()
			local bounds = grid().bounds
			return UDim2.fromOffset(bounds.width, bounds.height)
		end,
		LayoutOrder = 1,
		onActivated = onGridActivated,
		stateLayer = NO_STATE_LAYER,
		children = hexagons,
	})
	colorGrid.Name = "ColorGrid"

	local swatches = BottomRowSwatches({
		colors = bottomRowColors,
		paddingHorizontal = function()
			return tokens().Size.Size_100
		end,
		swatchWidth = function()
			return tokens().Size.Size_350
		end,
		swatchHeight = function()
			return tokens().Size.Size_400
		end,
		swatchCenterY = function()
			return tokens().Size.Size_250
		end,
	})
	swatches.Name = "Swatches"

	local bottomRow = View({
		Size = function()
			local size = tokens().Size
			return UDim2.new(1, -size.Size_400, 0, size.Size_500)
		end,
		tag = "stroke-standard stroke-muted radius-circle bg-surface-100",
		LayoutOrder = 2,
		onActivated = onBottomRowActivated,
		stateLayer = NO_STATE_LAYER,
		children = swatches,
	})
	bottomRow.Name = "BottomRow"

	return View(withCommonProps(props, {
		tag = "col align-x-center gap-small size-full-0 auto-y",
		children = { colorGrid, bottomRow },
	}) :: any)
end

return BrickColorPicker
