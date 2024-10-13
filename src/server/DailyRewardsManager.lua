--/SERVICES

--/TYPES

--/MODULES

local MarketplaceService = game:GetService("MarketplaceService")
local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local CEnum = gameDirectory.CEnum
local playerDataManager = gameDirectory.Require("Server.PlayerData")

local popUpHandlerRemote: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("PopUpHandler").RemoteEvent

--/GLOBAL_VARIABLES

local DailyRewardsManager = {}

local GROUP_ID: number = 33213988

local dailyChestProximityPrompt: ProximityPrompt = workspace.Spawn.DailyChest.PrimaryPart.ProximityPrompt

local vipChestProximityPrompt: ProximityPrompt = workspace.Spawn.VIPChest.PrimaryPart.ProximityPrompt

local vipWallProximityPrompt: ProximityPrompt = workspace.Spawn.VIPblocker.VIPPurchase.ProximityPrompt

local valkGlovesProximityPrompt: ProximityPrompt =
	workspace.Spawn.ValkGloveDisplay.PurchaseBoard.PrimaryPart.ProximityPrompt

--/GLOBAL_FUNCTIONS

--<<Gives player rewards based off of certain conditions
local function useDailyChestGiver(chestName: string, rewardsDataTable: { [string]: number })
	return function(mainPlayer: Player)
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		if mainPlayer:GetRankInGroup(GROUP_ID) > 0 then
			if playerData:CheckClaimPeriodOver(chestName) then
				playerData:SetClaimPeriod(chestName, 24)
				for rewardName: string, rewardAmount: number in next, rewardsDataTable do
					playerData:IncrementData(rewardName, rewardAmount)
				end
				return popUpHandlerRemote:FireClient(mainPlayer, "ShopUpdate", "Sucessfully Claimed Chest!")
			end
			return popUpHandlerRemote:FireClient(
				mainPlayer,
				"GroupNotification",
				"You have already claimed your chest today!"
			)
		end
		return popUpHandlerRemote:FireClient(mainPlayer, "GroupNotification", "Join Group to get access to chest")
	end
end

--/MODULAR_FUNCTIONS

dailyChestProximityPrompt.Triggered:Connect(
	useDailyChestGiver(CEnum.DailyClaimItems.DailyChest, { Coins = 25, Spins = 1 })
)
local vipRewardsGiver: (Player) -> () = useDailyChestGiver(CEnum.DailyClaimItems.VIPChest, { Coins = 100, Spins = 1 })
vipChestProximityPrompt.Triggered:Connect(function(mainPlayer: Player)
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	if playerData:OwnsGamepass(CEnum.GamePasses.VIP.Name) then
		return vipRewardsGiver(mainPlayer)
	end
end)

vipWallProximityPrompt.Triggered:Connect(function(playerWhoTriggered)
	return MarketplaceService:PromptGamePassPurchase(playerWhoTriggered, CEnum.GamePasses.VIP.GamePassID)
end)

valkGlovesProximityPrompt.Triggered:Connect(function(playerWhoTriggered)
	return MarketplaceService:PromptGamePassPurchase(playerWhoTriggered, CEnum.GamePasses.ValkGloves.GamePassID)
end)

return DailyRewardsManager
