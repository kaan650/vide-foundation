local Image = require("../../Image")
local Types = require("../../Types")

type FlexItem = Types.FlexItem
type SizeConstraint = Types.SizeConstraint

type CardMediaProps = {
	image: () -> string,
	width: () -> number,
	isEnd: () -> boolean,
	isFillHeight: () -> boolean,
	bottomHeight: () -> number,
	tag: () -> string,
	testId: string,
}

--- The card's image: a fixed-width column at the end, or a full-width strip at the bottom.
local function CardMedia(props: CardMediaProps): GuiObject
	return Image({
		Image = props.image,
		ScaleType = Enum.ScaleType.Crop,
		tag = props.tag,
		Size = function(): UDim2
			return if props.isEnd()
				then UDim2.new(0, props.width(), if props.isFillHeight() then 1 else 0, 0)
				else UDim2.new(1, 0, 0, props.bottomHeight())
		end,
		sizeConstraint = function(): SizeConstraint?
			return if props.isEnd() then { MaxSize = Vector2.new(props.width(), math.huge) } else nil
		end,
		flexItem = function(): FlexItem?
			return if props.isEnd()
				then { FlexMode = Enum.UIFlexMode.Shrink, ItemLineAlignment = Enum.ItemLineAlignment.Stretch }
				else nil
		end,
		LayoutOrder = 2,
		testId = `{props.testId}--image`,
	})
end

return CardMedia
