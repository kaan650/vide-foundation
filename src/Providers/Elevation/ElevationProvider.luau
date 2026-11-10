local Vide = require("../../Packages/Vide")

local ElevationLayer = require("../../Enums/ElevationLayer")
local elevation = require("./elevation")
type ElevationLayer = ElevationLayer.ElevationLayer
type Token = elevation.Token

export type Manager = {
	acquire: (layer: ElevationLayer, options: { reserve: boolean, owner: Token? }) -> Token,
	peek: (layer: ElevationLayer) -> number,
	releaseIfTop: (layer: ElevationLayer, index: number) -> (),
}

local ManagerContext = Vide.context(nil :: Manager?)
local OwnerTokenContext = Vide.context(nil :: Token?)

local function createManager(): Manager
	local counters: { [ElevationLayer]: number } = {
		[ElevationLayer.Popover] = 0,
		[ElevationLayer.Drawer] = 0,
		[ElevationLayer.Sheet] = 0,
		[ElevationLayer.Dialog] = 0,
		[ElevationLayer.Notification] = 0,
	}

	return {
		acquire = function(layer: ElevationLayer, options: { reserve: boolean, owner: Token? }): Token
			local spec = elevation.ELEVATION_LAYERS[layer]
			local index = -1
			local zIndex
			local shouldCap = true

			if options.owner then
				zIndex = options.owner.zIndex + 1
				shouldCap = options.owner.zIndex <= spec.finish
			elseif options.reserve then
				local count = counters[layer] or 0
				zIndex = spec.start + (count + 1) * spec.step
				counters[layer] = count + 1
				index = count
			else
				zIndex = spec.start
			end

			if shouldCap and zIndex > spec.finish then
				warn(
					string.format(
						"Layer %q capacity exceeded (%d/%d). Capping zIndex at %d.",
						tostring(layer),
						zIndex,
						spec.finish,
						spec.finish
					)
				)
				zIndex = spec.finish
			end

			return { layer = layer, index = index, zIndex = zIndex }
		end,
		peek = function(layer: ElevationLayer): number
			return counters[layer] or 0
		end,
		releaseIfTop = function(layer: ElevationLayer, index: number)
			local current = counters[layer] or 0
			if index >= 0 and index == current - 1 then
				counters[layer] = current - 1
			end
		end,
	}
end

local function ElevationProvider(props: { children: (() -> any)? })
	return ManagerContext(createManager(), function()
		return if props.children then props.children() else nil
	end)
end

--- Runs `children` with `owner` as the elevation owner, so nested layers stack above it.
local function ElevationOwnerScope(props: { owner: Token?, children: () -> any })
	return OwnerTokenContext(props.owner, props.children)
end

local function useElevationManager(): Manager
	local manager = ManagerContext()
	if not manager then
		error("useElevationManager must be used under ElevationProvider")
	end
	return manager
end

local function useOwnerToken(): Token?
	return OwnerTokenContext()
end

return {
	ElevationProvider = ElevationProvider,
	ElevationOwnerScope = ElevationOwnerScope,
	useElevationManager = useElevationManager,
	useOwnerToken = useOwnerToken,
}
