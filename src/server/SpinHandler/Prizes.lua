--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local CEnum = gameDirectory.CEnum
local playerDataManager = gameDirectory.Require("Server.PlayerData")

--/GLOBAL_VARIABLES

local SpinPrizes = {}
local spinRates = {}

--/GLOBAL_FUNCTIONS

local function useCoinGiver(amtCoins: number)
	return function(mainPlayer: Player)
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		return (playerData and playerData:IncrementData("Coins", amtCoins))
	end
end

--/MODULAR_FUNCTIONS

spinRates[1] = {
	Name = "GrappleAbility",
	Weight = 2,
	Function = function(mainPlayer: Player)
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		local abilitiesOwned = (playerData and playerData:GetData("Abilities"))
		if abilitiesOwned and not table.find(abilitiesOwned, "Grapple") then
			return playerData:AppendData("Abilities", "Grapple")
		end
	end,
}

spinRates[2] = {
	Name = "GoldenGloves",
	Weight = 8,
	Function = function(mainPlayer: Player)
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		local gloveSkinsOwned = (playerData and playerData:GetData("GloveSkins"))
		if gloveSkinsOwned and not table.find(gloveSkinsOwned, "GoldGlove") then
			return playerData:AppendData("GloveSkins", "GoldGlove")
		end
	end,
}

spinRates[3] = {
	Name = "2Spins",
	Weight = 10,
	Function = function(mainPlayer: Player)
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		if playerData then
			return playerData:IncrementData("Spins", 2)
		end
	end,
}

spinRates[4] = {
	Name = "Lucky",
	Weight = 12.5,
	Function = function(mainPlayer: Player)
		local gamePassTime: number = 30

		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		return playerData:GiveTemporaryGamepass(CEnum.GamePasses.Lucky, gamePassTime)
	end,
}

spinRates[5] = {
	Name = "150 Coins",
	Weight = 15,
	Function = useCoinGiver(150),
}

spinRates[6] = {
	Name = "80 Coins",
	Weight = 52.5,
	Function = useCoinGiver(80),
}

function SpinPrizes.RollPrize(): (string, () -> ())
	local randomObject = Random.new(os.time())
	local randomNumber: number = randomObject:NextInteger(1, 100)
	local weightCompare: number = 0
	local prizeDataTable = nil
	for _, prize in ipairs(spinRates) do
		weightCompare += prize.Weight
		if randomNumber <= weightCompare then
			prizeDataTable = prize
			break
		end
	end
	return prizeDataTable.Name, prizeDataTable.Function
end

return SpinPrizes
