--/SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

--/TYPES

--/MODULES

local gameDirectory = require(game:GetService("ReplicatedStorage").Shared.GameDirectory)
local CEnum = gameDirectory.CEnum
local globalFunctions = gameDirectory.GlobalFunctions
local playerDataReplicator = gameDirectory.Require("Client.PlayerDataClient")
playerDataReplicator.WaitForData()

--/GLOBAL_VARIABLES

local PlayetimeRewardsHandler = {}

local remoteFunction: RemoteFunction =
	gameDirectory.RegisterAsReplicatedService("PlaytimeRewards", "RemoteFunction").RemoteFunction

local rewardTimesFolder: Folder = ReplicatedStorage.Constants.PlaytimeRewardTimes
local amtRewards: number = #rewardTimesFolder:GetChildren()
local highestRewardTime: number = rewardTimesFolder[tostring(amtRewards)].Value * 60

local mainPlayer: Player = game.Players.LocalPlayer
local mainGui: ScreenGui = mainPlayer.PlayerGui:WaitForChild("MainGUI")
local playtimeFrame: ImageLabel = mainGui.Frames.PlaytimeFrame
local mainFrame: Frame = playtimeFrame.Main
local giftButton: TextButton = mainGui.Buttons.GiftButton
local giftPopUp: Frame = mainGui.Frames.PopUps.GiftNotif
local giftCount: TextLabel = giftButton.Frame["Gift Count"]

local notificationAmt: number = 0
local flag: number = 0

--/GLOBAL_FUNCTIONS

local function handlePopUpNotif()
	local timeFlag: number = os.clock()
	flag = timeFlag
	giftPopUp.Visible = true
	SoundService:PlayLocalSound(ReplicatedStorage.Sounds.Notification)
	task.delay(1.5, function()
		if flag == timeFlag then
			giftPopUp.Visible = false
		end
	end)
end

--<<On interact
local function onInteract()
	playtimeFrame.Visible = not playtimeFrame.Visible
end

--<<Closes
local function closeGiftFrame()
	playtimeFrame.Visible = false
end

--<<Changes notification gui based on amt of notifications
local function changeNotificationUi()
	if notificationAmt > 0 then
		giftCount.Parent.Visible = true
		giftCount.Text = notificationAmt
	else
		giftCount.Parent.Visible = false
	end
end

--<<Sets up the claming process
local function setUpClaimProcess(statusGui: ImageButton, giftNumber: number)
	local rbxCon: RBXScriptConnection
	rbxCon = statusGui.claim.Activated:Connect(function()
		if remoteFunction:InvokeServer({ Method = "ClaimGift", Args = { GiftNumber = giftNumber } }) then
			rbxCon:Disconnect()
			statusGui.claim.Text = "Claimed!"
			statusGui.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			notificationAmt -= 1
			return changeNotificationUi()
		end
	end)
end

--<<Iterates through all gift gui and updates their status timers with time passed
local function updateGiftStatusTimers(timePassed: number)
	local giftsClaimed = playerDataReplicator.GetData(CEnum.ClaimItems.PlaytimeRewardsClaimed)
	for x = 1, amtRewards do
		local name: string = tostring(x)
		local rewardTime: number = rewardTimesFolder[name].Value
		local statusGui: ImageButton = mainFrame[name].status
		local timeDifference: number = math.max(rewardTime * 60 - timePassed, 0)
		if table.find(giftsClaimed, x) then
			statusGui.claim.Visible = true
			statusGui.timer.Visible = false
			statusGui.claim.Text = "Claimed!"
			statusGui.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		end

		if not statusGui.claim.Visible then
			if timeDifference == 0 then
				if remoteFunction:InvokeServer({ Method = "CheckCanClaim", Args = { GiftNumber = x } }) then
					statusGui.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
					statusGui.claim.Visible = true
					statusGui.timer.Visible = false
					notificationAmt += 1
					changeNotificationUi()
					handlePopUpNotif()
					return setUpClaimProcess(statusGui, x)
				end
			else
				statusGui.timer.Text = globalFunctions.FormatSecondsIntoMinutes(timeDifference)
			end
		end
	end
end

--/MODULAR_FUNCTIONS

--/WORKSPACE

giftButton.Activated:Connect(onInteract)
playtimeFrame.Close.Activated:Connect(closeGiftFrame)

task.spawn(function()
	updateGiftStatusTimers(0)
	repeat
		task.wait(1)
		local timePassed: number = os.time() - playerDataReplicator.GetMetaData("JoinedTimeStamp")
		updateGiftStatusTimers(timePassed)
	until timePassed > highestRewardTime
end)

return PlayetimeRewardsHandler
