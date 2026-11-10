local Vide = require("../../Packages/Vide")

local Types = require("../Types")
type Value<T> = Types.Value<T>

export type TileConfiguration = {
	fillDirection: Value<Enum.FillDirection>,
	isContained: Value<boolean>,
	testId: string?,
}

return Vide.context({
	fillDirection = Enum.FillDirection.Vertical,
	isContained = false,
	testId = "",
} :: TileConfiguration)
