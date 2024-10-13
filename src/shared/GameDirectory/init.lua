--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--/TYPES

--/MODULES

--/GLOBAL_VARIABLES

local GameDirectory = {
	GlobalFunctions = require(script.Parent.Utils.GlobalFunctions),
	CEnum = require(script.Parent.Utils.CustomEnums),
}
local directoryPaths = {}

--/GLOBAL_FUNCTIONS

--<<Registers path IF it exists
local function registerDirectoryPath(strName: string, pathInstance: Instance?)
	directoryPaths[strName] = pathInstance
end

--<<Initializes directory paths
local function initDirectoryPath()
	--//Variables
	local sharedFolder: Folder = game.ReplicatedStorage.Shared

	--//Workspace
	registerDirectoryPath("Shared", sharedFolder)
	registerDirectoryPath("RS", game.ReplicatedStorage)
	registerDirectoryPath("Utils", sharedFolder.Utils)
	registerDirectoryPath("Data", sharedFolder.Data)
	if RunService:IsServer() then
		registerDirectoryPath("Server", game.ServerScriptService.Server)
		registerDirectoryPath("SS", game.ServerStorage)
		registerDirectoryPath("SSS", game.ServerScriptService)
	else
		local mainPlayer: Player = Players.LocalPlayer
		registerDirectoryPath("Client", mainPlayer.PlayerScripts.Client)
		registerDirectoryPath("PlayerScripts", mainPlayer.PlayerScripts)
	end
end

--/MODULAR_FUNCTIONS

--<<Preloads all modules under a passed instance
function GameDirectory.PreloadModules(parentInstance: Instance, ignoreStatusMessages: boolean)
	for _, childInstance: Instance in parentInstance:GetChildren() do
		if childInstance:IsA("Folder") then
			GameDirectory.PreloadModules(childInstance)
			continue
		end
		if childInstance:IsA("ModuleScript") then
			GameDirectory.GlobalFunctions.safeRequire(childInstance, ignoreStatusMessages)
		end
	end
end

--<<Returns the direct instance from string passed
function GameDirectory.Get(strPathData: string): Instance
	local stringSplitData: { string } = string.split(strPathData, ".")
	local instanceReturn: Instance = directoryPaths[stringSplitData[1]]

	assert(instanceReturn, string.format("%s is not a valid directory/sub-directory", stringSplitData[1]))

	for x = 2, #stringSplitData do
		instanceReturn = instanceReturn[stringSplitData[x]]
	end

	return instanceReturn
end

--<<Requires a module from given path
function GameDirectory.Require(stringPath: string)
	local moduleRequire: ModuleScript? = GameDirectory.Get(stringPath)
	assert(
		moduleRequire:IsA("ModuleScript"),
		string.format("%s is not a requirable module instance", moduleRequire.Name)
	)
	return GameDirectory.GlobalFunctions.safeRequire(moduleRequire)
end

--<<Requires a module from given path asynchrnously
function GameDirectory.RequireAsync(stringPath: string)
	local moduleRequire: ModuleScript? = GameDirectory.Get(stringPath)
	assert(
		moduleRequire:IsA("ModuleScript"),
		string.format("%s is not a requirable module instance", moduleRequire.Name)
	)
	return GameDirectory.GlobalFunctions.safeRequireAsync(moduleRequire)
end

--<<Registers as a client server service
function GameDirectory.RegisterAsReplicatedService(
	serviceName: string,
	typeCommunication: string
): {
	RemoteEvent: RemoteEvent?,
	RemoteFunction: RemoteFunction?,
	UnreliableRemoteEvent: UnreliableRemoteEvent?,
}
	if RunService:IsServer() then
		local remoteFolder: Folder = Instance.new("Folder")
		local remoteEvent: RemoteEvent? = (
			(typeCommunication == "Both" or typeCommunication == "RemoteEvent") and Instance.new("RemoteEvent")
			or nil
		)
		local unreliableRemoteEvent: UnreliableRemoteEvent? = (
			typeCommunication == "UnreliableRemoteEvent" and Instance.new("UnreliableRemoteEvent") or nil
		)
		local remoteFunction: RemoteFunction? = (
			(typeCommunication == "Both" or typeCommunication == "RemoteFunction")
				and Instance.new("RemoteFunction")
			or nil
		)
		if remoteEvent then
			remoteEvent.Parent = remoteFolder
		end
		if remoteFunction then
			remoteFunction.Parent = remoteFolder
		end
		if unreliableRemoteEvent then
			unreliableRemoteEvent.Parent = remoteFolder
		end
		remoteFolder.Name = serviceName
		remoteFolder.Parent = ReplicatedStorage.Remotes
		return {
			RemoteEvent = remoteEvent,
			RemoteFunction = remoteFunction,
			UnreliableRemoteEvent = unreliableRemoteEvent,
		}
	end
	return GameDirectory.GetReplicatedServiceFolder(serviceName)
end

--<<Returns Replicated Folder
function GameDirectory.GetReplicatedServiceFolder(serviceName: string)
	local remoteFolder = ReplicatedStorage.Remotes:FindFirstChild(serviceName)
		or ReplicatedStorage.Remotes:WaitForChild(serviceName)
	return {
		RemoteEvent = remoteFolder:FindFirstChildWhichIsA("RemoteEvent"),
		RemoteFunction = remoteFolder:FindFirstChildWhichIsA("RemoteFunction"),
		UnreliableRemoteEvent = remoteFolder:FindFirstChildWhichIsA("UnreliableRemoteEvent"),
	}
end

--<<Gets services that will be commonly used
function GameDirectory.GetServices()
	return {
		ReplicatedStorage = ReplicatedStorage,
		RunService = RunService,
		Players = Players,
	}
end

--<<Initializes gameDirectoryModule
function GameDirectory.__init__()
	initDirectoryPath()
	return GameDirectory
end

return GameDirectory.__init__()
