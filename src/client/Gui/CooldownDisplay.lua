--/SERVICES

local TweenService = game:GetService("TweenService")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local playerDataClient = gameDirectory.Require("Client.PlayerDataClient")
playerDataClient.WaitForData()

--/GLOBAL_VARIABLES

local CoolDownDisplay = {}
local mainPlayer: Player = game.Players.LocalPlayer
local mainGUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local remoteEvent: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("CooldownDisplayRemote").RemoteEvent

local catchDisplay: TextButton = mainGUI.Buttons.CatchDisplay
local abilityDisplay: TextButton = mainGUI.Buttons.AbilityDisplay
local abilityIcon: ImageLabel = abilityDisplay.Icon

local abilityAssets: Folder = mainGUI.Frames.ShopFrame.AbilitiesFrame.Assets.Abilities

local coolDownFrames = {
	Catch = {
		Frame = catchDisplay.CoolDownFrame,
		Tween = nil,
	},
	Ability = {
		Frame = abilityDisplay.CoolDownFrame,
		Tween = nil,
	},
}

--/GLOBAL_FUNCTIONS

--/MODULAR_FUNCTIONS

function CoolDownDisplay.PlayTween(frameName: string, args: { CDTime: number })
	local frameData = coolDownFrames[frameName]
	local mainFrame: Frame = frameData.Frame
	local frameTween: Tween = TweenService:Create(mainFrame, TweenInfo.new(args.CDTime, Enum.EasingStyle.Linear), {
		Size = UDim2.fromScale(mainFrame.Size.X.Scale, 0),
	})
	frameData.Tween = frameTween
	mainFrame.Size = UDim2.fromScale(mainFrame.Size.X.Scale, 1)
	frameTween:Play()
	return task.delay(args.CDTime, function()
		if frameData.Tween == frameTween then
			frameData.Tween = nil
		end
	end)
end

function CoolDownDisplay.Clear(frameName: string)
	local frameData = coolDownFrames[frameName]
	local mainFrame: Frame = frameData.Frame
	if frameData.Tween then
		frameData.Tween:Cancel()
		frameData.Tween = nil
	end
	mainFrame.Size = UDim2.fromScale(mainFrame.Size.X.Scale, 0)
end

abilityIcon.Image = abilityAssets[playerDataClient.GetData("EquippedAbility")].ImageLabel.Image

playerDataClient.OnDataChanged("EquippedAbility", function(newAbility: string)
	abilityIcon.Image = abilityAssets[newAbility].ImageLabel.Image
end)

remoteEvent.OnClientEvent:Connect(function(dataTable: { FrameName: string, Method: string, Args: { [string]: any } })
	return (
		CoolDownDisplay[dataTable.Method] and CoolDownDisplay[dataTable.Method](dataTable.FrameName, dataTable.Args)
	)
end)

return CoolDownDisplay
