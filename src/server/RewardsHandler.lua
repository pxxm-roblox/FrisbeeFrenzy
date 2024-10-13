--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local playerDataManager = gameDirectory.Require("Server.PlayerData")
local popUpHandlerRemote: RemoteEvent =
	gameDirectory.RegisterAsReplicatedService("PopUpHandler", "RemoteEvent").RemoteEvent
local generalUtilities = gameDirectory.Require("Server.Utils.General")

local AMT_COINS_PER_KILL: number = ReplicatedStorage.Constants.Rewards.KillCoins.Value

--/GLOBAL_VARIABLES

local RewardsHandler = {}

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function RewardsHandler.RewardKill(mainChar: Model, enemyChar: Model)
	local mainPlayer: Player? = game.Players:GetPlayerFromCharacter(mainChar)
	if mainPlayer then
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		playerData:IncrementData("Kills", 1)
		playerData:IncrementData("Coins", generalUtilities.AccountForx2Coins(mainPlayer, AMT_COINS_PER_KILL))
		return popUpHandlerRemote:FireClient(mainPlayer, "Kill", enemyChar.Name)
	end
end

return RewardsHandler
