--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)

--/GLOBAL_VARIABLES

local AFKButton = {}

local mainPlayer: Player = game.Players.LocalPlayer
local mainGUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local remoteFunction: RemoteFunction = gameDirectory.GetReplicatedServiceFolder("AFKHandler").RemoteFunction
local afkButton: ImageButton = mainGUI.Buttons.AFKButton

--/GLOBAL_FUNCTIONS

local function onAFKInteract()
	local afkState: boolean = remoteFunction:InvokeServer()
	if afkState then
		afkButton.UIStroke.Color = Color3.fromRGB(0, 255, 0)
		return
	end
	afkButton.UIStroke.Color = Color3.fromRGB(255, 0, 0)
end

--/MODULAR_FUNCTIONS

afkButton.Activated:Connect(onAFKInteract)

return AFKButton
