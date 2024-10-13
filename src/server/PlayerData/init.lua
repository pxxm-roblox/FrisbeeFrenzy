--/SERVICES

local Players = game:GetService("Players")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local CEnum = gameDirectory.CEnum
local profileService = gameDirectory.Require("Server.ProfileService")
local playerDataObject = require(script.DataObject)

--/GLOBAL_VARIABLES

local PlayerDataManager = {}

local DATA_STORE_VERSION: string = game.ServerStorage.ServerConstants.DataStoreVersion.Value

local OnReleaseCallbacks: { (playerDataObject.PlayerDataObject) -> () } = {}

local profileStore = profileService.GetProfileStore(DATA_STORE_VERSION, playerDataObject.ProfileTemplate)

local playerProfiles: { [Player]: playerDataObject.PlayerDataObject } = {}

local dataLoadRequests: { [Player]: { () -> () } } = {}

--/GLOBAL_FUNCTIONS

--<<Finds if theres a data load requests, if there is call it and set it to nil
local function checkDataLoadRequest(player: Player, profile: playerDataObject.PlayerDataObject)
	local indexedLoadRequests: { () -> () } = dataLoadRequests[player]
	if indexedLoadRequests then
		dataLoadRequests[player] = nil
		for _, callBack: () -> () in ipairs(indexedLoadRequests) do
			task.spawn(callBack, profile)
		end
	end
end

--<<Iterates through release callbacks and calls them each individually
local function callReleaseCallbacks(profileObject: playerDataObject.PlayerDataObject)
	for _, releaseCallback: (playerDataObject.PlayerDataObject) -> () in ipairs(OnReleaseCallbacks) do
		releaseCallback(profileObject)
	end
end

local function onProfileLoaded(mainPlayer: Player, profile: playerDataObject.PlayerDataObject)
	if profile:GetData("EquippedAbility") == "" then
		profile:SetData("EquippedAbility", "Dash")
		profile:AppendData("Abilities", "Dash")
	end
	profile:SetJoinedTimeStamp()
	profile:CheckSelectedClaimPeriodsAndReset({
		CEnum.ClaimItems.PlaytimeRewardsClaimed,
		CEnum.ClaimItems.SpinsBoughtWithCoins,
	})
	profile:CheckOwnedPasses()
	print("Loaded: " .. mainPlayer.Name, profile)
	return checkDataLoadRequest(mainPlayer, profile)
end

local function onPlayerAdded(mainPlayer: Player)
	local profile = profileStore:LoadProfileAsync("Player_" .. mainPlayer.UserId)
	if profile then
		profile:AddUserId(mainPlayer.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			callReleaseCallbacks(playerProfiles[mainPlayer])
			playerProfiles[mainPlayer] = nil
			return mainPlayer:Kick()
		end)
		if mainPlayer:IsDescendantOf(Players) then
			playerProfiles[mainPlayer] = playerDataObject.wrap(profile, mainPlayer)
			return onProfileLoaded(mainPlayer, playerProfiles[mainPlayer])
		end
		return profile:Release()
	end
	return mainPlayer:Kick("Data could not be loaded sorry!")
end

--/MODULAR_FUNCTIONS

function PlayerDataManager.GetPlayerData(mainPlayer: Player)
	return playerProfiles[mainPlayer]
end

function PlayerDataManager.OnProfileRelease(callBack: (playerDataObject.PlayerDataObject) -> ())
	table.insert(OnReleaseCallbacks, callBack)
end

function PlayerDataManager.OnDataLoaded(mainPlayer: Player, callBack: (playerDataObject.PlayerDataObject) -> ())
	if not playerProfiles[mainPlayer] then
		local playerLoadedRequests = dataLoadRequests[mainPlayer]
		if playerLoadedRequests then
			table.insert(playerLoadedRequests, callBack)
		else
			dataLoadRequests[mainPlayer] = {
				callBack,
			}
		end
		return
	end
	return callBack(playerProfiles[mainPlayer])
end

--/WORKSPACE

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(mainPlayer: Player)
	local profile = playerProfiles[mainPlayer]
	if dataLoadRequests[mainPlayer] then
		dataLoadRequests[mainPlayer] = nil
	end
	return (profile and profile:GetProfileObject():Release())
end)

PlayerDataManager.OnProfileRelease(function(profileObject: playerDataObject.PlayerDataObject)
	return profileObject:GetData("FirstTimePlaying") and profileObject:SetData("FirstTimePlaying", false)
end)

for _, mainPlayer: Player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(mainPlayer)
end

return PlayerDataManager
