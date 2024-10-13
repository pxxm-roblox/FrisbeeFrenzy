--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local characterDataManager = gameDirectory.Require("Server.CharacterData")

--/GLOBAL_VARIABLES

local Utilities = {}

local cooldownsFolder = ReplicatedStorage.Constants.CoolDowns

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function Utilities.SetCoolDownCD(mainChar: Model, abilityName: string)
	local mainCharacterData = characterDataManager.Get(mainChar)
	local cooldownTime: NumberValue = cooldownsFolder[abilityName]
	if mainCharacterData and cooldownTime then
		return mainCharacterData:SetAbilityCD(cooldownTime.Value)
	end
end

return Utilities
