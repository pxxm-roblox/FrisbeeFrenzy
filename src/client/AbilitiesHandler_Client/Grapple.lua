--/SERVICES

--/TYPES

--/MODULES

local grappleModule = require(script.Parent.Parent.GrappleHandler)

--/GLOBAL_VARIABLES

local grappleHandler = {}

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function grappleHandler.Main(onSkillEnd: (cooldownTime: number) -> nil)
	return onSkillEnd(not grappleModule.OnGrapple())
end

return grappleHandler
