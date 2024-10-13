--/SERVICES

--/TYPES

--/MODULES

--/GLOBAL_VARIABLES

local TutorialUI = {}

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local playerDataClient = gameDirectory.Require("Client.PlayerDataClient")
local inputsModule = gameDirectory.Require("Client.InputHandler.Inputs")
local mainPlayer: Player = game.Players.LocalPlayer
local tutorialScreenUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("TutorialUI")
local toggleFrame: Frame = tutorialScreenUI.Toggle
local mainGUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local versionText: TextLabel = toggleFrame:WaitForChild("main").Version
local infoButton: ImageButton = mainGUI:WaitForChild("Buttons").HelpButton
playerDataClient.WaitForData()

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

if inputsModule.PlayerDevice == "Mobile" then
	local textFrame: Frame = toggleFrame.main.Frame.TextFrame
	textFrame.AbilityText.Text = "ABILITY: TAP ABILITY UI BUTTON"
	textFrame.CatchText.Text = "CATCH: TAP SCREEN / TAP CATCH UI BUTTON"
end

if playerDataClient.GetData("FirstTimePlaying") then
	tutorialScreenUI.Enabled = true
end

toggleFrame.top.CloseButton.Activated:Connect(function()
	tutorialScreenUI.Enabled = false
end)

infoButton.Activated:Connect(function()
	tutorialScreenUI.Enabled = not tutorialScreenUI.Enabled
end)

versionText.Text = "VERSION: " .. game.ReplicatedStorage:WaitForChild("GAME_VERSION").Value

return TutorialUI
