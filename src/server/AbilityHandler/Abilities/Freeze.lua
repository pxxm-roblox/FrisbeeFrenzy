--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(ReplicatedStorage.Shared.GameDirectory)
local gameDataManager = gameDirectory.Require("Server.GameManager.Data")

--/GLOBAL_VARIABLES

local constantsFolder = ReplicatedStorage.Constants

local FREEZE_TIME: number = constantsFolder.Abilities.FreezeTime.Value

local FreezeAbility = {}

--/GLOBAL_FUNCTIONS
--/MODULAR_FUNCTIONS

function FreezeAbility.Main(mainChar: Model, onAbilityEnd: (ignoreReplication: boolean, ignoreAbilityCD: boolean) -> ())
	local targettedFrisbee = gameDataManager.GetTargettedFrisbee(mainChar)
	if targettedFrisbee then
		targettedFrisbee:Freeze(FREEZE_TIME)
		return onAbilityEnd()
	end
	return onAbilityEnd(false, true)
end

return FreezeAbility
