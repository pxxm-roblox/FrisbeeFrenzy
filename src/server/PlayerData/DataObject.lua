local DataObject = {}
DataObject.__index = DataObject

--/SERVICES

local MarketplaceService = game:GetService("MarketplaceService")

--/TYPES

type self = {
	Player: Player,
	OnChanged: { [string]: (any) -> () },
	Data: {
		Wins: number,
		Kills: number,
		Coins: number,
		Spins: number,
		FirstTimePlaying: boolean,
		CodesRedeemed: { string },
		EquippedAbility: string,
		EquippedFrisbeeSkin: string,
		RespawnSaved: boolean,
		EquippedGloveSkin: string,
		ClaimPeriods: { [string]: { TimeStamp: number, Duration: number } },
		SpinsBoughtWithCoins: number,
		PlaytimeRewardsClaimed: { number },
		FrisbeeSkins: { string },
		TemporaryGamepasses: { [string]: { TimeStamp: number, Duration: number } },
		GloveSkins: { string },
		Abilities: { string },
	},
	MetaData: {
		Loaded: boolean,
		JoinedTimeStamp: number,
		AFKState: boolean,
		OwnedGamepasses: { string },
		CodeCD: boolean,
	},
	ProfileObject: {},
}

export type PlayerDataObject = typeof(setmetatable({} :: self, DataObject))

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local globalFunctions = gameDirectory.GlobalFunctions
local gamePassFunctions = require(script.Parent.GamePassFunctions)
local CEnum = gameDirectory.CEnum
local remoteEvent: RemoteEvent = gameDirectory.RegisterAsReplicatedService("DataReplicator", "RemoteEvent").RemoteEvent

--/GLOBAL_VARIABLES

local profileTemplate = {
	Wins = 0,
	Kills = 0,
	Coins = 0,
	Spins = 0,
	FirstTimePlaying = true,
	EquippedAbility = "",
	EquippedFrisbeeSkin = "",
	EquippedGloveSkin = "",
	TemporaryGamepasses = {},
	SpinsBoughtWithCoins = 0,
	PlaytimeRewardsClaimed = {},
	RespawnSaved = false,
	CodesRedeemed = {},
	ClaimPeriods = {},
	FrisbeeSkins = {},
	GloveSkins = {},
	Abilities = {},
}

DataObject.ProfileTemplate = profileTemplate

--/GLOBAL_FUNCTIONS

--<<Replicates the data to client and checks for if any of the values or connected to on changed
local function replicateChangedData(dataObject: PlayerDataObject, key: string, value: any)
	remoteEvent:FireClient(dataObject.Player, {
		Action = "Set",
		Args = {
			Key = key,
			Value = value,
		},
	})
	if dataObject.OnChanged[key] ~= nil then
		dataObject.OnChanged[key](value)
	end
end

--/MODULAR_FUNCTIONS

function DataObject.wrap(profileServiceObject, mainPlayer: Player): PlayerDataObject
	return setmetatable({
		Player = mainPlayer,
		Data = profileServiceObject.Data,
		OnChanged = {},
		MetaData = {
			Loaded = false,
			AFKState = false,
			OwnedGamepasses = {},
			CodeCD = false,
		},
		ProfileObject = profileServiceObject,
	}, DataObject)
end

--<<Sets the key of data to the value, if data is an array error
function DataObject.SetData(self: PlayerDataObject, key: string, value: any)
	local dataValue: any = self.Data[key]
	if dataValue ~= nil then
		if type(dataValue) ~= "table" then
			self.Data[key] = value
			return replicateChangedData(self, key, value)
		end
		return error("Data is a table")
	end
	error("Key not found: " .. key)
end

--<<Increments data by step
function DataObject.IncrementData(self: PlayerDataObject, key: string, step: number)
	local dataValue: any = self.Data[key]
	if dataValue ~= nil then
		if type(dataValue) == "number" then
			self.Data[key] = dataValue + step
			return replicateChangedData(self, key, self.Data[key])
		end
		return error("Data is not a number")
	end
	error("Key not found: " .. key)
end

--<<Appends a value to a table data in the data object
function DataObject.AppendData(self: PlayerDataObject, key: string, value: any)
	local dataValue: any = self.Data[key]
	if dataValue ~= nil then
		if type(dataValue) == "table" then
			if not table.find(dataValue, value) then
				table.insert(dataValue, value)
				remoteEvent:FireClient(self.Player, {
					Action = "Append",
					Args = {
						Key = key,
						Value = value,
					},
				})
			else
				warn("Attempt to append duplicate value")
			end
			return
		end
		return error("Data is not a table")
	end
	error("Key not found: " .. key)
end

--<<Checks if data exists within table
function DataObject.ArrayContainsValue(self: PlayerDataObject, key: string, value: any): boolean
	local dataValue: any = self.Data[key]
	if dataValue ~= nil then
		if type(dataValue) == "table" then
			return table.find(dataValue, value) ~= nil
		end
		return error("Data is not a table")
	end
	error("Key not found: " .. key)
end

--<<Returns the data of a key <MEANT TO BE READ ONLY>
function DataObject.GetData(self: PlayerDataObject, key: string): any
	local dataValue: any = self.Data[key]
	if dataValue ~= nil then
		return dataValue
	end
	error("Key not found: " .. key)
end

--<<Checks if player is loaded
function DataObject.IsLoaded(self: PlayerDataObject): boolean
	return self.MetaData.Loaded
end

--<<Sets player loaded
function DataObject.SetLoaded(self: PlayerDataObject)
	self.MetaData.Loaded = true
end

--<<Sets player joined time stamp
function DataObject.SetJoinedTimeStamp(self: PlayerDataObject)
	self.MetaData.JoinedTimeStamp = os.time()
end

--<<Returns player joined time stamp
function DataObject.GetJoinedTimeStamp(self: PlayerDataObject): number
	return self.MetaData.JoinedTimeStamp
end

--<<Sets afk state
function DataObject.SetAFKState(self: PlayerDataObject, state: boolean)
	self.MetaData.AFKState = state
end

--<<Returns afk state
function DataObject.GetAFKState(self: PlayerDataObject): boolean
	return self.MetaData.AFKState
end

function DataObject.CheckGiftClaimed(self: PlayerDataObject, giftNumber: number): boolean
	return table.find(self.Data.PlaytimeRewardsClaimed, giftNumber) ~= nil
end

function DataObject.SetGiftClaimed(self: PlayerDataObject, giftNumber: number)
	if self:CheckClaimPeriodOver(CEnum.ClaimItems.PlaytimeRewardsClaimed) then
		self:SetClaimPeriod(CEnum.ClaimItems.PlaytimeRewardsClaimed, 24)
	end
	return self:AppendData(CEnum.ClaimItems.PlaytimeRewardsClaimed, giftNumber)
end

function DataObject.CheckOwnedPasses(self: PlayerDataObject)
	local mainPlayer: Player = self.Player
	for _, passData in next, CEnum.GamePasses do
		self:OwnsGamepass(passData.Name)
		if MarketplaceService:UserOwnsGamePassAsync(mainPlayer.UserId, passData.GamePassID) then
			table.insert(self.MetaData.OwnedGamepasses, passData.Name)
			if gamePassFunctions[passData.Name] then
				gamePassFunctions[passData.Name](self)
			end
		end
	end
end

--<<Checks if the player owns the gamepass
function DataObject.OwnsGamepass(self: PlayerDataObject, gamepassName: string): boolean
	local temporaryGamepass: { TimeStamp: number, Duration: number }? = self.Data.TemporaryGamepasses[gamepassName]
	if temporaryGamepass then
		if os.time() - temporaryGamepass.TimeStamp < temporaryGamepass.Duration then
			return true
		end
		self.Data.TemporaryGamepasses[gamepassName] = nil
	end
	if table.find(self.MetaData.OwnedGamepasses, gamepassName) then
		return true
	end
	return false
end

--<<Handles temporary gamepasses
function DataObject.GiveTemporaryGamepass(self: PlayerDataObject, gamePassCEnum, durationInMinutes: number)
	local indexedTemporaryGamepass: { TimeStamp: number, Duration: number } =
		self.Data.TemporaryGamepasses[gamePassCEnum.Name]
	durationInMinutes *= 60
	if indexedTemporaryGamepass then
		indexedTemporaryGamepass.TimeStamp = os.time()
		indexedTemporaryGamepass.Duration = durationInMinutes
		return
	end
	self.Data.TemporaryGamepasses[gamePassCEnum.Name] = {
		TimeStamp = os.time(),
		Duration = durationInMinutes,
	}
end

--<<Appends a value to a table data in the data object
function DataObject.AppendMetaData(self: PlayerDataObject, key: string, value: any)
	local dataValue: any = self.MetaData[key]
	if dataValue ~= nil then
		if type(dataValue) == "table" then
			table.insert(dataValue, value)
			return remoteEvent:FireClient(self.Player, {
				Action = "AppendMetaData",
				Args = {
					Key = key,
					Value = value,
				},
			})
		end
		return error("Data is not a table")
	end
	error("Key not found: " .. key)
end

--<<Returns all meta data
function DataObject.GetMetaData(self: PlayerDataObject): { [string]: any }
	return self.MetaData
end

--<<Sets meta data
function DataObject.SetMetaData(self: PlayerDataObject, key: string, value: any)
	self.MetaData[key] = value
end

--<<Returns meta data by key
function DataObject.GetMetaDataByKey(self: PlayerDataObject, key: string): any
	return self.MetaData[key]
end

--<<Returns all data <READ ONLY>
function DataObject.GetAllData(self: PlayerDataObject): { [string]: any }
	return self.Data
end

--<<Returns the profile service object
function DataObject.GetProfileObject(self: PlayerDataObject)
	return self.ProfileObject
end

--<<Checks daily claim dictionary
function DataObject.CheckClaimPeriodOver(self: PlayerDataObject, claimName: string): boolean
	local TIME_IN_SECONDS: number = 3600

	local dailyClaimDictionary = self.Data.ClaimPeriods
	local claimData = dailyClaimDictionary[claimName]
	if claimData then
		if os.time() - claimData.TimeStamp < (claimData.Duration * TIME_IN_SECONDS) then
			return false
		else
			dailyClaimDictionary[claimName] = nil
		end
	end
	return true
end

--<<Sets daily claim
function DataObject.SetClaimPeriod(self: PlayerDataObject, claimName: string, claimPeriodHours: number)
	local dailyClaimDictionary = self.Data.ClaimPeriods
	dailyClaimDictionary[claimName] = {
		TimeStamp = os.time(),
		Duration = claimPeriodHours,
	}
	return remoteEvent:FireClient(self.Player, {
		Action = "SetDictionary",
		Args = {
			Key = "ClaimPeriods",
			DictKey = claimName,
			Value = {
				TimeStamp = os.time(),
				Duration = claimPeriodHours,
			},
		},
	})
end

--<<Resets data to default
function DataObject.ResetData(self: PlayerDataObject, dataName: string)
	local currentData: any = self:GetData(dataName)
	local defaultValue: any = profileTemplate[dataName]
	if currentData ~= defaultValue and (typeof(currentData) ~= "table" or #currentData > 0) then
		if type(defaultValue) == "table" then
			defaultValue = globalFunctions.DeepCopy(defaultValue)
		end
		self.Data[dataName] = defaultValue
		return replicateChangedData(self, dataName, self:GetData(dataName))
	end
end

--<<Returns the player
function DataObject.GetPlayer(self: PlayerDataObject): Player
	return self.Player
end

--<<Checks and resets certain claim periods
function DataObject.CheckSelectedClaimPeriodsAndReset(self: PlayerDataObject, selectedClaimPeriods: { string })
	for _, claimName: string in ipairs(selectedClaimPeriods) do
		if self:CheckClaimPeriodOver(claimName) then
			self:ResetData(claimName)
		end
	end
end

--<<Assigns a function to a value, where if changed, will call the function with the new value
function DataObject.ConnectToOnChanged(self: PlayerDataObject, key: string, func: (any) -> ())
	self.OnChanged[key] = func
end

return DataObject
