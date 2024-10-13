--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local characterDataObjectModule = require(script.CharacterDataObject)
local mainServices = gameDirectory.GetServices()
local gameData = gameDirectory.Require("Server.GameManager.Data")

--/GLOBAL_VARIABLES

local CharacterGameData = {}
local characterData: { [Model]: {} } = {}

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function CharacterGameData.Register(mainChar: Model)
	local characterDataObject = characterDataObjectModule.new(mainChar)
	characterData[mainChar] = characterDataObject
	return characterDataObject
end

function CharacterGameData.UnregisterAll()
	return table.clear(characterData)
end

function CharacterGameData.Get(mainChar: Model)
	return characterData[mainChar]
end

--/WORKSPACE

mainServices.Players.PlayerAdded:Connect(function(mainPlayer: Player)
	mainPlayer.CharacterAdded:Connect(function(mainChar: Model)
		local mainCon: RBXScriptConnection
		mainCon = mainChar.AncestryChanged:Connect(function(_, newParent: Instance?)
			if not newParent then
				if characterData[mainChar] then
					characterData[mainChar] = nil
				end
				gameData.OnCharacterLeave(mainChar)
				return mainCon:Disconnect()
			end
		end)
	end)
end)

return CharacterGameData
