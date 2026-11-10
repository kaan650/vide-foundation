local Vide = require("../../Packages/Vide")

local DialogContext = require("./DialogContext")
local DialogSize = require("../../Enums/DialogSize")
local Types = require("../Types")
local Value = require("../../Utility/Value")
local getResponsiveSize = require("./getResponsiveSize")
local useOverlay = require("../../Providers/Overlay/useOverlay")
local useTokens = require("../../Providers/Style/useTokens")
type DialogSize = DialogSize.DialogSize
type Value<T> = Types.Value<T>

export type DialogProviderProps = {
	size: () -> DialogSize,
	responsiveSize: DialogSize?,
	hasHeroMedia: boolean?,
	children: () -> any,
	testId: string,
}

local function DialogProvider(props: DialogProviderProps)
	local overlay = useOverlay()
	local tokens = useTokens()

	local responsiveSize = Vide.source(Vide.untrack(function(): DialogSize
		local current = overlay()
		if current then
			return getResponsiveSize(current.AbsoluteSize.X, props.size(), tokens())
		end
		return props.responsiveSize or props.size()
	end))
	local hasHeroMedia = Vide.source(props.hasHeroMedia == true)
	local closeAffordance = Vide.source(nil :: GuiObject?)
	local contentStart = Vide.source(nil :: Value<GuiObject?>?)
	local getCloseAffordance: () -> GuiObject? = closeAffordance :: any
	local getContentStart: () -> Value<GuiObject?>? = contentStart :: any

	return DialogContext({
		size = props.size,
		responsiveSize = function()
			return responsiveSize()
		end,
		setResponsiveSize = function(size: DialogSize)
			responsiveSize(size)
		end,
		hasHeroMedia = function()
			return hasHeroMedia()
		end,
		setHasHeroMedia = function(value: boolean)
			hasHeroMedia(value)
		end,
		testId = props.testId,
		closeAffordanceRef = getCloseAffordance,
		setCloseAffordanceRef = function(instance: GuiObject?)
			closeAffordance(instance)
		end,
		contentStartRef = function(): GuiObject?
			return Value.read(getContentStart())
		end,
		setContentStartRef = function(ref: Value<GuiObject?>)
			contentStart(ref)
		end,
	}, props.children)
end

return DialogProvider
