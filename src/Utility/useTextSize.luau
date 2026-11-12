local Vide = require("../Packages/Vide")

local Types = require("../Components/Types")
local Value = require("./Value")
local getTextBoundsAsync = require("./getTextBoundsAsync")
local normalizeFontFace = require("./normalizeFontFace")
local usePreferences = require("../Providers/Preferences/usePreferences")

type FontStyle = Types.FontStyle
type Value<T> = Types.Value<T>

--- The size `text` takes in `fontStyle`, as a source; nil while there is no text or no measurement yet.
--- Measuring yields, so the previous size stays until the new one arrives, as Foundation does.
--- Call it while the component is being created.
local function useTextSize(
	text: Value<string?>,
	fontStyle: Value<FontStyle>,
	frameSize: Value<Vector2?>?
): () -> Vector2?
	local preferences = usePreferences()
	local size: Vide.Source<Vector2?> = Vide.source(nil :: Vector2?)
	local generation = 0

	Vide.effect(function()
		local currentText: string? = Value.read(text)
		local style: FontStyle = Value.read(fontStyle)
		local bounds: Vector2? = Value.read(frameSize)
		--* The preferred text size changes how text renders, so it measures again when it changes.
		local _ = preferences().preferredTextSize
		local font = Value.read(normalizeFontFace(style.Font))
		local fontSize = style.FontSize

		generation += 1
		local current = generation
		if currentText == nil or fontSize == nil or typeof(font) ~= "Font" then
			size(nil)
			return
		end
		task.spawn(function()
			local measured = getTextBoundsAsync(currentText, font, fontSize, if bounds then bounds.X else nil)
			if current == generation then
				size(measured)
			end
		end)
	end)

	Vide.cleanup(function()
		generation += 1
	end)

	return size
end

return useTextSize
