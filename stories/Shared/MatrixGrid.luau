local foundation = require("../foundation")
local VF = foundation.VF
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")

type ColorStyleValue = VideFoundation.ColorStyleValue

--- One row of a MatrixGrid. `label` and `cells` are Vide children, created inside the story.
export type MatrixGridRow = {
	label: any?,
	cells: { any },
	rowTag: string?,
	backgroundStyle: ColorStyleValue?,
	stroke: {
		Color: Color3?,
		Transparency: number?,
		Thickness: number?,
	}?,
}

export type MatrixGridProps = {
	labelColumnWidth: number?,
	showLabelColumn: boolean?,
	showHeader: boolean?,
	columnHeaders: { string },
	cellColumnWidth: number?,
	cellColumnWidths: { number }?,
	rows: { MatrixGridRow },
	headerTextAlign: ("left" | "center")?,
	cellAlign: ("left" | "center")?,
	rowGap: ("large" | "xxlarge")?,
}

--- A row label for MatrixGrid.
local function matrixLabel(text: string): GuiObject
	return VF.Text({
		Text = text,
		tag = "auto-xy text-caption-small text-align-x-left content-default",
	})
end

--- A two-line row label for MatrixGrid: a title over a muted subtitle.
local function matrixInfoLabel(title: string, subtitle: string): GuiObject
	return VF.View({
		tag = "col gap-xsmall size-full-0 auto-y",
		children = {
			VF.Text({
				Text = title,
				tag = "size-full-0 auto-y text-caption-small text-wrap text-align-x-left content-default",
				LayoutOrder = 1,
			}),
			VF.Text({
				Text = subtitle,
				tag = "size-full-0 auto-y text-caption-small text-wrap text-align-x-left content-muted",
				LayoutOrder = 2,
			}),
		},
	})
end

local function getCellColumnWidth(props: MatrixGridProps, cellIndex: number): number?
	if props.cellColumnWidths then
		return props.cellColumnWidths[cellIndex]
	end
	return props.cellColumnWidth
end

local function renderCells(props: MatrixGridProps, cells: { any }, cellAlignTag: string): { GuiObject }
	local cellChildren = {}
	for index, cell in cells do
		local cellColumnWidth = getCellColumnWidth(props, index)
		cellChildren[index] = VF.View({
			tag = `col auto-xy {cellAlignTag}`,
			Size = if cellColumnWidth then UDim2.fromOffset(cellColumnWidth, 0) else nil,
			LayoutOrder = index,
			children = cell,
		})
	end
	return cellChildren
end

--- A table of examples: column headers, then one row per variant with a label and a cell per column.
local function MatrixGrid(props: MatrixGridProps): GuiObject
	local showLabelColumn = if props.showLabelColumn == nil then true else props.showLabelColumn
	local showHeader = if props.showHeader == nil then true else props.showHeader
	local labelColumnWidth = props.labelColumnWidth or 80
	local headerTextAlign = props.headerTextAlign or "center"
	local cellAlign = props.cellAlign or "center"
	local rowGap = props.rowGap or "large"
	local headerAlignTag = if headerTextAlign == "left" then "text-align-x-left" else "text-align-x-center"
	local cellAlignTag = if cellAlign == "left" then "align-x-left" else "align-x-center"
	local rowTag = `row align-y-center gap-{rowGap} auto-xy`
	local cellRowTag = `row align-y-center gap-{rowGap} auto-x`

	local layoutOrder = 1
	local children = {}

	if showHeader then
		local headerCells = {}
		for index, header in props.columnHeaders do
			local cellColumnWidth = getCellColumnWidth(props, index)
			headerCells[index] = VF.Text({
				Text = header,
				tag = `auto-xy text-caption-small content-muted {headerAlignTag}`,
				Size = if cellColumnWidth then UDim2.fromOffset(cellColumnWidth, 0) else nil,
				LayoutOrder = index,
			})
		end

		table.insert(
			children,
			VF.View({
				tag = `padding-y-small {rowTag}`,
				LayoutOrder = layoutOrder,
				children = if showLabelColumn
					then {
						VF.View({
							Size = UDim2.fromOffset(labelColumnWidth, 0),
							LayoutOrder = 1,
						}),
						VF.View({
							tag = cellRowTag,
							LayoutOrder = 2,
							children = headerCells,
						}),
					}
					else headerCells,
			})
		)
		layoutOrder += 1
	end

	for _, row in props.rows do
		local rowChildren
		if showLabelColumn then
			rowChildren = {
				VF.View({
					tag = "col align-y-center size-full-0 auto-y clip",
					Size = UDim2.fromOffset(labelColumnWidth, 0),
					LayoutOrder = 1,
					children = row.label,
				}),
				VF.View({
					tag = cellRowTag,
					LayoutOrder = 2,
					children = renderCells(props, row.cells, cellAlignTag),
				}),
			}
		else
			rowChildren = renderCells(props, row.cells, cellAlignTag)
		end

		local rowViewTag = if row.rowTag then `{rowTag} {row.rowTag}` else rowTag
		local stroke = row.stroke
		table.insert(
			children,
			VF.View({
				tag = `padding-y-small {rowViewTag}`,
				backgroundStyle = row.backgroundStyle,
				stroke = if stroke
					then {
						Color = stroke.Color,
						Transparency = stroke.Transparency,
						Thickness = stroke.Thickness,
					}
					else nil,
				LayoutOrder = layoutOrder,
				children = rowChildren,
			})
		)
		layoutOrder += 1
	end

	return VF.View({
		tag = "col auto-xy",
		children = children,
	})
end

return {
	MatrixGrid = MatrixGrid,
	matrixLabel = matrixLabel,
	matrixInfoLabel = matrixInfoLabel,
}
