local Vide = require("../../Packages/Vide")

local Types = require("../Types")
local Value = require("../../Utility/Value")
local Wrappers = require("../../Utility/Wrappers")
local ContentProvider = Wrappers.Services.ContentProvider

--* Success, Failure and TimedOut are final: an asset only reports again when a higher mip level follows a success.
local function isFinalAssetFetchStatus(status: Enum.AssetFetchStatus): boolean
	return status == Enum.AssetFetchStatus.Success
		or status == Enum.AssetFetchStatus.Failure
		or status == Enum.AssetFetchStatus.TimedOut
end

--- Calls `onLoaded` with the image's final fetch status, again each time the image changes.
local function useOnLoaded(image: Types.Value<string?>?, onLoaded: ((Enum.AssetFetchStatus) -> ())?)
	if not onLoaded then
		return
	end

	Vide.effect(function()
		local uri: string? = Value.read(image)
		if uri == nil then
			return
		end

		local status = ContentProvider:GetAssetFetchStatus(uri)
		if isFinalAssetFetchStatus(status) then
			onLoaded(status)
			return
		end

		local connection: RBXScriptConnection
		connection = ContentProvider:GetAssetFetchStatusChangedSignal(uri):Connect(function(newStatus)
			if isFinalAssetFetchStatus(newStatus) then
				connection:Disconnect()
				onLoaded(newStatus)
			end
		end)
		Vide.cleanup(connection)
	end)
end

return useOnLoaded
