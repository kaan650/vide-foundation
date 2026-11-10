local PopoverAlign = require("../../Enums/PopoverAlign")
local PopoverSide = require("../../Enums/PopoverSide")

type PopoverSide = PopoverSide.PopoverSide
type PopoverAlign = PopoverAlign.PopoverAlign

local function calculatePopoverBounds(
	side: PopoverSide,
	sideOffset: number,
	alignOffset: number,
	arrowSize: number,
	contentSize: Vector2
): Vector2
	local popoverSize = contentSize
	if side == PopoverSide.Top or side == PopoverSide.Bottom then
		popoverSize += Vector2.new(alignOffset, sideOffset + arrowSize)
	else
		popoverSize += Vector2.new(sideOffset + arrowSize, alignOffset)
	end
	return popoverSize
end

local function isOnScreen(object: Rect, screen: Rect): boolean
	if
		object.Min.X > screen.Max.X
		or object.Max.X < screen.Min.X
		or object.Min.Y > screen.Max.Y
		or object.Max.Y < screen.Min.Y
	then
		return false
	end
	return true
end

--- Flips to the opposite side when the content does not fit on `desiredSide` and fits there.
local function calculateSide(desiredSide: PopoverSide, object: Rect, screen: Rect, popoverSize: Vector2): PopoverSide
	if desiredSide == PopoverSide.Top then
		if object.Min.Y - popoverSize.Y < screen.Min.Y and object.Max.Y + popoverSize.Y < screen.Max.Y then
			return PopoverSide.Bottom
		end
	elseif desiredSide == PopoverSide.Bottom then
		if object.Max.Y + popoverSize.Y > screen.Max.Y and object.Min.Y - popoverSize.Y > screen.Min.Y then
			return PopoverSide.Top
		end
	elseif desiredSide == PopoverSide.Left then
		if object.Min.X - popoverSize.X < screen.Min.X and object.Max.X + popoverSize.X < screen.Max.X then
			return PopoverSide.Right
		end
	elseif desiredSide == PopoverSide.Right then
		if object.Max.X + popoverSize.X > screen.Max.X and object.Min.X - popoverSize.X > screen.Min.X then
			return PopoverSide.Left
		end
	end
	return desiredSide
end

local function calculateAlign(
	side: PopoverSide,
	desiredAlign: PopoverAlign,
	anchor: Rect,
	screen: Rect,
	popoverSize: Vector2
): PopoverAlign
	local isVerticalSide = side == PopoverSide.Top or side == PopoverSide.Bottom

	if isVerticalSide then
		if desiredAlign == PopoverAlign.Start then
			if anchor.Min.X + popoverSize.X > screen.Max.X then
				return PopoverAlign.End
			end
		elseif desiredAlign == PopoverAlign.End then
			if anchor.Max.X - popoverSize.X < screen.Min.X then
				return PopoverAlign.Start
			end
		end
	else
		if desiredAlign == PopoverAlign.Start then
			if anchor.Min.Y + popoverSize.Y > screen.Max.Y then
				return PopoverAlign.End
			end
		elseif desiredAlign == PopoverAlign.End then
			if anchor.Max.Y - popoverSize.Y < screen.Min.Y then
				return PopoverAlign.Start
			end
		end
	end
	return desiredAlign
end

local function adjustForOnScreenKeyboard(screenRect: Rect, keyboardPosition: Vector2, topGuiInset: Vector2): Rect
	--! The engine's keyboard position ignores the top bar and device insets.
	local adjustedKeyboardPosition = keyboardPosition - topGuiInset
	local adjustedMaxY = math.min(screenRect.Max.Y, adjustedKeyboardPosition.Y)
	return Rect.new(screenRect.Min, Vector2.new(screenRect.Max.X, adjustedMaxY))
end

local function calculatePositions(
	side: PopoverSide,
	sideOffset: number,
	align: PopoverAlign,
	alignOffset: number,
	anchor: Rect,
	screen: Rect,
	arrowSize: number,
	contentSize: Vector2
): (Vector2, Vector2, Vector2)
	local pos = { X = 0, Y = 0 }
	local arrow = { X = 0, Y = 0 }
	local anchorPoint = { X = 0, Y = 0 }

	local isVertical = side == PopoverSide.Top or side == PopoverSide.Bottom
	local isTopLeft = side == PopoverSide.Top or side == PopoverSide.Left
	local mainAxis, crossAxis = "X", "Y"
	local anchorSize = anchor.Height
	local mainAxisAnchorStart = anchor.Min.X
	local crossAxisAnchorStart = anchor.Min.Y
	local crossAxisContentSize = contentSize.Y
	local mainAxisContentSize = contentSize.X
	local mainAxisAnchorEnd = anchor.Max.X
	local crossAxisAnchorEnd = anchor.Max.Y
	local crossAxisScreenStart = screen.Min.Y
	local crossAxisScreenEnd = screen.Max.Y
	local mainAxisScreenStart = screen.Min.X
	local mainAxisScreenEnd = screen.Max.X
	if isVertical then
		mainAxis, crossAxis = "Y", "X"
		anchorSize = anchor.Width
		mainAxisAnchorStart = anchor.Min.Y
		crossAxisAnchorStart = anchor.Min.X
		crossAxisContentSize = contentSize.X
		mainAxisContentSize = contentSize.Y
		mainAxisAnchorEnd = anchor.Max.Y
		crossAxisAnchorEnd = anchor.Max.X
		crossAxisScreenStart = screen.Min.X
		crossAxisScreenEnd = screen.Max.X
		mainAxisScreenStart = screen.Min.Y
		mainAxisScreenEnd = screen.Max.Y
	end

	local mainAxisOffset = sideOffset + arrowSize
	if isTopLeft then
		pos[mainAxis] = mainAxisAnchorStart - mainAxisOffset - mainAxisContentSize
		arrow[mainAxis] = mainAxisContentSize
	else -- Bottom or Right
		pos[mainAxis] = mainAxisAnchorEnd + mainAxisOffset
		arrow[mainAxis] = 0
	end

	if align == PopoverAlign.Start then
		pos[crossAxis] = crossAxisAnchorStart + alignOffset
	elseif align == PopoverAlign.Center then
		pos[crossAxis] = crossAxisAnchorStart + anchorSize / 2 - crossAxisContentSize / 2 + alignOffset
	else -- End
		pos[crossAxis] = crossAxisAnchorEnd + -alignOffset
		anchorPoint[crossAxis] = 1
	end

	local crossAxisContentStart = pos[crossAxis] - anchorPoint[crossAxis] * crossAxisContentSize

	local crossAxisContentEnd = crossAxisContentStart + crossAxisContentSize
	if crossAxisContentStart < crossAxisScreenStart then
		anchorPoint[crossAxis] = 0
		pos[crossAxis] = crossAxisScreenStart
	elseif crossAxisContentEnd > crossAxisScreenEnd then
		anchorPoint[crossAxis] = 1
		pos[crossAxis] = crossAxisScreenEnd
	end

	crossAxisContentStart = pos[crossAxis] - anchorPoint[crossAxis] * crossAxisContentSize
	crossAxisContentEnd = crossAxisContentStart + crossAxisContentSize

	local intersectionStart = math.max(crossAxisAnchorStart, crossAxisContentStart)
	local intersectionEnd = math.min(crossAxisAnchorEnd, crossAxisContentEnd)

	local arrowPlacement
	if intersectionStart <= intersectionEnd then
		arrowPlacement = (intersectionStart + intersectionEnd) / 2
	else
		if crossAxisContentEnd < crossAxisAnchorStart then
			arrowPlacement = crossAxisContentEnd - arrowSize
		else
			arrowPlacement = crossAxisContentStart + arrowSize
		end
	end
	arrow[crossAxis] = arrowPlacement - pos[crossAxis]

	--* Foundation keeps the popover on screen even when that covers the anchor.
	pos[mainAxis] = math.clamp(
		pos[mainAxis],
		mainAxisScreenStart,
		math.max(mainAxisScreenEnd - mainAxisContentSize - mainAxisOffset, 0)
	)
	pos.X -= screen.Min.X
	pos.Y -= screen.Min.Y

	return Vector2.new(pos.X, pos.Y), Vector2.new(arrow.X, arrow.Y), Vector2.new(anchorPoint.X, anchorPoint.Y)
end

return {
	adjustForOnScreenKeyboard = adjustForOnScreenKeyboard,
	isOnScreen = isOnScreen,
	calculateSide = calculateSide,
	calculatePositions = calculatePositions,
	calculatePopoverBounds = calculatePopoverBounds,
	calculateAlign = calculateAlign,
}
