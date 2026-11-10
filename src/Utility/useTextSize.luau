local Vide = require("../Packages/Vide")

local Services = require("./Wrappers/Services")
local Types = require("../Components/Types")
local Value = require("./Value")
local usePreferences = require("../Providers/Preferences/usePreferences")

type FontStyle = Types.FontStyle
type Value<T> = Types.Value<T>

local TextService = Services.TextService

--- The size `text` takes in `fontStyle` (whose Font is an Enum.Font), as a source; nil while there is no text.
--- Call it while the component is being created.
local function useTextSize(text: Value<string?>, fontStyle: Value<FontStyle>, frameSize: Value<Vector2?>?): () -> Vector2?
	local preferences = usePreferences()

	return Vide.derive(function(): Vector2?
		local currentText: string? = Value.read(text)
		local style: FontStyle = Value.read(fontStyle)
		local bounds: Vector2? = Value.read(frameSize)
		--* The preferred text size changes how text renders, so it measures again when it changes.
		local _ = preferences().preferredTextSize
		if currentText == nil then
			return nil
		end
		return TextService:GetTextSize(
			currentText,
			style.FontSize :: number,
			style.Font :: any,
			bounds or Vector2.new(math.huge, math.huge)
		)
	end)
end

return useTextSize
