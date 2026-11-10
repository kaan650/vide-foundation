local ThumbnailType = require("./ThumbnailType")

-- Kept apart from ThumbnailType so other media types (video) can be added later.
export type MediaType = ThumbnailType.ThumbnailType

return ThumbnailType
