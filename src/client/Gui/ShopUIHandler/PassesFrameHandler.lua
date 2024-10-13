--/SERVICES

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)

--/GLOBAL_VARIABLES

local PassesFrameHandler = {}

local mainPlayer: Player = game.Players.LocalPlayer
local mainGUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local passesFrame: Frame = mainGUI.Frames.ShopFrame.PassesFrame
local remoteFunction: RemoteFunction = gameDirectory.GetReplicatedServiceFolder("ShopUIHandler").RemoteFunction

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

for _, uiFolder: Folder in ipairs(passesFrame.GamepassFrame:GetChildren()) do
	uiFolder.ImageButton.Activated:Connect(function()
		return remoteFunction:InvokeServer({
			Category = "GamePass",
			Item = uiFolder.Name,
		})
	end)
end

PassesFrameHandler.MainFrame = passesFrame

return PassesFrameHandler
