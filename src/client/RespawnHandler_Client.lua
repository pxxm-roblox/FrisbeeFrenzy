--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local proximityHandler = gameDirectory.Require("Client.ProximityHandler")

--/GLOBAL_VARIABLES

local RespawnHandlerClient = {}

local respawnRing: BasePart = workspace:WaitForChild("Spawn"):WaitForChild("RespawnRing")
local healParticle: ParticleEmitter = respawnRing:WaitForChild("Heal")
local otherBillBoardUI: BillboardGui = respawnRing:WaitForChild("Other"):WaitForChild("BillboardGui")
local inGameFolder: Folder = workspace:WaitForChild("InGame")
local shopHandlerRemote: RemoteFunction = gameDirectory.GetReplicatedServiceFolder("ShopUIHandler").RemoteFunction

local MINIMUM_AMOUNT_OF_PLAYERS: number = game.ReplicatedStorage.Constants.Main.MinimumPlayersRespawn.Value

--/GLOBAL_FUNCTIONS

--<<Enables/disables respawn ring based on how many players are in game
local function updateRespawnRing(isEnabled: boolean)
	respawnRing.Transparency = isEnabled and 0 or 1
	healParticle.Enabled = isEnabled
	otherBillBoardUI.Enabled = isEnabled
end

--/MODULAR_FUNCTIONS

proximityHandler.RegisterProximityFunction(respawnRing, function(enterState: string)
	if enterState == "Entered" then
		if #inGameFolder:GetChildren() >= MINIMUM_AMOUNT_OF_PLAYERS then
			return shopHandlerRemote:InvokeServer({
				Category = "Respawn",
			})
		end
	end
end)

inGameFolder.ChildAdded:Connect(function()
	if #inGameFolder:GetChildren() >= MINIMUM_AMOUNT_OF_PLAYERS then
		updateRespawnRing(true)
	end
end)

inGameFolder.ChildRemoved:Connect(function()
	if #inGameFolder:GetChildren() < MINIMUM_AMOUNT_OF_PLAYERS then
		updateRespawnRing(false)
	end
end)

updateRespawnRing(#inGameFolder:GetChildren() >= MINIMUM_AMOUNT_OF_PLAYERS)

return RespawnHandlerClient
