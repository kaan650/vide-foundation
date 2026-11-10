local Vide = require("../../Packages/Vide")

local InputPlacement = require("../../Enums/InputPlacement")
local InputSize = require("../../Enums/InputSize")

type InputPlacement = InputPlacement.InputPlacement
type InputSize = InputSize.InputSize

export type InputGroupConfiguration = {
	size: InputSize?,
	placement: InputPlacement?,
}

return Vide.context({
	size = nil,
	placement = nil,
} :: InputGroupConfiguration)
