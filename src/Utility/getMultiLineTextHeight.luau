local FontScales = require("../Components/Text/FontScales")

--- The height of `lineCount` lines of Builder Sans text, as Foundation's text inputs size their TextBox.
local function getMultiLineTextHeight(fontSize: number, lineCount: number, lineHeight: number): number
	if fontSize <= 0 or lineCount <= 0 then
		return 0
	end

	--* Line heights below 1 are not supported.
	if lineHeight <= 1 then
		lineHeight = 1
	end

	fontSize = math.floor(fontSize)

	local paddingOffset = 0
	local nominalScale = FontScales[Font.fromEnum(Enum.Font.BuilderSans).Family]
	if nominalScale ~= nil then
		local rawTextSize = fontSize / nominalScale
		local rawLineHeight = lineHeight * nominalScale
		paddingOffset = (rawTextSize * rawLineHeight - fontSize) / 2
	end

	local multiLineHeight = math.ceil((lineCount - 1) * lineHeight * fontSize)
	--! TextBoxes clip their text unless they are 1 or 2 pixels taller than the plain text height.
	local roundedPadding = if paddingOffset >= 1 then math.ceil(paddingOffset) else math.floor(paddingOffset)

	return multiLineHeight + fontSize + roundedPadding
end

return getMultiLineTextHeight
