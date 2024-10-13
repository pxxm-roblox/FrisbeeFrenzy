local giftFunctions = {}
local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local playerDataManager = gameDirectory.Require("Server.PlayerData")
local CEnum = gameDirectory.CEnum

--<<Global functions

local function useCoinGiver(amtCoins: number)
	return function(mainPlayer: Player)
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		return (playerData and playerData:IncrementData("Coins", amtCoins))
	end
end

local function useSpinGiver(amtSpins: number)
	return function(mainPlayer: Player)
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		return (playerData and playerData:IncrementData("Spins", amtSpins))
	end
end

--<<First gift
giftFunctions[1] = useCoinGiver(10)

giftFunctions[2] = useCoinGiver(15)

giftFunctions[3] = useCoinGiver(20)

giftFunctions[4] = useCoinGiver(25)

giftFunctions[5] = function(mainPlayer: Player)
	local TEMP_TIME: number = 15
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	return (playerData and playerData:GiveTemporaryGamepass(CEnum.GamePasses.x2Coins, TEMP_TIME))
end

giftFunctions[6] = useSpinGiver(1)

giftFunctions[7] = useCoinGiver(45)

giftFunctions[8] = function(mainPlayer: Player)
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	return (
		playerData
		and not playerData:ArrayContainsValue("GloveSkins", "HackerGlove")
		and playerData:AppendData("GloveSkins", "HackerGlove")
	)
end

return giftFunctions
