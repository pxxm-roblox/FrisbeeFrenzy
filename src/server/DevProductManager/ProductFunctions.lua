--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local CEnum = gameDirectory.CEnum
local crateHandler = gameDirectory.RequireAsync("Server.CrateHandler")
local playerDataManager = gameDirectory.Require("Server.PlayerData")
local popUpHandlerRemote: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("PopUpHandler").RemoteEvent
local serverUtils = gameDirectory.Require("Server.Utils.General")

--/GLOBAL_VARIABLES

local ProductFunctions = {}

local MINIMUM_PLAYERS_FOR_RESPAWN: number = ReplicatedStorage.Constants.Main.MinimumPlayersRespawn.Value

--/GLOBAL_FUNCTIONS

--<<Appends coins
local function useCoinAppendFunction(amtCoins: number)
	return function(_, mainPlayer)
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		if playerData then
			playerData:IncrementData("Coins", amtCoins)
			return true
		end
		return false
	end
end

--<<Appends spin
local function useSpinAppendFunction(amtSpins: number)
	return function(_, mainPlayer)
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		if playerData then
			playerData:IncrementData("Spins", amtSpins)
			popUpHandlerRemote:FireClient(
				mainPlayer,
				"ShopUpdate",
				("Successfully Purchased %s Spins!"):format(amtSpins)
			)
			return true
		end
		return false
	end
end

--/MODULAR_FUNCTIONS

ProductFunctions[1688414111] = function(_, mainPlayer: Player)
	crateHandler.RollPremiumCrate(mainPlayer)
	return true
end

local oneSpinFunction = useSpinAppendFunction(1)

ProductFunctions[1679325619] = useCoinAppendFunction(25000)
ProductFunctions[1679282891] = useCoinAppendFunction(13500)
ProductFunctions[1685029576] = useCoinAppendFunction(8500)
ProductFunctions[1678014559] = useCoinAppendFunction(2500)
ProductFunctions[1678009687] = useCoinAppendFunction(1000)
ProductFunctions[1678020492] = useCoinAppendFunction(500)
ProductFunctions[1687744363] = oneSpinFunction
ProductFunctions[1687744652] = useSpinAppendFunction(5)
ProductFunctions[1687744487] = function(_, mainPlayer: Player)
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	if playerData then
		playerData:SetClaimPeriod(CEnum.DailyClaimItems.DailyDiscount, 24)
		return oneSpinFunction(_, mainPlayer)
	end
	return false
end

ProductFunctions[CEnum.DevProductIDs.Respawn] = function(_, mainPlayer: Player)
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	if #workspace.InGame:GetChildren() >= MINIMUM_PLAYERS_FOR_RESPAWN then
		serverUtils.SpawnCharacterInGame(mainPlayer.Character)
	else
		playerData:SetData("RespawnSaved", true)
		popUpHandlerRemote:FireClient(
			mainPlayer,
			"ShopUpdate",
			("Less than %d players currently ingame, respawn saved for later use!"):format(MINIMUM_PLAYERS_FOR_RESPAWN),
			1.5
		)
	end
	return true
end

return ProductFunctions
