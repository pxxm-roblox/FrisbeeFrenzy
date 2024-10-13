--/SERVICES

local Players = game:GetService("Players")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local playerDataManager = gameDirectory.Require("Server.PlayerData")
local remoteFunction: RemoteFunction =
	gameDirectory.RegisterAsReplicatedService("SpinHandler", "RemoteFunction").RemoteFunction
local prizesModule = require(script.Prizes)

--/GLOBAL_VARIABLES

local SpinHandler_Server = {}
local GiftRequests: { [Player]: (Player) -> () } = {}

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function remoteFunction.OnServerInvoke(mainPlayer: Player, Method: "Roll" | "Claim"): { Status: string, Args: string }
	if Method == "Roll" then
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		if not GiftRequests[mainPlayer] and playerData:GetData("Spins") > 0 then
			local prizeWon: string, giftFunction: (Player) -> () = prizesModule.RollPrize()
			playerData:IncrementData("Spins", -1)
			GiftRequests[mainPlayer] = giftFunction
			return {
				Status = "Success",
				Args = prizeWon,
			}
		end
		return {
			Status = "Failed",
			Args = "Insufficient Spins!",
		}
	end
	if Method == "Claim" and GiftRequests[mainPlayer] then
		GiftRequests[mainPlayer](mainPlayer)
		GiftRequests[mainPlayer] = nil
	end
end

Players.PlayerRemoving:Connect(function(player: Player)
	if GiftRequests[player] then
		GiftRequests[player] = nil
	end
end)

return SpinHandler_Server
