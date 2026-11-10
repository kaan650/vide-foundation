local Vide = require("../../Packages/Vide")

local HeaderBarSlot = require("../../Enums/HeaderBarSlot")
type HeaderBarSlot = HeaderBarSlot.HeaderBarSlot

export type HeaderBarContext = {
	testId: string,
	slot: HeaderBarSlot?,
}

return Vide.context({
	testId = "",
} :: HeaderBarContext)
