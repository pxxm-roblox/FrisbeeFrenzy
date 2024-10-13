--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local playerDataManager = gameDirectory.Require("Server.PlayerData")
local giftFunctions = require(script.GiftFunctions)

--/GLOBAL_VARIABLES

local PlaytimeRewards = {}

local remoteFunction: RemoteFunction =
	gameDirectory.RegisterAsReplicatedService("PlaytimeRewards", "RemoteFunction").RemoteFunction

local giftTimeConstants: Folder = ReplicatedStorage.Constants.PlaytimeRewardTimes

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function PlaytimeRewards.CheckCanClaim(mainPlayer: Player, args: { GiftNumber: number }): boolean
	local giftTime: number = giftTimeConstants[tostring(args.GiftNumber)].Value * 60
	local playerData = playerDataManager.GetPlayerData(mainPlayer)
	return (playerData and (os.time() - playerData:GetJoinedTimeStamp() >= giftTime))
end

function PlaytimeRewards.ClaimGift(mainPlayer: Player, args: { GiftNumber: number })
	if PlaytimeRewards.CheckCanClaim(mainPlayer, args) then
		local playerData = playerDataManager.GetPlayerData(mainPlayer)
		if not playerData:CheckGiftClaimed(args.GiftNumber) then
			giftFunctions[args.GiftNumber](mainPlayer)
			playerData:SetGiftClaimed(args.GiftNumber)
		end
		return true
	end
	return false
end

function remoteFunction.OnServerInvoke(
	mainPlayer: Player,
	args: {
		Method: string,
		Args: {
			[string]: any,
		},
	}?
)
	local indexedFunction = PlaytimeRewards[args.Method]
	return (indexedFunction and indexedFunction(mainPlayer, args.Args))
end

return PlaytimeRewards
