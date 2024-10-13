--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local dashAbility = require(script.Parent.Dash)

--/GLOBAL_VARIABLES

local superDashHandler = {}
local dashConstants: Folder = ReplicatedStorage.Constants.Abilities

local DASH_SPEED: number = dashConstants.SuperDashSpeed.Value

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function superDashHandler.Main(onSkillEnd: (cooldownTime: number) -> nil)
	return dashAbility.Main(onSkillEnd, DASH_SPEED)
end

return superDashHandler
