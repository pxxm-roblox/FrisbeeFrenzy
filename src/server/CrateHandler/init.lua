--/SERVICES

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local crateObject = require(script.CrateObject)

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local CEnum = gameDirectory.CEnum
local playerDataManager = gameDirectory.Require("Server.PlayerData")
local popUpRemote: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("PopUpHandler").RemoteEvent

--/GLOBAL_VARIABLES

local CrateHandlerModule = {}

local CrateClaimRequests: { [Player]: () -> () } = {}
local normalChest: Model = workspace.Spawn.NormalChest
local normalProximityPrompt: ProximityPrompt = normalChest.PrimaryPart.ProximityPrompt
local premiumProximityPrompt: ProximityPrompt = workspace.Spawn.PremiumChest.PrimaryPart.ProximityPrompt
local crateRollRemote: RemoteEvent = gameDirectory.RegisterAsReplicatedService("CrateRoller", "RemoteEvent").RemoteEvent

local crateData = {
	Normal = {
		CrateObject = crateObject.new(ReplicatedStorage.Constants.Crates.Normal),
		CoinsRefund = 15,
		Price = {
			Type = "Coins",
			Value = 80,
		},
	},
	Premium = {
		CrateObject = crateObject.new(ReplicatedStorage.Constants.Crates.Premium),
		CoinsRefund = 100,
		Price = {
			Type = "Robux",
		},
	},
}

--/GLOBAL_FUNCTIONS

--<<Calls crate claim function if it exists
local function claimCrateRoll(playerData)
	local indexedFunction: ({}) -> () = CrateClaimRequests[playerData:GetPlayer()]
	if indexedFunction then
		CrateClaimRequests[playerData:GetPlayer()] = nil
		return indexedFunction(playerData)
	end
end

--<<Checks if player has enough value to purchase
local function checkIfPlayerHasEnoughMonetaryValue(mainPlayer: Player, price): boolean
	if price.Type == "Coins" then
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		if playerData:GetData("Coins") >= price.Value then
			playerData:IncrementData("Coins", -price.Value)
			return true
		end
		popUpRemote:FireClient(mainPlayer, "HandleCoinSectionChange")
	elseif price.Type == "Robux" then
		return true
	end
	return false
end

--<<Returns a function that when called will give the player the glove skin
local function useGloveSkinGiver(gloveName: string)
	return function(playerData)
		playerData:AppendData("GloveSkins", gloveName)
	end
end

--<<Returns a function that gives amt coins when called
local function useCoinsGiver(amt: number)
	return function(playerData)
		playerData:IncrementData("Coins", amt)
	end
end

--<<Rolls a glove for the player if duplicate returns coins
local function useGloveRoller(typeCrate: string)
	local selectedCrateData = crateData[typeCrate]
	return function(mainPlayer: Player)
		if checkIfPlayerHasEnoughMonetaryValue(mainPlayer, selectedCrateData.Price) then
			local playerData = playerDataManager.GetPlayerData(mainPlayer)
			local gloveRoled: Model =
				selectedCrateData.CrateObject:RollGlove(playerData:OwnsGamepass(CEnum.GamePasses.Lucky.Name))
			local glovesOwned: { string } = playerData:GetData("GloveSkins")
			if not table.find(glovesOwned, gloveRoled.Name) then
				CrateClaimRequests[mainPlayer] = useGloveSkinGiver(gloveRoled.Name)
			else
				CrateClaimRequests[mainPlayer] = useCoinsGiver(selectedCrateData.CoinsRefund)
			end
			return crateRollRemote:FireClient(mainPlayer, {
				Glove = gloveRoled,
				Crate = typeCrate,
			})
		end
	end
end

--/MODULAR_FUNCTIONS

normalProximityPrompt.Triggered:Connect(useGloveRoller("Normal"))

premiumProximityPrompt.Triggered:Connect(function(mainPlayer: Player)
	return MarketplaceService:PromptProductPurchase(mainPlayer, 1688414111)
end)

local premiumCrate = useGloveRoller("Premium")
function CrateHandlerModule.RollPremiumCrate(mainPlayer: Player)
	return premiumCrate(mainPlayer)
end

crateRollRemote.OnServerEvent:Connect(function(mainPlayer: Player)
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	return claimCrateRoll(playerData)
end)

playerDataManager.OnProfileRelease(claimCrateRoll)

return CrateHandlerModule
