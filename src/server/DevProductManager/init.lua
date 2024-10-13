local DevProductManager = {}

local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local GameAnalyticsGDK = require(game.ReplicatedStorage.GameAnalytics)
local playerDataManager = gameDirectory.Require("Server.PlayerData")
local CEnum = gameDirectory.CEnum
local popUpHandlerRemote: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("PopUpHandler").RemoteEvent

-- Data store for tracking purchases that were successfully processed
local purchaseHistoryStore = DataStoreService:GetDataStore("PurchaseHistory")

-- Table setup containing product IDs and functions for handling purchases
local productFunctions = require(script.ProductFunctions)
local gamePassFunctions = require(script.GamePassFunctions)

-- The core 'ProcessReceipt' callback function
local function processReceipt(receiptInfo)
	-- Determine if the product was already granted by checking the data store
	local playerProductKey = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId
	local purchased = false
	local success, errorMessage

	success, errorMessage = pcall(function()
		purchased = purchaseHistoryStore:GetAsync(playerProductKey)
	end)
	-- If purchase was recorded, the product was already granted
	if success and purchased then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif not success then
		error("Data store error:" .. errorMessage)
	end

	local success, isPurchaseRecorded = pcall(function()
		return purchaseHistoryStore:UpdateAsync(playerProductKey, function(alreadyPurchased)
			if alreadyPurchased then
				return true
			end

			-- Find the player who made the purchase in the server
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				-- The player probably left the game
				-- If they come back, the callback will be called again
				return nil
			end

			local handler = productFunctions[receiptInfo.ProductId]

			local success, result = pcall(handler, receiptInfo, player)
			-- If granting the product failed, do NOT record the purchase in datastores.
			if not success or not result then
				error(
					"Failed to process a product purchase for ProductId: "
						.. tostring(receiptInfo.ProductId)
						.. " Player: "
						.. tostring(player)
						.. " Error: "
						.. tostring(result)
				)
				return nil
			end

			-- Record the transcation in purchaseHistoryStore.
			return true
		end)
	end)

	if not success then
		error("Failed to process receipt due to data store error.")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	elseif isPurchaseRecorded == nil then
		-- Didn't update the value in data store.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	else
		-- IMPORTANT: Tell Roblox that the game successfully handled the purchase
		GameAnalyticsGDK:ProcessReceiptCallback(receiptInfo)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

-- Set the callback; this can only be done once by one script on the server!
MarketplaceService.ProcessReceipt = processReceipt

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if wasPurchased then
		local playerData = playerDataManager.GetPlayerData(player)
		local gamePassData = nil
		for _, gamePass in pairs(CEnum.GamePasses) do
			if gamePass.GamePassID == gamePassId then
				gamePassData = gamePass
				break
			end
		end
		if gamePassData and not table.find(playerData:GetMetaDataByKey("OwnedGamepasses"), gamePassData.Name) then
			playerData:AppendMetaData("OwnedGamepasses", gamePassData.Name)
			if gamePassFunctions[gamePassData.Name] then
				gamePassFunctions[gamePassData.Name](player)
			end
			return popUpHandlerRemote:FireClient(
				player,
				"ShopUpdate",
				("Successfully Purchased GamePass %s!"):format(gamePassData.Name)
			)
		end
	end
end)

return DevProductManager
