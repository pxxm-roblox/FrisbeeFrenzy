--/SERVICES

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local remoteEvent: RemoteEvent = gameDirectory.GetReplicatedServiceFolder("PopUpHandler").RemoteEvent
local shopUIHandler = gameDirectory.RequireAsync("Client.Gui.ShopUIHandler")
local globalFunctions = gameDirectory.GlobalFunctions
local playersFolder: Folder = workspace:WaitForChild("Players")
local inGameFolder: Folder = workspace:WaitForChild("InGame")

--/GLOBAL_VARIABLES

local GamePopUpsHandler = {}

local mainPlayer: Player = game.Players.LocalPlayer
local mainGUI: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local popUps: Folder = mainGUI.Frames.PopUps
local currentFrame: Frame = nil

--/GLOBAL_FUNCTIONS

--<<Use win pop up
local function useWinPopUp()
	local effectFlag: number
	return function(playerWon: string)
		local flagCompare: number = os.clock()
		effectFlag = flagCompare
		local winPopUp: Frame = popUps.WinFrame
		local textLabel: TextLabel = winPopUp.TextLabel
		local tweenInfo: TweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Sine)
		textLabel.Text = playerWon .. " WON!"
		currentFrame = winPopUp
		winPopUp.Visible = true
		SoundService:PlayLocalSound(ReplicatedStorage.Sounds.WinSound)
		TweenService:Create(textLabel, tweenInfo, {
			TextTransparency = 0,
		}):Play()
		TweenService:Create(textLabel.UIStroke, tweenInfo, {
			Transparency = 0,
		}):Play()
		return task.delay(tweenInfo.Time + 3, function()
			if flagCompare == effectFlag then
				TweenService:Create(textLabel, tweenInfo, {
					TextTransparency = 1,
				}):Play()
				return TweenService:Create(textLabel.UIStroke, tweenInfo, {
					Transparency = 1,
				}):Play()
			end
		end)
	end
end

--<<Use kill pop up
local function useKillPopUp()
	local effectFlag: number
	return function(playerKilled: string)
		local flagCompare: number = os.clock()
		effectFlag = flagCompare
		local killPopUp: Frame = popUps.KillFrame
		local textLabel: TextLabel = killPopUp.Label
		local tweenInfo: TweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Sine)
		textLabel.Text = "YOU KILLED " .. playerKilled
		currentFrame = killPopUp
		killPopUp.Visible = true
		SoundService:PlayLocalSound(ReplicatedStorage.Sounds.KillSound)
		TweenService:Create(textLabel, tweenInfo, {
			TextTransparency = 0,
		}):Play()
		TweenService:Create(textLabel.UIStroke, tweenInfo, {
			Transparency = 0,
		}):Play()
		return task.delay(tweenInfo.Time + 0.5, function()
			if flagCompare == effectFlag then
				TweenService:Create(textLabel, tweenInfo, {
					TextTransparency = 1,
				}):Play()
				return TweenService:Create(textLabel.UIStroke, tweenInfo, {
					Transparency = 1,
				}):Play()
			end
		end)
	end
end

--<<Use shop update pop up
local function useShopUpdatePopUp()
	local effectFlag: number
	return function(shopMessage: string, messageLength: number)
		local flagCompare: number = os.clock()
		effectFlag = flagCompare
		local shopPopUp: Frame = popUps.ShopUpdateFrame
		local textLabel: TextLabel = shopPopUp.Label
		local tweenInfo: TweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Sine)
		textLabel.Text = shopMessage
		currentFrame = shopPopUp
		shopPopUp.Visible = true
		SoundService:PlayLocalSound(ReplicatedStorage.Sounds.Notification2)
		TweenService:Create(textLabel, tweenInfo, {
			TextTransparency = 0,
		}):Play()
		TweenService:Create(textLabel.UIStroke, tweenInfo, {
			Transparency = 0,
		}):Play()
		return task.delay(tweenInfo.Time + (messageLength or 0.5), function()
			if flagCompare == effectFlag then
				TweenService:Create(textLabel, tweenInfo, {
					TextTransparency = 1,
				}):Play()
				return TweenService:Create(textLabel.UIStroke, tweenInfo, {
					Transparency = 1,
				}):Play()
			end
		end)
	end
end

--/MODULAR_FUNCTIONS

GamePopUpsHandler.Win = useWinPopUp()

GamePopUpsHandler.Kill = useKillPopUp()

GamePopUpsHandler.ShopUpdate = useShopUpdatePopUp()

GamePopUpsHandler.HandleCoinSectionChange = shopUIHandler.HandleCoinSectionChange

GamePopUpsHandler.GroupNotification = globalFunctions.UsePopUp(popUps.GroupChestNotif.display, 1)

GamePopUpsHandler.StandOff = globalFunctions.UsePopUp(popUps.StandOff.TextLabel, 2, ReplicatedStorage.Sounds.ClashSound)

function GamePopUpsHandler.SortPopUp(popUpName: string, args: string)
	return GamePopUpsHandler[popUpName](args)
end

remoteEvent.OnClientEvent:Connect(function(typePopUp: string, ...)
	if currentFrame then
		currentFrame.Visible = false
	end
	return GamePopUpsHandler[typePopUp](...)
end)

if #playersFolder:GetChildren() + #inGameFolder:GetChildren() < 2 then
	popUps.NeedMorePlayers.Visible = true
	local rbxCon: RBXScriptConnection
	rbxCon = playersFolder.ChildAdded:Connect(function()
		if #playersFolder:GetChildren() + #inGameFolder:GetChildren() > 1 then
			popUps.NeedMorePlayers.Visible = false
			rbxCon:Disconnect()
		end
	end)
end

return GamePopUpsHandler
