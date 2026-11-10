local Vide = require("../../Packages/Vide")

local Logger = require("../../Utility/Logger")

export type AddTags = (tags: { string }) -> ()

local warned = false
local function missingProvider(_tags: { string })
	if not warned then
		warned = true
		Logger:warning("No StyleProvider found; Foundation style tags have no rules")
	end
end

return Vide.context(missingProvider :: AddTags)
