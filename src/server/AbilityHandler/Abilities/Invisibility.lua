--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(ReplicatedStorage.Shared.GameDirectory)
local presetFX = gameDirectory.Require("Shared.PresetFX")

--/GLOBAL_VARIABLES

local InvisibilityAbility = {}

local INVISIBILITY_TIME: number = 1

--/GLOBAL_FUNCTIONS
--/MODULAR_FUNCTIONS

function InvisibilityAbility.Main(
	mainChar: Model,
	onAbilityEnd: (ignoreReplication: boolean, ignoreAbilityCD: boolean) -> ()
)
	presetFX.Sort("Invisibility", {
		MainChar = mainChar,
		TimeInvisible = INVISIBILITY_TIME,
	})
	return task.delay(INVISIBILITY_TIME, onAbilityEnd)
end

function InvisibilityAbility.OnTargettedByFrisbee(mainChar: Model, frisbeeObject)
	frisbeeObject:Pause()
	frisbeeObject:ChaseClosestEnemy(mainChar)
	return true
end

return InvisibilityAbility
