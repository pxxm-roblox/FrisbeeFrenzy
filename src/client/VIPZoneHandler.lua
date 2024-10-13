--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local CEnum = gameDirectory.CEnum
local playerDataClient = gameDirectory.Require("Client.PlayerDataClient")
playerDataClient.WaitForData()

--/GLOBAL_VARIABLES

local VIPZoneHandler = {}

local vipZoneBlocker: BasePart = workspace:WaitForChild("Spawn"):WaitForChild("VIPblocker")

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

if table.find(playerDataClient.GetMetaData("OwnedGamepasses"), CEnum.GamePasses.VIP.Name) then
	vipZoneBlocker:Destroy()
else
	local shopRemoteFunction: RemoteFunction = gameDirectory.GetReplicatedServiceFolder("ShopUIHandler").RemoteFunction
	local proximityHandler = gameDirectory.Require("Client.ProximityHandler")
	local rainbowRing: BasePart = workspace:WaitForChild("Spawn"):WaitForChild("RainbowRing")

	proximityHandler.RegisterProximityFunction(rainbowRing, function()
		if not table.find(playerDataClient.GetMetaData("OwnedGamepasses"), CEnum.GamePasses.VIP.Name) then
			return shopRemoteFunction:InvokeServer({
				Category = "GamePass",
				Item = CEnum.GamePasses.VIP.Name,
			})
		end
	end)

	playerDataClient.OnDataChanged("OwnedGamepasses", function(gamePassBought: string)
		if gamePassBought == CEnum.GamePasses.VIP.Name then
			vipZoneBlocker:Destroy()
		end
	end)
end

return VIPZoneHandler
