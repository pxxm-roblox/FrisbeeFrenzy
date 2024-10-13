--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local playerDataManager = gameDirectory.Require("Server.PlayerData")
local trelloAPI = gameDirectory.Require("Server.TrelloAPI")
local BoardID = trelloAPI.BoardsAPI.GetBoardID("Frisbee project")
local ListId = trelloAPI.BoardsAPI.GetListID(BoardID, "Codes")

--/GLOBAL_VARIABLES

local CodesHandler = {}

local remoteFunction: RemoteFunction =
	gameDirectory.RegisterAsReplicatedService("CodesHandler", "RemoteFunction").RemoteFunction

--/GLOBAL_FUNCTIONS

local function doesGloveExist(newGlove: string): boolean
	for _, rarityFolder: Folder in ipairs(ReplicatedStorage.Gloves:GetChildren()) do
		local gloveFolder: Folder? = rarityFolder:FindFirstChild(newGlove)
		if gloveFolder then
			return true
		end
	end
	return false
end

local ClaimRewardFunctions = {}

ClaimRewardFunctions.coins = function(playerData, amountMoney: number)
	return playerData:IncrementData("Coins", amountMoney)
end

ClaimRewardFunctions.spins = function(playerData, amountSpins: number)
	return playerData:IncrementData("Spins", amountSpins)
end

ClaimRewardFunctions.glove = function(playerData, typeGlove: string)
	if doesGloveExist(typeGlove) then
		return playerData:AppendData("GloveSkins", typeGlove)
	end
end

--<<Get card object from codename
local function getCardFromCodeName(codeName: string)
	for _, cardObject in ipairs(trelloAPI.CardsAPI.GetCardsOnList(ListId)) do
		if cardObject.name == codeName then
			return cardObject
		end
	end
end

--<<Rewards player with the code they inputted
local function rewardPlayerWithCodeInputted(mainPlayer: Player, cardObject)
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	local codesRedeemed = playerData:GetData("CodesRedeemed")
	if cardObject and not table.find(codesRedeemed, cardObject.name) then
		local success: boolean = pcall(function()
			local itemsArray: { string } = cardObject.desc:gsub("%s+", ""):split(",")
			for _, itemPair: string in ipairs(itemsArray) do
				local splitArray: { string } = itemPair:split(":")
				ClaimRewardFunctions[splitArray[1]:lower()](playerData, tonumber(splitArray[2]) or splitArray[2])
			end
			playerData:AppendData("CodesRedeemed", cardObject.name)
		end)
		return success
	end
end

--/MODULAR_FUNCTIONS

function remoteFunction.OnServerInvoke(mainPlayer: Player, codeName: string): boolean
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	if #codeName > 0 and not playerData:GetMetaDataByKey("CodeCD") then
		playerData:SetMetaData("CodeCD", true)
		if rewardPlayerWithCodeInputted(mainPlayer, getCardFromCodeName(codeName)) then
			playerData:SetMetaData("CodeCD", false)
			return true
		end
		playerData:SetMetaData("CodeCD", false)
	end
	return false
end

return CodesHandler
