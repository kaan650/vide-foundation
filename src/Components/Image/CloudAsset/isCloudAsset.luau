
local FoundationCloudAssets: { [string]: any } = require("../../../Packages/FoundationCloudAssets").Assets :: any

return function(img: string): boolean
	return FoundationCloudAssets[img] ~= nil
end
