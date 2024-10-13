local ContentProvider = game:GetService("ContentProvider")
local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local mainServices = gameDirectory.GetServices()
gameDirectory.PreloadModules(script)
gameDirectory.PreloadModules(game.ReplicatedStorage.Shared)

ContentProvider:PreloadAsync(mainServices.ReplicatedStorage.Animations:GetChildren())
