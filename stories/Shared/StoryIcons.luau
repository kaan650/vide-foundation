local BuilderIcons = require("@game/ReplicatedStorage/Packages/VideFoundation/Packages/BuilderIcons")

local MatrixGrid = require("./MatrixGrid")

local IconName = BuilderIcons.Icon
local migrationLookup: { [string]: { name: string, variant: string } } = BuilderIcons.Migration["uiblox"] :: any

export type StoryIcon = { name: string, title: string, subtitle: string }

local MIGRATED_LEGACY_ICON = "icons/placeholder/placeholderOn_small"

local function formatMigratedLegacySubtitle(legacyPath: string): string
	local mapping = migrationLookup[legacyPath]
	return `{legacyPath} → {mapping.name} ({mapping.variant})`
end

--* One icon per kind an `icon` prop accepts, so a story covers every rendering path: a Builder icon and a migrated
--* UIBlox name render through Icon, a non-migrated UIBlox name through Image.
local ICON_TYPE_EXAMPLES: { StoryIcon } = {
	{
		name = IconName.RobloxPlus,
		title = "Builder icon · Icon component",
		subtitle = IconName.RobloxPlus,
	},
	{
		name = MIGRATED_LEGACY_ICON,
		title = "Migrated legacy string · Icon component",
		subtitle = formatMigratedLegacySubtitle(MIGRATED_LEGACY_ICON),
	},
	{
		name = "icons/menu/clothing/limited_on",
		title = "Non-migrated legacy string · Image component",
		subtitle = "icons/menu/clothing/limited_on",
	},
}

export type BuildIconControlOptionsProps = {
	additional: { string }?,
}

local EMPTY_ICON = ""

--- The options of an `icon` Choose control: no icon, then one icon per kind, then `additional`.
local function buildIconControlOptions(props: BuildIconControlOptionsProps?): { string }
	local options: { string } = { EMPTY_ICON }
	for _, example in ICON_TYPE_EXAMPLES do
		table.insert(options, example.name)
	end
	local additional = if props then props.additional else nil
	if additional then
		for _, name in additional do
			table.insert(options, name)
		end
	end
	return options
end

--- The icon an `icon` control value stands for; nil for the empty option.
local function parseIconControl(controlValue: string): string?
	if controlValue == EMPTY_ICON then
		return nil
	end
	return controlValue
end

--- MatrixGrid rows, one per icon kind, labelled with the kind. Call it inside the story, where `renderCells` can
--- create components.
local function buildIconTypeMatrixRows(renderCells: (iconExample: StoryIcon) -> { any }): { MatrixGrid.MatrixGridRow }
	local rows: { MatrixGrid.MatrixGridRow } = {}
	for _, iconExample in ICON_TYPE_EXAMPLES do
		table.insert(rows, {
			label = MatrixGrid.matrixInfoLabel(iconExample.title, iconExample.subtitle),
			cells = renderCells(iconExample),
		})
	end
	return rows
end

return {
	ICON_TYPE_EXAMPLES = ICON_TYPE_EXAMPLES,
	buildIconControlOptions = buildIconControlOptions,
	buildIconTypeMatrixRows = buildIconTypeMatrixRows,
	parseIconControl = parseIconControl,
}
