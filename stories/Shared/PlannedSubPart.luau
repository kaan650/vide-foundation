local foundation = require("../foundation")
local VF = foundation.VF

--- The placeholder Foundation shows for a compound component's part (Popover.Anchor, Sheet.Header...) whose
--- documentation is not written yet: its name and a status message.
local function PlannedSubPart(props: { name: string })
	return VF.View({
		tag = "col align-x-center align-y-center gap-small size-full auto-xy padding-large",
		children = {
			VF.Text({
				Text = props.name,
				tag = "auto-xy text-title-medium text-align-x-center content-emphasis",
				LayoutOrder = 1,
			}),
			VF.Text({
				Text = "Documentation in progress — check back soon.",
				tag = "size-full-0 auto-y text-body-medium text-wrap text-align-x-center content-muted",
				LayoutOrder = 2,
			}),
		},
	})
end

--- The story module of such a part: Foundation's summary and a Playground section with the placeholder.
local function story(name: string)
	return foundation.sections({
		summary = `{name} documentation is in progress.`,
		sections = {
			{
				name = "Playground",
				story = function()
					return PlannedSubPart({ name = name })
				end,
			},
		},
	})
end

return {
	PlannedSubPart = PlannedSubPart,
	story = story,
}
