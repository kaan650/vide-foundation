local Vide = require("../../Packages/Vide")

local ColorNamespace = require("../../Enums/ColorNamespace")
type ColorNamespace = ColorNamespace.ColorNamespace

export type PresentationContextValue = {
	isIconSize: boolean,
	colorNamespace: ColorNamespace,
}

local context = Vide.context({
	isIconSize = false,
	colorNamespace = ColorNamespace.Color,
} :: PresentationContextValue)

local function usePresentationContext(): PresentationContextValue
	return context()
end

return {
	context = context,
	usePresentationContext = usePresentationContext,
}
