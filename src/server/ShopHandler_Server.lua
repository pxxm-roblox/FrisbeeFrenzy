--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local playerDataManager = gameDirectory.Require("Server.PlayerData")
local globalFunctions = gameDirectory.GlobalFunctions
local serverUtils = gameDirectory.Require("Server.Utils.General")
local CEnum = gameDirectory.CEnum
local remoteFunction: RemoteFunction =
	gameDirectory.RegisterAsReplicatedService("ShopUIHandler", "RemoteFunction").RemoteFunction
local popUpHandlerRemote: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("PopUpHandler").RemoteEvent

--/GLOBAL_VARIABLES

local ShopHandler_Server = {}
local Coin_IDs = {
	["25k"] = 1679325619,
	["13.5k"] = 1679282891,
	["8.5k"] = 1685029576,
	["2.5k"] = 1678014559,
	["1k"] = 1678009687,
	["500"] = 1678020492,
}

local Spin_Data = {
	SpinCoins = 3000,
	["1Spin"] = 1687744363,
	["5Spins"] = 1687744652,
	DailyDiscount = 1687744487,
}

local MINIMUM_PLAYERS_FOR_RESPAWN: number = ReplicatedStorage.Constants.Main.MinimumPlayersRespawn.Value

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function ShopHandler_Server.GamePass(mainPlayer: Player, gamePassName: string)
	local gamePassData = CEnum.GamePasses[gamePassName]
	if gamePassData then
		return MarketplaceService:PromptGamePassPurchase(mainPlayer, gamePassData.GamePassID)
	end
end

function ShopHandler_Server.Spins(mainPlayer: Player, spinProduct: string)
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	if spinProduct == "SpinCoins" then
		if playerData:GetData("Coins") >= Spin_Data.SpinCoins then
			if playerData:GetData(CEnum.ClaimItems.SpinsBoughtWithCoins) < 3 then
				playerData:IncrementData("Coins", -Spin_Data.SpinCoins)
				playerData:IncrementData("Spins", 1)
				playerData:IncrementData("SpinsBoughtWithCoins", 1)
				if playerData:GetData(CEnum.ClaimItems.SpinsBoughtWithCoins) >= 3 then
					playerData:SetClaimPeriod(CEnum.ClaimItems.SpinsBoughtWithCoins, 24)
				end
				return popUpHandlerRemote:FireClient(
					mainPlayer,
					"ShopUpdate",
					("Successfully Purchased %s Spins!"):format(Spin_Data.SpinCoins)
				)
			end
		end
		popUpHandlerRemote:FireClient(mainPlayer, "HandleCoinSectionChange")
	elseif spinProduct == "DailyDiscount" then
		if playerData:CheckClaimPeriodOver(CEnum.DailyClaimItems.DailyDiscount) then
			return MarketplaceService:PromptProductPurchase(mainPlayer, Spin_Data.DailyDiscount)
		end
	else
		return MarketplaceService:PromptProductPurchase(mainPlayer, Spin_Data[spinProduct])
	end
end

function ShopHandler_Server.Coin(mainPlayer: Player, amtCoins: string)
	MarketplaceService:PromptProductPurchase(mainPlayer, Coin_IDs[amtCoins])
	return true
end

function ShopHandler_Server.Glove(mainPlayer: Player, gloveName: string)
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	local equippedGlove: string = playerData:GetData("EquippedGloveSkin")
	local glovesOwned: { string } = playerData:GetData("GloveSkins")
	if equippedGlove ~= gloveName and table.find(glovesOwned, gloveName) then
		playerData:SetData("EquippedGloveSkin", gloveName)
		globalFunctions.WeldEquippedGloves(
			mainPlayer.Character,
			ReplicatedStorage.Gloves:FindFirstChild(gloveName, true)
		)
		popUpHandlerRemote:FireClient(mainPlayer, "ShopUpdate", ("Sucessfully Equipped %s!"):format(gloveName))
		return true
	end
	return false
end

function ShopHandler_Server.Ability(mainPlayer: Player, abilityName: string)
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	local ownedAbilities = playerData:GetData("Abilities")
	local abilityPrice: NumberValue = ReplicatedStorage.Constants.Prices:FindFirstChild(abilityName)
	if table.find(ownedAbilities, abilityName) then
		if playerData:GetData("EquippedAbility") ~= abilityName then
			playerData:SetData("EquippedAbility", abilityName)
			popUpHandlerRemote:FireClient(mainPlayer, "ShopUpdate", ("Sucessfully Equipped %s!"):format(abilityName))
		end
		return true
	end
	if abilityPrice and playerData:GetData("Coins") >= abilityPrice.Value then
		playerData:IncrementData("Coins", -abilityPrice.Value)
		playerData:AppendData("Abilities", abilityName)
		popUpHandlerRemote:FireClient(mainPlayer, "ShopUpdate", ("Sucessfully Purchased %s!"):format(abilityName))
		return true
	end
	return false
end

function ShopHandler_Server.Respawn(mainPlayer: Player)
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	if #workspace.InGame:GetChildren() >= MINIMUM_PLAYERS_FOR_RESPAWN then
		if playerData:GetData("RespawnSaved") then
			playerData:SetData("RespawnSaved", false)
			return serverUtils.SpawnCharacterInGame(mainPlayer.Character)
		end
		return MarketplaceService:PromptProductPurchase(mainPlayer, CEnum.DevProductIDs.Respawn)
	end
end

function remoteFunction.OnServerInvoke(mainPlayer: Player, dataTable: { Category: string, Item: string })
	return ShopHandler_Server[dataTable.Category] and ShopHandler_Server[dataTable.Category](mainPlayer, dataTable.Item)
end

return ShopHandler_Server
