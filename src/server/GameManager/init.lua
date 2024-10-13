--/SERVICES

--/TYPES

--/MODULES

--local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)

--/GLOBAL_VARIABLES

local GameManager = {}

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function GameManager.__init__()
	require(script.FrisbeeInputHandler)
	return GameManager
end

return GameManager.__init__()
