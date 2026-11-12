local Icon = require("../Icon")
local InputPlatform = require("../../Enums/InputPlatform")
local Text = require("../Text")
local View = require("../View")
local keyDisplay = require("./keyDisplay")
local useShortcutVariants = require("./useShortcutVariants")

type InputPlatform = InputPlatform.InputPlatform
type ShortcutVariantProps = useShortcutVariants.ShortcutVariantProps

type KeyCapProps = {
	keyCode: Enum.KeyCode,
	platform: InputPlatform,
	variantProps: ShortcutVariantProps,
	LayoutOrder: number,
	testId: string,
}

--- One key of a Shortcut: a cap with a glyph or a word, or a bare gamepad glyph. Nil for a key that is not displayed.
local function KeyCap(props: KeyCapProps): GuiObject?
	local variantProps = props.variantProps
	local key = keyDisplay.resolveKey(props.keyCode, props.platform)
	if key == nil then
		return nil
	end

	--* Gamepad glyphs draw without a cap, sized to fill the cap height.
	if key.kind == "GamepadIcon" then
		local glyph = Icon({
			name = key.icon,
			size = variantProps.gamepadIcon.size,
			style = variantProps.gamepadIcon.style,
			testId = `{props.testId}--icon`,
		})
		glyph.Name = "Content"
		return View({
			tag = variantProps.capless.tag,
			LayoutOrder = props.LayoutOrder,
			testId = props.testId,
			children = glyph,
		})
	end

	--* Square cap for one character; longer labels get padding and grow.
	local needsWideCap = key.kind == "Text" and (utf8.len(key.text) or 0) > 1

	local content: GuiObject
	if key.kind == "Icon" then
		content = Icon({
			name = key.icon,
			size = variantProps.icon.size,
			style = variantProps.icon.style,
			testId = `{props.testId}--icon`,
		})
	else
		content = Text({
			Text = key.text,
			tag = variantProps.text.tag,
			testId = `{props.testId}--text`,
		})
	end
	content.Name = "Content"

	return View({
		tag = variantProps.cap.tag,
		--* One size wants 6px here, which is off the padding scale.
		padding = if needsWideCap
			then {
				left = UDim.new(0, variantProps.capWide.padding),
				right = UDim.new(0, variantProps.capWide.padding),
			}
			else nil,
		LayoutOrder = props.LayoutOrder,
		testId = props.testId,
		children = content,
	})
end

return KeyCap
