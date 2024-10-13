--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(ReplicatedStorage.Shared.GameDirectory)
local remoteEvent: RemoteEvent =
	gameDirectory.RegisterAsReplicatedService("PresetFX", "UnreliableRemoteEvent").UnreliableRemoteEvent

--/GLOBAL_VARIABLES

local PresetFX_Server = {}
local Effects = {}

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

--/Main

function Effects.RockTrail(args)
	return remoteEvent:FireAllClients("RockTrail", args)
end

function Effects.RockTrailFollow(mainPart: BasePart, Size: number, Spacing: number): BoolValue
	local instanceReplicate: BoolValue = Instance.new("BoolValue")
	instanceReplicate.Parent = mainPart
	remoteEvent:FireAllClients("RockTrailFollow", {
		InstanceReplicate = instanceReplicate,
		Spacing = Spacing,
		Size = Size,
	})
	return instanceReplicate
end

function PresetFX_Server.Sort(effectString: string, ...)
	local indexedEffect = Effects[effectString]
	if not indexedEffect then
		return remoteEvent:FireAllClients(effectString, ...)
	end
	return indexedEffect(...)
end

return PresetFX_Server
