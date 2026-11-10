--* Height-to-width ratio of the widest character, to bound how many characters can fit on one line.
local WIDEST_CHAR_HEIGHT_TO_WIDTH_RATIO = 1.4

local function charAt(text: string, position: number): string
	return text:sub(position, position)
end

--- The text of `textBox` up to the end of the word holding the cursor, to measure how far down the cursor is.
--- TextBox does not expose its line wrapping and GetTextBoundsAsync only measures whole text, so wrapping is
--- estimated by cutting at the next whitespace (see Foundation PR 850).
local function truncateTextToCursor(textBox: TextBox): string
	local cursorPosition = textBox.CursorPosition
	if cursorPosition == -1 then
		return ""
	end

	local text = textBox.Text
	local textHeight = textBox.TextSize * textBox.LineHeight

	local largestCharacterWidth = textHeight / WIDEST_CHAR_HEIGHT_TO_WIDTH_RATIO
	local maxLookAhead = textBox.AbsoluteSize.X / largestCharacterWidth

	local maxLookAheadPosition = cursorPosition + maxLookAhead
	local nextNewline = string.find(text, "\n", cursorPosition) or math.huge
	local nextSpace = string.find(text, "[ \t\f\v]", cursorPosition) or math.huge
	local truncateEnd = math.min(nextNewline - 1, nextSpace, #text)
	local isWithinNewlines = charAt(text, cursorPosition):match("\n")
		and (charAt(text, cursorPosition - 1):match("\n") or cursorPosition == 1)

	if isWithinNewlines then
		truncateEnd = cursorPosition - 1
	elseif truncateEnd > maxLookAheadPosition then
		--* A word longer than a line wraps anywhere, so the cursor position itself is the best estimate.
		truncateEnd = cursorPosition
	end

	return utf8.char(utf8.codepoint(text, 1, truncateEnd))
end

return truncateTextToCursor
