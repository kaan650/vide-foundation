local Vide = require("../../Packages/Vide")

local DialogSize = require("../../Enums/DialogSize")
local getResponsiveSize = require("./getResponsiveSize")
local useDialog = require("./useDialog")
local useOverlay = require("../../Providers/Overlay/useOverlay")
local useTokens = require("../../Providers/Style/useTokens")
type DialogSize = DialogSize.DialogSize

--- Keeps the dialog's responsive size in step with the overlay's width.
local function useDialogResponsiveSize(size: () -> DialogSize)
	local tokens = useTokens()
	local overlay = useOverlay()
	local dialog = useDialog()

	Vide.effect(function()
		local current = overlay()
		if not current then
			return
		end
		local currentSize = size()
		local currentTokens = tokens()

		local function updateSize()
			dialog.setResponsiveSize(getResponsiveSize(current.AbsoluteSize.X, currentSize, currentTokens))
		end

		Vide.untrack(updateSize)
		Vide.cleanup(current:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSize))
	end)
end

return useDialogResponsiveSize
