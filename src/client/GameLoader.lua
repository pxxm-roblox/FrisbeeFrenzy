--/SERVICES

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local remoteEvent: RemoteEvent = gameDirectory.RegisterAsReplicatedService("PlayerLoaded", "RemoteEvent").RemoteEvent

--/GLOBAL_VARIABLES

local GameLoader = {}

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

if not game:IsLoaded() then
	game.Loaded:Wait()
end

ContentProvider:PreloadAsync(ReplicatedStorage.Animations:GetChildren())

if not game:GetService("Players").LocalPlayer:HasAppearanceLoaded() then
	game:GetService("Players").LocalPlayer.CharacterAppearanceLoaded:Wait()
end

remoteEvent:FireServer()

return GameLoader
