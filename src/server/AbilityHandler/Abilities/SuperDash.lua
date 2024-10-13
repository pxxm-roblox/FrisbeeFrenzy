--/SERVICES

--/TYPES

--/MODULES

local dashModule = require(script.Parent.Dash)

--/GLOBAL_VARIABLES

local DashAbility = {}

local SUPER_DASH_SPEED: number = game.ReplicatedStorage.Constants.Abilities.SuperDashSpeed.Value

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function DashAbility.Main(mainChar: Model, onAbilityEnd: (ignoreReplication: boolean) -> nil, args)
	args.CustomSpeed = SUPER_DASH_SPEED
	return dashModule.Main(mainChar, onAbilityEnd, args)
end

return DashAbility
