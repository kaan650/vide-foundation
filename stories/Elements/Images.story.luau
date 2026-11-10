local foundation = require("../foundation")
local FoundationImages = require("@game/ReplicatedStorage/Packages/VideFoundation/Packages/FoundationImages")
local VF = foundation.VF

local Images = FoundationImages.Images

local function ImageGridItem(props: { imageName: string, isVisible: () -> boolean, LayoutOrder: number })
	local imageName = props.imageName

	return VF.View({
		tag = "col align-x-center align-y-center gap-small size-3000-0 auto-y padding-medium radius-medium bg-surface-100",
		Visible = props.isVisible,
		LayoutOrder = props.LayoutOrder,
		children = {
			VF.Image({
				tag = "size-2000-2000",
				Image = imageName,
				LayoutOrder = 1,
			}),
			VF.Text({
				tag = "size-full-0 auto-xy text-caption-large text-wrap content-default",
				Text = imageName:match("([^/]+)$") or imageName,
				LayoutOrder = 2,
			}),
			VF.Text({
				tag = "size-full-0 auto-xy text-caption-small text-wrap content-default",
				Text = imageName,
				LayoutOrder = 3,
			}),
		},
	})
end

local function capitalizeFirstLetter(text: string): string
	return (text:gsub("^%l", string.upper))
end

local function getImagesBySection(): { [string]: { string } }
	local sections: { [string]: { string } } = {}
	for imageName in Images :: { [string]: any } do
		local section = imageName:match("^([^/]+)") or "other"
		if not sections[section] then
			sections[section] = {}
		end
		table.insert(sections[section], imageName)
	end
	for _, imageList in sections do
		table.sort(imageList)
	end
	return sections
end

local function createStoryForSection(sectionName: string, imageList: { string }): foundation.Section
	return {
		name = capitalizeFirstLetter(sectionName),
		story = function(controls)
			local gridItems = {}
			for index, imageName in imageList do
				gridItems[index] = ImageGridItem({
					imageName = imageName,
					--! Matched as plain text: Foundation's pattern match errors on keywords such as "(".
					isVisible = function()
						local keyword: string = controls.keyword()
						return if #keyword > 0 then string.find(imageName, keyword, 1, true) ~= nil else true
					end,
					LayoutOrder = index,
				})
			end

			return foundation.scroll(VF.View({
				tag = "row wrap gap-xlarge size-full-0 auto-y",
				children = gridItems,
			}))
		end,
	}
end

local stories: { foundation.Section } = {}
for sectionName, imageList in getImagesBySection() do
	table.insert(stories, createStoryForSection(sectionName, imageList))
end
table.sort(stories, function(a: foundation.Section, b: foundation.Section)
	return a.name < b.name
end)

return foundation.sections({
	summary = "Foundation Images organized by section",
	controls = {
		keyword = "",
	},
	sections = stories,
})
