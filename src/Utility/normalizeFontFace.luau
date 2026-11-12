local Types = require("../Components/Types")

type FontFace = Types.FontFace
type FontFaceTable = Types.FontFaceTable
type Value<T> = Types.Value<T>

--- A FontFace prop as a `Font` (or the source it already is); nil for `Enum.Font.Unknown`.
local function normalizeFontFace(fontFace: FontFace? | Font): Value<Font>?
	if type(fontFace) == "function" then
		return fontFace :: Value<Font>
	elseif typeof(fontFace) == "table" then
		local fontFaceTable = fontFace :: FontFaceTable
		return Font.new(fontFaceTable.Family, fontFaceTable.Weight, fontFaceTable.Style)
	elseif typeof(fontFace) == "EnumItem" then
		if fontFace == Enum.Font.Unknown then
			return nil
		end
		return Font.fromEnum(fontFace :: Enum.Font)
	end
	return fontFace :: Font?
end

return normalizeFontFace
