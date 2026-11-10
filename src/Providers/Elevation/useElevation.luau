local Vide = require("../../Packages/Vide")

local ElevationLayer = require("../../Enums/ElevationLayer")
local Provider = require("./ElevationProvider")
local elevation = require("./elevation")
type Token = elevation.Token
type ElevationLayer = ElevationLayer.ElevationLayer

type Options = {
	stackAboveOwner: boolean,
}

--- Takes a z-index in `layer` for the life of the calling component.
local function useElevation(layer: ElevationLayer, options: Options): Token
	local manager = Provider.useElevationManager()
	local owner = Provider.useOwnerToken()

	local token: Token
	local isNestedSameLayer = owner ~= nil and owner.layer == layer
	if options.stackAboveOwner then
		if not owner then
			token = manager.acquire(layer, { reserve = false })
		elseif isNestedSameLayer then
			token = manager.acquire(layer, { reserve = true, owner = owner })
		else
			token = { layer = layer, index = -1, zIndex = owner.zIndex + 1 }
		end
	else
		token = manager.acquire(layer, { reserve = isNestedSameLayer })
	end

	Vide.cleanup(function()
		if token.index >= 0 then
			manager.releaseIfTop(layer, token.index)
		end
	end)

	return token
end

return useElevation
