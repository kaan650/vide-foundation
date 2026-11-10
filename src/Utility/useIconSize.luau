local IconSize = require("../Enums/IconSize")
local Types = require("../Components/Types")
local Value = require("./Value")
local useTokens = require("../Providers/Style/useTokens")

type IconSize = IconSize.IconSize
type Value<T> = Types.Value<T>

--- The icon's box as a source of UDim2: an IconSize maps to a token size, a number is used as is (Builder Icons only).
local function useIconSize(size: Value<IconSize | number>, isBuilderIcon: boolean, isIconButton: boolean?): () -> UDim2
	local tokens = useTokens()

	return function()
		local resolved = Value.read(size)
		local pixels: number?
		if type(resolved) == "number" then
			pixels = if isBuilderIcon then resolved else nil
		else
			local sizes = tokens().Size
			if isBuilderIcon then
				pixels = ({
					[IconSize.XSmall] = if isIconButton then sizes.Size_400 else sizes.Size_300,
					[IconSize.Small] = if isIconButton then sizes.Size_500 else sizes.Size_400,
					[IconSize.Medium] = if isIconButton then sizes.Size_600 else sizes.Size_500,
					[IconSize.Large] = if isIconButton then sizes.Size_700 else sizes.Size_600,
					[IconSize.XLarge] = if isIconButton then sizes.Size_800 else sizes.Size_700,
					[IconSize.XXLarge] = if isIconButton then sizes.Size_900 else sizes.Size_800,
				} :: { [string]: number })[resolved]
			else
				pixels = ({
					[IconSize.XSmall] = sizes.Size_200,
					[IconSize.Small] = sizes.Size_400,
					[IconSize.Medium] = sizes.Size_900,
					[IconSize.Large] = sizes.Size_1200,
					[IconSize.XLarge] = sizes.Size_2400,
					[IconSize.XXLarge] = 24 * sizes.Size_200,
				} :: { [string]: number })[resolved]
			end
		end
		if pixels == nil then
			error("Invalid icon size: " .. tostring(resolved))
		end
		return UDim2.fromOffset(pixels, pixels)
	end
end

return useIconSize
