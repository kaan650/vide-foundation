local foundation = require("../foundation")
local VideFoundation = require("@game/ReplicatedStorage/Packages/VideFoundation")
local VF = foundation.VF
local UILabs = foundation.UILabs

local ChipGroupVariant = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ChipGroupVariant")
local ChipSize = require("@game/ReplicatedStorage/Packages/VideFoundation/Enums/ChipSize")

type ChipGroupItem = VideFoundation.ChipGroupItem

local GENRE_LABELS = {
	"Literary Fiction",
	"Historical Fiction",
	"Science Fiction",
	"Fantasy",
	"Magical Realism",
	"Speculative Fiction",
	"Mystery",
	"Thriller",
	"Crime Fiction",
	"Suspense",
	"Horror",
	"Gothic Fiction",
	"Romance",
	"Contemporary Fiction",
	"Adventure",
	"Western",
	"Dystopian",
	"Utopian",
	"Cyberpunk",
	"Steampunk",
	"Alternate History",
	"Psychological Fiction",
	"Satire",
	"Urban Fiction",
}

local function activated(label: string)
	return function()
		print(`ChipGroup: "{label}" activated`)
	end
end

local chips: { ChipGroupItem } = {}
for index, label in GENRE_LABELS do
	chips[index] = {
		text = label,
		isChecked = index == 1,
		onActivated = activated(label),
	}
end

return foundation.sections({
	summary = "ChipGroup",
	controls = {
		size = UILabs.Choose({ ChipSize.Medium, ChipSize.Small }),
		variant = UILabs.Choose({ ChipGroupVariant.Row, ChipGroupVariant.Wrap }),
	},
	sections = {
		{
			name = "Playground",
			story = function(controls)
				return VF.ChipGroup({
					size = controls.size,
					variant = controls.variant,
					chips = chips,
				})
			end,
		},
		{
			name = "Row",
			story = function()
				return VF.ChipGroup({
					size = ChipSize.Medium,
					variant = ChipGroupVariant.Row,
					chips = chips,
				})
			end,
		},
		{
			name = "Wrap",
			story = function()
				return VF.ChipGroup({
					size = ChipSize.Medium,
					variant = ChipGroupVariant.Wrap,
					chips = chips,
				})
			end,
		},
	},
})
