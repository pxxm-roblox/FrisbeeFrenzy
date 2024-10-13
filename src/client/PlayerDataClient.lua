--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local remoteEvent: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("DataReplicator").RemoteEvent

--/GLOBAL_VARIABLES

local playerDataReplicator = {}
local dataChangedListeners: { [string]: { (any) -> () } } = {}
local replicationFunctions = {}
local playerData = nil
local metaData = nil

--/GLOBAL_FUNCTIONS

--<<Checks if a listener for the data exists, if it exists loop through all listeners and call them
local function callDataChangedListeners(dataName: string, data: any)
	if dataChangedListeners[dataName] then
		for _, listener in dataChangedListeners[dataName] do
			task.spawn(listener, data)
		end
	end
end

--/MODULAR_FUNCTIONS

function playerDataReplicator.OnDataChanged(dataName: string, callBack: (any) -> ())
	if not dataChangedListeners[dataName] then
		dataChangedListeners[dataName] = {}
	end
	table.insert(dataChangedListeners[dataName], callBack)
end

--<<READ_ONLY
function playerDataReplicator.GetData(key: string)
	return playerData[key]
end

function playerDataReplicator.GetMetaData(key: string)
	return metaData[key]
end

function playerDataReplicator.WaitForData()
	while not playerData or not metaData do
		task.wait()
	end
end

function replicationFunctions.Loaded(args: { Data: {}, MetaData: {} })
	playerData = args.Data
	metaData = args.MetaData
end

function replicationFunctions.Set(args: { Key: string, Value: any })
	if playerData then
		playerData[args.Key] = args.Value
		return callDataChangedListeners(args.Key, args.Value)
	end
end

function replicationFunctions.SetDictionary(args: { Key: string, DictKey: string, Value: any })
	if playerData then
		local dictionary = playerData[args.Key]
		dictionary[args.DictKey] = args.Value
		return callDataChangedListeners(args.Key, { DictKey = args.DictKey, Value = args.Value })
	end
end

function replicationFunctions.Append(args: { Key: string, Value: any })
	if playerData then
		table.insert(playerData[args.Key], args.Value)
		return callDataChangedListeners(args.Key, args.Value)
	end
end

function replicationFunctions.AppendMetaData(args: { Key: string, Value: any })
	if metaData then
		table.insert(metaData[args.Key], args.Value)
		return callDataChangedListeners(args.Key, args.Value)
	end
end

remoteEvent.OnClientEvent:Connect(function(args: { Action: string, Args: { [string]: any } })
	return replicationFunctions[args.Action](args.Args)
end)

return playerDataReplicator
