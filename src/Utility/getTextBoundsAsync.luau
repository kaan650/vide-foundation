local Services = require("./Wrappers/Services")
local Types = require("../Components/Types")
local normalizeFontFace = require("./normalizeFontFace")

type FontFaceTable = Types.FontFaceTable
type MeasurableFontFace = Font | Enum.Font | FontFaceTable

local TextService = Services.TextService

--- Measures `text` with TextService:GetTextBoundsAsync. Yields; nil when the font can't be resolved or the call fails.
local function getTextBoundsAsync(text: string, font: MeasurableFontFace, fontSize: number, width: number?): Vector2?
	local normalizedFont = normalizeFontFace(font)
	if typeof(normalizedFont) ~= "Font" then
		return nil
	end

	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = normalizedFont
	params.Size = fontSize
	params.Width = width or math.huge

	local success, result = pcall(function()
		return TextService:GetTextBoundsAsync(params)
	end)
	params:Destroy()

	return if success then result else nil
end

return getTextBoundsAsync
