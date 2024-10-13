--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local playerDataManager = gameDirectory.Require("Server.PlayerData")
local remoteFunction: RemoteFunction =
	gameDirectory.RegisterAsReplicatedService("AFKHandler", "RemoteFunction").RemoteFunction

--/GLOBAL_VARIABLES

local AFKHandlerServer = {}

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function remoteFunction.OnServerInvoke(mainPlayer: Player): boolean
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	if playerData then
		local currentAFKState: boolean = playerData:GetAFKState()
		playerData:SetAFKState(not currentAFKState)
		return playerData:GetAFKState()
	end
	return
end

return AFKHandlerServer
